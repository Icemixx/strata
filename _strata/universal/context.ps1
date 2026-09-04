[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$CheckAll,
    [Parameter(DontShow = $true)]
    [switch]$GenerateGuide,
    [switch]$GuideStatus,
    [string[]]$Paths
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$IsAgentInternalInvocation = $MyInvocation.InvocationName -eq '.'

$GeneratorVersion = 'strata-context-2'
$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Findings = New-Object System.Collections.ArrayList
$UniversalRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$StrataRoot = [IO.Path]::GetFullPath((Split-Path -Parent $UniversalRoot))
$ProjectRoot = [IO.Path]::GetFullPath((Split-Path -Parent $StrataRoot))
$GuidePath = Join-Path $StrataRoot 'project_guide.html'
$GuideShellPath = Join-Path $UniversalRoot 'guide-shell.html'

function Show-Usage {
    @'
Usage:
  context.ps1 -Check -Paths <changed paths>
  context.ps1 -CheckAll
  context.ps1 -GuideStatus

All user-callable modes are read-only. Ask the agent to "update the Guide" when a refreshed Guide is needed.
'@ | Write-Output
}

function Add-Finding([string]$Code, [string]$Message) {
    [void]$Findings.Add([pscustomobject]@{ Code = $Code; Message = $Message })
}

function Read-Utf8([string]$Path) {
    try {
        return $Utf8Strict.GetString([IO.File]::ReadAllBytes($Path)).Replace("`r`n", "`n").Replace("`r", "`n")
    }
    catch {
        Add-Finding 'INVALID_UTF8' "$Path is not valid UTF-8: $($_.Exception.Message)"
        return $null
    }
}

function Test-Inside([string]$Path, [string]$Root) {
    $full = [IO.Path]::GetFullPath($Path)
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    return $full.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)
}

function Get-Relative([string]$Path, [string]$Root) {
    $rootUri = New-Object Uri(([IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'))
    $pathUri = New-Object Uri([IO.Path]::GetFullPath($Path))
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

function Invoke-GitRead([string[]]$GitArguments) {
    # Git writes advisory warnings to stderr and still exits 0 - an unreadable
    # global ignore file, an unreadable directory during a walk. Under the
    # caller's ErrorActionPreference Stop, PowerShell turns that native stderr
    # into a terminating error, which silently emptied every watch expansion on
    # one host. Read with the preference relaxed for the duration of the call,
    # restore the caller's, and keep failing closed only on a nonzero exit.
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $safeRoot = $ProjectRoot.Replace('\','/')
        $output = @(& git -c "safe.directory=$safeRoot" -C $ProjectRoot @GitArguments 2>$null)
        if ($LASTEXITCODE -ne 0) { return @() }
        return @($output | Where-Object { $_ -is [string] })
    }
    catch { return @() }
    finally { $ErrorActionPreference = $previousPreference }
}

function Get-GitSnapshot {
    $oidLines = @(Invoke-GitRead @('rev-parse','HEAD'))
    if ($oidLines.Count -eq 0 -or $oidLines[0] -notmatch '^[0-9a-fA-F]{40}$') {
        return [pscustomobject]@{ Oid='unavailable'; Short='unavailable'; Date='unknown date'; Subject='Git metadata unavailable' }
    }
    $oid = $oidLines[0].ToLowerInvariant()
    $dateLines = @(Invoke-GitRead @('show','-s','--format=%cs',$oid))
    $subjectLines = @(Invoke-GitRead @('show','-s','--format=%s',$oid))
    return [pscustomobject]@{
        Oid = $oid
        Short = $oid.Substring(0,7)
        Date = if ($dateLines.Count -gt 0) { $dateLines[0] } else { 'unknown date' }
        Subject = if ($subjectLines.Count -gt 0) { $subjectLines[0] } else { 'subject unavailable' }
    }
}

function Get-ContentsEntries([string]$IndexPath, [string]$AuthorityRoot) {
    $text = Read-Utf8 $IndexPath
    $entries = New-Object System.Collections.ArrayList
    if ($null -eq $text) { return $entries }
    $lines = $text -split "`n"
    $headingIndexes = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Contents\s*$') { $headingIndexes += $i }
    }
    if ($headingIndexes.Count -ne 1) {
        Add-Finding 'CONTENTS_SECTION' "$IndexPath must contain exactly one '## Contents' section."
        return $entries
    }
    $start = $headingIndexes[0] + 1
    $end = $lines.Count
    for ($i = $start; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+') { $end = $i; break }
    }
    for ($i = $start; $i -lt $end; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -notmatch '^\s*-\s+\[([^\]]+)\]\(([^)]+)\)\s+(?:—|–|-)\s+(\S.+)$') {
            Add-Finding 'CONTENTS_ENTRY' "${IndexPath}:$($i + 1) is not a described direct-child link."
            continue
        }
        $label = $Matches[1]
        $targetText = $Matches[2]
        $description = $Matches[3]
        if ($targetText -match '^[a-zA-Z][a-zA-Z0-9+.-]*:' -or $targetText.StartsWith('#')) {
            Add-Finding 'ROUTE_EXTERNAL' "${IndexPath}:$($i + 1) routes to a non-local target: $targetText"
            continue
        }
        $pathPart = ($targetText -split '#', 2)[0]
        try { $pathPart = [Uri]::UnescapeDataString($pathPart) } catch { }
        $target = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $IndexPath) $pathPart))
        if (-not (Test-Inside $target $AuthorityRoot)) {
            Add-Finding 'ROUTE_ESCAPE' "${IndexPath}:$($i + 1) escapes its authority root: $targetText"
            continue
        }
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
            Add-Finding 'BROKEN_LINK' "${IndexPath}:$($i + 1) targets a missing file: $targetText"
            continue
        }
        $item = Get-Item -LiteralPath $target
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Add-Finding 'LINK_LIKE_PATH' "$target is a reparse point."
            continue
        }
        if ([IO.Path]::GetExtension($target) -ine '.md') {
            Add-Finding 'ROUTE_TYPE' "${IndexPath}:$($i + 1) must route to Markdown: $targetText"
            continue
        }
        $indexDir = [IO.Path]::GetFullPath((Split-Path -Parent $IndexPath)).TrimEnd('\')
        $targetDir = [IO.Path]::GetFullPath((Split-Path -Parent $target)).TrimEnd('\')
        $direct = $targetDir.Equals($indexDir, [StringComparison]::OrdinalIgnoreCase)
        if ((Split-Path -Leaf $target) -ieq 'index.md') {
            $direct = ([IO.Path]::GetFullPath((Split-Path -Parent $targetDir)).TrimEnd('\')).Equals($indexDir, [StringComparison]::OrdinalIgnoreCase)
        }
        if (-not $direct) {
            Add-Finding 'NOT_DIRECT_CHILD' "${IndexPath}:$($i + 1) skips an index level: $targetText"
            continue
        }
        [void]$entries.Add([pscustomobject]@{
            Label = $label
            Description = $description
            Target = $target
            Source = $IndexPath
        })
    }
    return $entries
}

function Build-AuthorityGraph([string]$Name, [string]$DirectoryName) {
    $root = Join-Path $StrataRoot $DirectoryName
    $rootIndex = Join-Path $root 'index.md'
    $owners = @{}
    $ordered = New-Object System.Collections.ArrayList
    $visitedIndexes = @{}
    $tree = [pscustomobject]@{
        Label = $Name
        Description = ''
        Path = $rootIndex
        IsIndex = $true
        Children = New-Object System.Collections.ArrayList
    }
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        Add-Finding 'MISSING_AUTHORITY' "Missing $Name root: $root"
        return [pscustomobject]@{ Name=$Name; Root=$root; RootIndex=$rootIndex; Owners=$owners; Ordered=$ordered; Tree=$tree }
    }
    if (-not (Test-Path -LiteralPath $rootIndex -PathType Leaf)) {
        Add-Finding 'MISSING_INDEX' "Missing $Name root index: $rootIndex"
        return [pscustomobject]@{ Name=$Name; Root=$root; RootIndex=$rootIndex; Owners=$owners; Ordered=$ordered; Tree=$tree }
    }
    function Visit-Index([string]$IndexPath, [object]$Node) {
        $key = [IO.Path]::GetFullPath($IndexPath).ToLowerInvariant()
        if ($visitedIndexes.ContainsKey($key)) {
            Add-Finding 'INDEX_CYCLE' "Index cycle or duplicate traversal at $IndexPath"
            return
        }
        $visitedIndexes[$key] = $true
        [void]$ordered.Add($IndexPath)
        foreach ($entry in @(Get-ContentsEntries $IndexPath $root)) {
            $child = [pscustomobject]@{
                Label = $entry.Label
                Description = $entry.Description
                Path = $entry.Target
                IsIndex = ((Split-Path -Leaf $entry.Target) -ieq 'index.md')
                Children = New-Object System.Collections.ArrayList
            }
            [void]$Node.Children.Add($child)
            $targetKey = $entry.Target.ToLowerInvariant()
            if (-not $owners.ContainsKey($targetKey)) { $owners[$targetKey] = New-Object System.Collections.ArrayList }
            [void]$owners[$targetKey].Add($IndexPath)
            if ($owners[$targetKey].Count -gt 1) {
                Add-Finding 'MULTIPLE_OWNERS' "$($entry.Target) has more than one owning Contents entry."
            }
            if ($child.IsIndex) { Visit-Index $entry.Target $child }
            else { [void]$ordered.Add($entry.Target) }
        }
    }
    Visit-Index $rootIndex $tree
    $caseMap = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md')) {
        if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Add-Finding 'LINK_LIKE_PATH' "$($file.FullName) is a reparse point."
            continue
        }
        $caseKey = $file.FullName.ToLowerInvariant()
        if ($caseMap.ContainsKey($caseKey) -and $caseMap[$caseKey] -cne $file.FullName) {
            Add-Finding 'CASE_COLLISION' "$($caseMap[$caseKey]) collides with $($file.FullName)."
        }
        $caseMap[$caseKey] = $file.FullName
        if ($file.FullName -ine $rootIndex -and -not $owners.ContainsKey($caseKey)) {
            Add-Finding 'UNINDEXED_RECORD' "$($file.FullName) is not owned by a Contents entry."
        }
    }
    foreach ($dir in @(Get-ChildItem -LiteralPath $root -Recurse -Directory)) {
        if (($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Add-Finding 'LINK_LIKE_PATH' "$($dir.FullName) is a reparse point."
        }
        elseif (-not (Test-Path -LiteralPath (Join-Path $dir.FullName 'index.md') -PathType Leaf)) {
            Add-Finding 'MISSING_INDEX' "$($dir.FullName) is a routed directory without index.md."
        }
    }
    return [pscustomobject]@{ Name=$Name; Root=$root; RootIndex=$rootIndex; Owners=$owners; Ordered=$ordered; Tree=$tree }
}

function Test-RequiredFiles {
    foreach ($relative in @(
        'universal_agent_instructions.md',
        'universal\active-agent.md',
        'universal\context-routing.md',
        'universal\guide-shell.html',
        'project_instructions.md'
    )) {
        $path = Join-Path $StrataRoot $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Add-Finding 'MISSING_REQUIRED_FILE' "Missing $path" }
    }
    foreach ($router in @('AGENTS.md','CLAUDE.md')) {
        $path = Join-Path $ProjectRoot $router
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Add-Finding 'MISSING_ROUTER' "Missing root router: $path"
            continue
        }
        $text = Read-Utf8 $path
        if ($null -eq $text) { continue }
        foreach ($required in @('_strata/universal_agent_instructions.md','_strata/project_instructions.md')) {
            if ($text -notmatch [regex]::Escape($required)) { Add-Finding 'ROUTER_EDGE' "$router does not route $required" }
        }
        if ($text -match 'active-agent|harness-(?:codex|claude-code)|project_instructions_active_agent') {
            Add-Finding 'ROUTER_NOT_THIN' "$router imports an Active Agent file or harness dossier."
        }
    }
}

function Test-GuideShell {
    if (-not (Test-Path -LiteralPath $GuideShellPath -PathType Leaf)) { return }
    $shell = Read-Utf8 $GuideShellPath
    if ($null -eq $shell) { return }
    foreach ($placeholder in @(
        '@@STRATA_GENERATOR@@',
        '@@STRATA_DIGEST@@',
        '@@STRATA_GENERATED_AT@@',
        '@@STRATA_BASE_COMMIT@@',
        '@@STRATA_BASE_COMMIT_SHORT@@',
        '@@STRATA_BASE_COMMIT_DATE@@',
        '@@STRATA_BASE_COMMIT_SUBJECT@@',
        '<!--STRATA_NAVIGATION-->',
        '<!--STRATA_CONTENT-->',
        '<!--STRATA_MANIFEST-->'
    )) {
        $count = [regex]::Matches($shell, [regex]::Escape($placeholder)).Count
        if ($count -ne 1) { Add-Finding 'GUIDE_SHELL_PLACEHOLDER' "$GuideShellPath must contain $placeholder exactly once; found $count." }
    }
    if ($shell -match '(?is)<(?:script|img|iframe|frame|link|audio|video|source)\b[^>]*(?:src|href)\s*=') {
        Add-Finding 'GUIDE_SHELL_EXTERNAL' "$GuideShellPath contains a loadable resource attribute."
    }
    if ($shell -match '(?i)url\s*\(') {
        Add-Finding 'GUIDE_SHELL_EXTERNAL' "$GuideShellPath contains a CSS url() resource."
    }
}

function Test-State([object]$StateGraph, [object]$RationaleGraph, [object]$BuildGraph) {
    $ids = @{}
    foreach ($path in @($StateGraph.Ordered)) {
        if ((Split-Path -Leaf $path) -ieq 'index.md') { continue }
        $text = Read-Utf8 $path
        if ($null -eq $text) { continue }
        $lines = $text -split "`n"
        $currentId = $null
        for ($i=0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -match '^- ([A-Z][A-Z0-9]*-[0-9]+) — (OPEN|IN PROGRESS|BLOCKED|DONE) — (\S.+)$') {
                $currentId = $Matches[1]
                $status = $Matches[2]
                if ($ids.ContainsKey($currentId)) { Add-Finding 'DUPLICATE_STATE_ID' "$currentId appears in $($ids[$currentId]) and $path" }
                else { $ids[$currentId] = $path }
                $inCompleted = Test-Inside $path (Join-Path $StateGraph.Root 'completed')
                if ($status -eq 'DONE' -and -not $inCompleted) { Add-Finding 'DONE_IN_CURRENT' "$currentId is DONE outside completed storage." }
                if ($status -ne 'DONE' -and $inCompleted) { Add-Finding 'ACTIVE_IN_COMPLETED' "$currentId is $status inside completed storage." }
                continue
            }
            if ($line -match '^- [A-Z][A-Z0-9]*-[0-9]+\s') {
                Add-Finding 'STATE_ENTRY_FORMAT' "${path}:$($i+1) has an invalid State ticket entry."
                $currentId = $null
                continue
            }
            if ($line -match '^\s{2,}- (Why|How):\s+(.+)$') {
                $kind = $Matches[1]
                $linksText = $Matches[2]
                if ($null -eq $currentId) { Add-Finding 'ORPHAN_TYPED_LINK' "${path}:$($i+1) has $kind without a preceding ticket."; continue }
                $matches = [regex]::Matches($linksText, '\[[^\]]+\]\(([^)]+)\)')
                if ($matches.Count -eq 0) { Add-Finding 'TYPED_LINK_FORMAT' "${path}:$($i+1) has no Markdown link."; continue }
                foreach ($match in $matches) {
                    $raw = ($match.Groups[1].Value -split '#',2)[0]
                    $target = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $path) $raw))
                    $graph = if ($kind -eq 'Why') { $RationaleGraph } else { $BuildGraph }
                    if (-not (Test-Inside $target $graph.Root) -or -not (Test-Path -LiteralPath $target -PathType Leaf)) {
                        Add-Finding 'TYPED_LINK_TARGET' "${path}:$($i+1) has invalid $kind target: $raw"
                    }
                    elseif (-not $graph.Owners.ContainsKey($target.ToLowerInvariant())) {
                        Add-Finding 'TYPED_LINK_UNROUTED' "${path}:$($i+1) targets an unowned $kind record: $raw"
                    }
                }
            }
        }
    }
}

function Invoke-Validation {
    $Findings.Clear()
    Test-RequiredFiles
    Test-GuideShell
    $state = Build-AuthorityGraph 'State' 'state'
    $rationale = Build-AuthorityGraph 'Rationale' 'rationale'
    $build = Build-AuthorityGraph 'Build Log' 'build-log'
    Test-State $state $rationale $build
    return [pscustomobject]@{ State=$state; Rationale=$rationale; BuildLog=$build }
}

function Get-SourceDigest([object]$Graphs) {
    $builder = New-Object Text.StringBuilder
    [void]$builder.AppendLine($GeneratorVersion)
    foreach ($graph in @($Graphs.State,$Graphs.Rationale,$Graphs.BuildLog)) {
        foreach ($path in @($graph.Ordered)) {
            [void]$builder.AppendLine((Get-Relative $path $StrataRoot).Replace('\','/'))
            $text = Read-Utf8 $path
            if ($null -ne $text) { [void]$builder.AppendLine($text) }
        }
    }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Utf8NoBom.GetBytes($builder.ToString())))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Write-GuideStatus([object]$Graphs) {
    # Two paths, one first-token interface. With a composition source the v1
    # manifest, section and closed reason-code grammar applies; without one the
    # pre-v1 authority-only digest, field sets, missing-digest result and
    # GUIDE_CHANGE advisories below remain exactly as they were.
    $compositionPath = Join-Path $ProjectRoot '_strata/project_guide.md'
    if (Test-Path -LiteralPath $compositionPath -PathType Leaf) {
        Write-GuideCompositionStatus $compositionPath
        return
    }
    $currentDigest = Get-SourceDigest $Graphs
    if (-not (Test-Path -LiteralPath $GuidePath -PathType Leaf)) {
        Write-Output "GUIDE_MISSING current_digest=$currentDigest"
        return
    }
    try { $html = [IO.File]::ReadAllText($GuidePath, $Utf8Strict) }
    catch {
        Write-Output "GUIDE_INVALID reason=utf8 current_digest=$currentDigest"
        return
    }
    $digestMatch = [regex]::Match($html, '\bdata-source-digest="([0-9a-f]{64})"', 'IgnoreCase')
    $commitMatch = [regex]::Match($html, '\bdata-generation-commit="([^"]+)"', 'IgnoreCase')
    if (-not $digestMatch.Success) {
        Write-Output "GUIDE_INVALID reason=missing-digest current_digest=$currentDigest"
        return
    }
    $generatedDigest = $digestMatch.Groups[1].Value.ToLowerInvariant()
    $baseCommit = if ($commitMatch.Success) { $commitMatch.Groups[1].Value } else { 'unavailable' }
    $commitsSince = 'unknown'
    $authorityCommitsSince = 'unknown'
    $changes = @()
    if ($baseCommit -match '^[0-9a-f]{40}$') {
        $ancestor = @(Invoke-GitRead @('merge-base','--is-ancestor',$baseCommit,'HEAD'))
        if ($LASTEXITCODE -eq 0) {
            $count = @(Invoke-GitRead @('rev-list','--count',("$baseCommit..HEAD")))
            if ($count.Count -gt 0) { $commitsSince = $count[0] }
            $authorityCount = @(Invoke-GitRead @('rev-list','--count',("$baseCommit..HEAD"),'--','_strata/state','_strata/rationale','_strata/build-log'))
            if ($authorityCount.Count -gt 0) { $authorityCommitsSince = $authorityCount[0] }
            $changes = @(Invoke-GitRead @('log','-n','5','--format=%h%x09%s',("$baseCommit..HEAD"),'--','_strata/state','_strata/rationale','_strata/build-log'))
        }
    }
    $authorityDirty = @(Invoke-GitRead @('status','--porcelain','--','_strata/state','_strata/rationale','_strata/build-log')).Count -gt 0
    if ($generatedDigest -eq $currentDigest) {
        Write-Output "GUIDE_CURRENT digest=$currentDigest generated_from=$baseCommit commits_since=$commitsSince authority_commits_since=$authorityCommitsSince authority_worktree_dirty=$($authorityDirty.ToString().ToLowerInvariant())"
        return
    }
    Write-Output "GUIDE_STALE generated_digest=$generatedDigest current_digest=$currentDigest generated_from=$baseCommit commits_since=$commitsSince authority_commits_since=$authorityCommitsSince authority_worktree_dirty=$($authorityDirty.ToString().ToLowerInvariant())"
    foreach ($change in $changes) { Write-Output "GUIDE_CHANGE $change" }
}

function Convert-MarkdownInline([string]$Text) {
    $encoded = [Net.WebUtility]::HtmlEncode($Text)
    $tokens = [Collections.Generic.List[string]]::new()
    $encoded = [regex]::Replace($encoded, '`([^`]+)`', {
        param($m)
        $index = $tokens.Count
        $tokens.Add('<code>' + $m.Groups[1].Value + '</code>')
        return "@@STRATAINLINE$index@@"
    })
    $encoded = [regex]::Replace($encoded, '!\[([^\]]*)\]\(([^)]+)\)', '[Image: $1]($2)')
    $encoded = [regex]::Replace($encoded, '\[([^\]]+)\]\(([^)]+)\)', {
        param($m)
        $label = $m.Groups[1].Value
        $target = [Net.WebUtility]::HtmlDecode($m.Groups[2].Value).Trim()
        if ($target -match '(?i)^(?:javascript|data|vbscript):') { return $label }
        return '<a href="' + [Net.WebUtility]::HtmlEncode($target) + '">' + $label + '</a>'
    })
    $encoded = [regex]::Replace($encoded, '(?<!\*)\*\*([^*]+)\*\*', '<strong>$1</strong>')
    $encoded = [regex]::Replace($encoded, '(?<!_)__([^_]+)__', '<strong>$1</strong>')
    $encoded = [regex]::Replace($encoded, '(?<!\*)\*([^*]+)\*', '<em>$1</em>')
    $encoded = [regex]::Replace($encoded, '(?<!_)_([^_]+)_', '<em>$1</em>')
    for ($i = 0; $i -lt $tokens.Count; $i++) { $encoded = $encoded.Replace("@@STRATAINLINE$i@@", $tokens[$i]) }
    return $encoded
}

function Convert-Markdown([string]$Markdown, [string]$HeaderPrefix = 'source-heading-') {
    $safePrefix = [regex]::Replace($HeaderPrefix, '[^a-zA-Z0-9_-]', '-')
    # Heading text repeats inside a record - "Files", "Notes", "Verification" once per section is
    # normal prose, not a mistake - so a slug alone is not an id. Number the repeats rather than
    # emitting a duplicate id, which fails generation closed and blocks the whole Guide.
    $usedSlugs = @{}
    $lines = @($Markdown -replace "`r`n?", "`n" -split "`n")
    $html = [Text.StringBuilder]::new()
    $paragraph = [Collections.Generic.List[string]]::new()
    $listType = $null
    $inCode = $false
    $code = [Collections.Generic.List[string]]::new()

    function Flush-Paragraph {
        if ($paragraph.Count -gt 0) {
            [void]$html.Append('<p>').Append((Convert-MarkdownInline ($paragraph -join ' '))).AppendLine('</p>')
            $paragraph.Clear()
        }
    }
    function Close-List {
        if ($null -ne $listType) {
            [void]$html.Append('</').Append($listType).AppendLine('>')
            Set-Variable -Name listType -Value $null -Scope 1
        }
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^```') {
            if ($inCode) {
                [void]$html.Append('<pre><code>').Append([Net.WebUtility]::HtmlEncode($code -join "`n")).AppendLine('</code></pre>')
                $code.Clear(); $inCode = $false
            }
            else { Flush-Paragraph; Close-List; $inCode = $true }
            continue
        }
        if ($inCode) { $code.Add($line); continue }
        if ([string]::IsNullOrWhiteSpace($line)) { Flush-Paragraph; Close-List; continue }

        if ($line -match '^(#{1,6})\s+(.+?)\s*#*$') {
            Flush-Paragraph; Close-List
            $level = $Matches[1].Length
            $heading = $Matches[2]
            $slug = ([regex]::Replace($heading.ToLowerInvariant(), '[^a-z0-9_]+', '-')).Trim('-')
            if ($usedSlugs.ContainsKey($slug)) {
                $usedSlugs[$slug] = $usedSlugs[$slug] + 1
                $slug = $slug + '-' + $usedSlugs[$slug]
            }
            else { $usedSlugs[$slug] = 1 }
            [void]$html.Append('<h').Append($level).Append(' id="').Append($safePrefix).Append($slug).Append('">').Append((Convert-MarkdownInline $heading)).Append('</h').Append($level).AppendLine('>')
            continue
        }

        if ($i + 1 -lt $lines.Count -and $line.Contains('|') -and $lines[$i + 1] -match '^\s*\|?\s*:?-{3,}') {
            Flush-Paragraph; Close-List
            $headers = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
            $i++
            [void]$html.AppendLine('<table><thead><tr>')
            foreach ($cell in $headers) { [void]$html.Append('<th>').Append((Convert-MarkdownInline $cell)).AppendLine('</th>') }
            [void]$html.AppendLine('</tr></thead><tbody>')
            while ($i + 1 -lt $lines.Count -and $lines[$i + 1].Contains('|') -and -not [string]::IsNullOrWhiteSpace($lines[$i + 1])) {
                $i++
                $cells = @($lines[$i].Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
                [void]$html.AppendLine('<tr>')
                foreach ($cell in $cells) { [void]$html.Append('<td>').Append((Convert-MarkdownInline $cell)).AppendLine('</td>') }
                [void]$html.AppendLine('</tr>')
            }
            [void]$html.AppendLine('</tbody></table>')
            continue
        }

        if ($line -match '^\s*[-+*]\s+(.+)$') {
            Flush-Paragraph
            if ($listType -ne 'ul') { Close-List; $listType = 'ul'; [void]$html.AppendLine('<ul>') }
            [void]$html.Append('<li>').Append((Convert-MarkdownInline $Matches[1])).AppendLine('</li>')
            continue
        }
        if ($line -match '^\s*\d+[.)]\s+(.+)$') {
            Flush-Paragraph
            if ($listType -ne 'ol') { Close-List; $listType = 'ol'; [void]$html.AppendLine('<ol>') }
            [void]$html.Append('<li>').Append((Convert-MarkdownInline $Matches[1])).AppendLine('</li>')
            continue
        }
        if ($line -match '^>\s?(.*)$') {
            Flush-Paragraph; Close-List
            [void]$html.Append('<blockquote><p>').Append((Convert-MarkdownInline $Matches[1])).AppendLine('</p></blockquote>')
            continue
        }
        if ($line -match '^\s*(?:-{3,}|\*{3,}|_{3,})\s*$') { Flush-Paragraph; Close-List; [void]$html.AppendLine('<hr>'); continue }
        $paragraph.Add($line.Trim())
    }
    if ($inCode) { [void]$html.Append('<pre><code>').Append([Net.WebUtility]::HtmlEncode($code -join "`n")).AppendLine('</code></pre>') }
    Flush-Paragraph; Close-List
    return $html.ToString()
}

function Remove-ContentsSection([string]$Markdown) {
    return [regex]::Replace($Markdown, '(?ms)^## Contents\s*\n.*?(?=^##\s|\z)', '').Trim()
}

function Get-DocAnchor([string]$Path) {
    $relative = (Get-Relative $Path $StrataRoot).Replace('\','/').ToLowerInvariant()
    return 'doc-' + ([regex]::Replace($relative, '[^a-z0-9]+', '-')).Trim('-')
}

function Get-HeadingAnchor([string]$DocumentAnchor, [string]$Fragment) {
    try { $decoded = [Uri]::UnescapeDataString($Fragment) }
    catch { $decoded = $Fragment }
    $slug = [regex]::Replace($decoded.ToLowerInvariant(), '[^a-z0-9_]+', '-')
    return $DocumentAnchor + '-heading-' + $slug
}

function Rewrite-GuideLinks([string]$Html, [string]$SourcePath, [hashtable]$Anchors) {
    return [regex]::Replace($Html, 'href="([^"]+)"', {
        param($m)
        $raw = $m.Groups[1].Value
        $sourceKey = [IO.Path]::GetFullPath($SourcePath).ToLowerInvariant()
        if ($raw.StartsWith('#')) {
            if (-not $Anchors.ContainsKey($sourceKey)) { return $m.Value }
            return 'href="#' + (Get-HeadingAnchor $Anchors[$sourceKey] $raw.Substring(1)) + '"'
        }
        if ($raw -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') { return $m.Value }
        $parts = $raw -split '#',2
        $pathPart = $parts[0]
        try { $target = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $SourcePath) ([Uri]::UnescapeDataString($pathPart)))) }
        catch { return $m.Value }
        $key = $target.ToLowerInvariant()
        if ($Anchors.ContainsKey($key)) {
            if ($parts.Count -eq 2 -and -not [string]::IsNullOrWhiteSpace($parts[1])) {
                return 'href="#' + (Get-HeadingAnchor $Anchors[$key] $parts[1]) + '"'
            }
            return 'href="#' + $Anchors[$key] + '"'
        }
        return $m.Value
    })
}

function Get-PlainSummary([string]$Markdown) {
    $text = Remove-ContentsSection $Markdown
    foreach ($paragraph in @($text -split "(?:`r?`n){2,}")) {
        $candidate = $paragraph.Trim()
        if ([string]::IsNullOrWhiteSpace($candidate) -or $candidate -match '^(?:#|```|~~~|[-*+]\s|\d+\.\s|>|\|)') { continue }
        $candidate = [regex]::Replace($candidate, '!\[([^\]]*)\]\([^)]+\)', '$1')
        $candidate = [regex]::Replace($candidate, '\[([^\]]+)\]\([^)]+\)', '$1')
        $candidate = [regex]::Replace($candidate, '[`*_~]', '')
        $candidate = [regex]::Replace($candidate, '\s+', ' ').Trim()
        if (-not [string]::IsNullOrWhiteSpace($candidate)) { return $candidate }
    }
    return ''
}

function Get-NodeDescription([object]$Node) {
    if (-not [string]::IsNullOrWhiteSpace($Node.Description)) { return $Node.Description }
    $markdown = Read-Utf8 $Node.Path
    if ($null -eq $markdown) { return '' }
    return Get-PlainSummary $markdown
}

function Render-GuideNavigationNode([object]$Node, [hashtable]$Anchors) {
    $anchor = $Anchors[$Node.Path.ToLowerInvariant()]
    $label = [Net.WebUtility]::HtmlEncode($Node.Label)
    $description = [Net.WebUtility]::HtmlEncode((Get-NodeDescription $Node))
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append("<li data-nav-item data-target=`"$anchor`">")
    if ($Node.Children.Count -gt 0) {
        [void]$builder.Append("<details open><summary>$label</summary><a href=`"#$anchor`">Overview</a>")
        if (-not [string]::IsNullOrWhiteSpace($description)) { [void]$builder.Append("<span class=`"nav-description`">$description</span>") }
        [void]$builder.Append('<ul>')
        foreach ($child in @($Node.Children)) { [void]$builder.Append((Render-GuideNavigationNode $child $Anchors)) }
        [void]$builder.Append('</ul></details>')
    }
    else {
        [void]$builder.Append("<a href=`"#$anchor`">$label</a>")
        if (-not [string]::IsNullOrWhiteSpace($description)) { [void]$builder.Append("<span class=`"nav-description`">$description</span>") }
        # Topics inside the record, so a reader can navigate to a subject by name.
        $topics = @(Get-RecordTopics (Remove-ContentsSection (Read-Utf8 $Node.Path)) ($anchor + '-heading-'))
        if ($topics.Count -gt 0) {
            [void]$builder.Append('<ul class="nav-topics">')
            foreach ($topic in $topics) {
                [void]$builder.Append(("<li data-nav-item data-target=`"{0}`"><a href=`"#{0}`">{1}</a></li>" -f $topic.Anchor,[Net.WebUtility]::HtmlEncode($topic.Title)))
            }
            [void]$builder.Append('</ul>')
        }
    }
    [void]$builder.Append('</li>')
    return $builder.ToString()
}

function Render-TopicCards([object]$Node, [hashtable]$Anchors) {
    if ($Node.Children.Count -eq 0) { return '' }
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('<div class="topic-grid">')
    foreach ($child in @($Node.Children)) {
        $anchor = $Anchors[$child.Path.ToLowerInvariant()]
        $label = [Net.WebUtility]::HtmlEncode($child.Label)
        $description = [Net.WebUtility]::HtmlEncode((Get-NodeDescription $child))
        [void]$builder.Append("<a class=`"topic-card`" href=`"#$anchor`"><strong>$label</strong>")
        if (-not [string]::IsNullOrWhiteSpace($description)) { [void]$builder.Append("<span>$description</span>") }
        [void]$builder.Append('</a>')
    }
    [void]$builder.Append('</div>')
    return $builder.ToString()
}

function Get-RecordTopics([string]$Markdown, [string]$HeadingPrefix) {
    # The archived project guides navigated by topic, not by file: every "## " in a record is a
    # subject a reader looks for by name. Compute the same anchors Convert-Markdown will emit so
    # navigation and content agree without rendering twice.
    $safePrefix = [regex]::Replace($HeadingPrefix, '[^a-zA-Z0-9_-]', '-')
    $topics = New-Object System.Collections.ArrayList
    $inCode = $false
    foreach ($line in @($Markdown -split "`n")) {
        # Track fences exactly as Convert-Markdown does. A "## " inside a code block is sample
        # text, not a topic: navigating to one links at a heading the renderer never emitted.
        if ($line -match '^```') { $inCode = -not $inCode; continue }
        if ($inCode) { continue }
        if ($line -match '^##\s+(.+?)\s*#*$') {
            $title = $Matches[1]
            $slug = ([regex]::Replace($title.ToLowerInvariant(), '[^a-z0-9_]+', '-')).Trim('-')
            [void]$topics.Add([pscustomobject]@{ Anchor = $safePrefix + $slug; Title = $title })
        }
    }
    return $topics
}

function Expand-RecordTopics([string]$Html) {
    # Fold each topic into a disclosure block, the first left open. A record that renders every
    # reference table at once is the wall the archived guides avoided by collapsing detail.
    # A group heading ends the fold above it as surely as the next topic does: absorbed into the
    # preceding <details>, a group title disappears from the page whenever that fold is shut.
    $headings = [regex]::Matches($Html, '<h([12]) id="([^"]+)">(.*?)</h[12]>')
    if ($headings.Count -eq 0) { return $Html }
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append($Html.Substring(0, $headings[0].Index))
    $opened = $false
    for ($i = 0; $i -lt $headings.Count; $i++) {
        $heading = $headings[$i]
        $start = $heading.Index + $heading.Length
        $end = if ($i + 1 -lt $headings.Count) { $headings[$i + 1].Index } else { $Html.Length }
        $inner = $Html.Substring($start, $end - $start)
        if ($heading.Groups[1].Value -eq '1') {
            [void]$builder.Append($heading.Value).Append($inner)
            continue
        }
        $open = if ($opened) { '' } else { ' open' }
        $opened = $true
        [void]$builder.Append(('<details class="topic" id="{0}"{1}><summary>{2}</summary><div class="topic-body">{3}</div></details>' -f $heading.Groups[2].Value, $open, $heading.Groups[3].Value, $inner))
    }
    return $builder.ToString()
}

function Test-GuideCitation([string]$Kind, [string]$Target, [string]$RepoRoot, [object]$Graphs) {
    # Two reference kinds resolve at different strengths, because they can. An authority target is
    # present in the routed graph or it is not. A code locator can only be checked textually: deciding
    # which declaration a token denotes is static analysis, which universal tooling must not attempt.
    $parts = $Target -split ':', 2
    $relative = $parts[0]
    $locator = if ($parts.Count -gt 1) { $parts[1] } else { '' }
    if ($Kind -eq 'authority') {
        $pieces = $Target -split '#', 2
        $path = $pieces[0]
        $anchor = if ($pieces.Count -gt 1) { $pieces[1] } else { '' }
        if ($path -match '[<>"|*?]') { return "authority target has illegal path characters: $Target" }
        $full = Join-Path $RepoRoot $path
        if (-not (Test-Path -LiteralPath $full)) { return "authority file not found: $path" }
        $routed = $false
        foreach ($graph in @($Graphs.State,$Graphs.Rationale,$Graphs.BuildLog)) {
            foreach ($known in @($graph.Ordered)) {
                if ([IO.Path]::GetFullPath($known) -eq [IO.Path]::GetFullPath($full)) { $routed = $true }
            }
        }
        if (-not $routed) { return "authority target is not routed: $path" }
        if ($anchor) {
            $slugs = @()
            foreach ($line in @((Read-Utf8 $full) -split "`n")) {
                if ($line -match '^#{1,6}\s+(.+?)\s*#*$') {
                    $slugs += ([regex]::Replace($Matches[1].ToLowerInvariant(), '[^a-z0-9_]+', '-')).Trim('-')
                }
            }
            if ($slugs -notcontains $anchor.ToLowerInvariant()) { return "authority anchor not found: $Target" }
        }
        return ''
    }
    if ($relative -match '[<>"|*?]') { return "code target has illegal path characters: $Target" }
    $full = Join-Path $RepoRoot $relative
    if (-not (Test-Path -LiteralPath $full)) { return "cited file not found: $relative" }
    # A path alone is not evidence. Code files are large; "somewhere in this file" cannot be checked by
    # a reader, so the form requires the spot and generation refuses a reference that omits it.
    if ([string]::IsNullOrWhiteSpace($locator)) { return "code reference needs a locator: $Target" }
    $content = Read-Utf8 $full
    if ($null -eq $content) { return "cited file unreadable: $relative" }
    # Delimiter-aware for a simple identifier; literal for compound tokens carrying punctuation.
    $found = if ($locator -match '^[A-Za-z_][A-Za-z0-9_]*$') {
        [regex]::IsMatch($content, '(?<![A-Za-z0-9_])' + [regex]::Escape($locator) + '(?![A-Za-z0-9_])')
    } else { $content.Contains($locator) }
    if (-not $found) { return "locator not found in cited file: $Target" }
    return ''
}

function Convert-GuideCitations([string]$Markdown, [string]$RepoRoot, [object]$Graphs, [object]$Problems, [object]$CitedFiles, [object]$Chips) {
    # Harvest references from the Markdown, before rendering. A path like `_strata/state/current.md`
    # carries underscores that inline conversion reads as emphasis, so a reference validated after
    # rendering is validated against `<em>strata/...` and fails for a reason that is not its own.
    $index = 0
    return [regex]::Replace($Markdown, '\[(code|authority):\s*([^\]]+)\]', {
        param($m)
        $kind = $m.Groups[1].Value
        $target = $m.Groups[2].Value.Trim()
        $problem = Test-GuideCitation $kind $target $RepoRoot $Graphs
        if ($problem) { [void]$Problems.Add($problem) }
        if ($kind -eq 'code') { [void]$CitedFiles.Add((($target -split ':', 2)[0])) }
        $token = '@@STRATACITE' + $script:GuideCiteCounter + '@@'
        $script:GuideCiteCounter++
        [void]$Chips.Add([pscustomobject]@{
            Token = $token
            Html  = ('<span class="cite cite-{0}" title="{0}">{1}</span>' -f $kind,[Net.WebUtility]::HtmlEncode($target))
        })
        return $token
    })
}

function Render-GuideNode([object]$Node, [int]$Depth, [hashtable]$Anchors) {
    $builder = New-Object Text.StringBuilder
    $markdown = Read-Utf8 $Node.Path
    if ($null -eq $markdown) { return '' }
    $markdown = Remove-ContentsSection $markdown
    $anchor = $Anchors[$Node.Path.ToLowerInvariant()]
    $relative = (Get-Relative $Node.Path $StrataRoot).Replace('\','/')
    $description = if ([string]::IsNullOrWhiteSpace($Node.Description)) { '' } else { [Net.WebUtility]::HtmlEncode($Node.Description) }
    $rendered = ''
    if (-not [string]::IsNullOrWhiteSpace($markdown)) {
        $rendered = Convert-Markdown $markdown ($anchor + '-heading-')
        $rendered = Rewrite-GuideLinks $rendered $Node.Path $Anchors
        $rendered = [regex]::Replace($rendered, '<li>([A-Z][A-Z0-9]*-[0-9]+) —', '<li><strong>$1</strong> —')
        $rendered = Expand-RecordTopics $rendered
    }
    [void]$builder.Append("<article class=`"record`" id=`"$anchor`" data-depth=`"$Depth`" data-source=`"$([Net.WebUtility]::HtmlEncode($relative))`" data-search-item data-nav-target>")
    [void]$builder.Append("<div class=`"source`">$([Net.WebUtility]::HtmlEncode($relative))</div>")
    if (-not [string]::IsNullOrWhiteSpace($description)) { [void]$builder.Append("<p class=`"record-description`">$description</p>") }
    [void]$builder.Append($rendered)
    [void]$builder.Append((Render-TopicCards $Node $Anchors))
    [void]$builder.Append('</article>')
    foreach ($child in @($Node.Children)) { [void]$builder.Append((Render-GuideNode $child ($Depth + 1) $Anchors)) }
    return $builder.ToString()
}

# ---------------------------------------------------------------------------
# Guide composition v1: directive grammar, section identity, block coverage,
# table evidence, watch surfaces, per-section digests and the embedded manifest.
#
# Everything below runs only when `_strata/project_guide.md` exists. The
# authority-only path keeps its pre-v1 generation, digest and status behaviour
# untouched, because a consuming project that has not composed a Guide must not
# see its status output change.
# ---------------------------------------------------------------------------

$GuideManifestSchema = 'strata-guide-manifest/v1'
$GuideSectionKinds = @('topic','workflow','architecture','module-family')
$GuideWatchKinds = @('workflow','architecture','module-family')
$GuideCompositionRelative = '_strata/project_guide.md'

function Get-Sha256Hex([byte[]]$Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-Sha256Text([string]$Text) { return Get-Sha256Hex $Utf8NoBom.GetBytes($Text) }

function Get-FileDigest([string]$FullPath) {
    if (-not (Test-Path -LiteralPath $FullPath -PathType Leaf)) { return '' }
    try { return Get-Sha256Hex ([IO.File]::ReadAllBytes($FullPath)) }
    catch { return '' }
}

# A dedicated serializer. ConvertTo-Json fixes neither property order nor
# whitespace nor escaping, and this JSON is hashed: any of the three would let
# an identical Guide hash differently on a different host.
function ConvertTo-GuideJsonString([string]$Value) {
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('"')
    foreach ($char in $Value.ToCharArray()) {
        if ($char -ceq '"') { [void]$builder.Append('\"') }
        elseif ($char -ceq '\') { [void]$builder.Append('\\') }
        elseif ($char -ceq "`b") { [void]$builder.Append('\b') }
        elseif ($char -ceq "`f") { [void]$builder.Append('\f') }
        elseif ($char -ceq "`n") { [void]$builder.Append('\n') }
        elseif ($char -ceq "`r") { [void]$builder.Append('\r') }
        elseif ($char -ceq "`t") { [void]$builder.Append('\t') }
        elseif ([int][char]$char -lt 32) { [void]$builder.Append('\u').Append(([int][char]$char).ToString('x4')) }
        else { [void]$builder.Append($char) }
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

# Pairs arrive as ordered @(@('key','<already encoded json>'),...). Property
# order is the caller's order, never a hashtable's enumeration order.
function ConvertTo-GuideJsonObject([object[]]$Pairs) {
    $parts = @()
    foreach ($pair in $Pairs) { $parts += ((ConvertTo-GuideJsonString $pair[0]) + ':' + $pair[1]) }
    return '{' + ($parts -join ',') + '}'
}

function ConvertTo-GuideJsonArray([object[]]$Items) {
    if ($null -eq $Items) { return '[]' }
    return '[' + (@($Items) -join ',') + ']'
}

function Sort-GuideOrdinal([object[]]$Values) {
    $list = [Collections.Generic.List[string]]::new()
    foreach ($value in @($Values)) { [void]$list.Add([string]$value) }
    $list.Sort([StringComparer]::Ordinal)
    return @($list.ToArray())
}

function ConvertTo-GuideCitedTargetsJson([object[]]$Targets) {
    $encoded = @()
    foreach ($target in @($Targets)) {
        $encoded += ConvertTo-GuideJsonObject @(
            @('kind',   (ConvertTo-GuideJsonString $target.kind)),
            @('target', (ConvertTo-GuideJsonString $target.target)),
            @('path',   (ConvertTo-GuideJsonString $target.path)),
            @('digest', (ConvertTo-GuideJsonString $target.digest))
        )
    }
    return ConvertTo-GuideJsonArray $encoded
}

function ConvertTo-GuideWatchSurfacesJson([object[]]$Surfaces) {
    $encoded = @()
    foreach ($surface in @($Surfaces)) {
        $entries = @()
        foreach ($entry in @($surface.entries)) {
            $entries += ConvertTo-GuideJsonObject @(
                @('path',   (ConvertTo-GuideJsonString $entry.path)),
                @('digest', (ConvertTo-GuideJsonString $entry.digest))
            )
        }
        $encoded += ConvertTo-GuideJsonObject @(
            @('pattern', (ConvertTo-GuideJsonString $surface.pattern)),
            @('digest',  (ConvertTo-GuideJsonString $surface.digest)),
            @('entries', (ConvertTo-GuideJsonArray $entries))
        )
    }
    return ConvertTo-GuideJsonArray $encoded
}

function Get-GuideInputDigest([object[]]$Targets, [object[]]$Surfaces) {
    $json = ConvertTo-GuideJsonObject @(
        @('cited_targets',  (ConvertTo-GuideCitedTargetsJson $Targets)),
        @('watch_surfaces', (ConvertTo-GuideWatchSurfacesJson $Surfaces))
    )
    return Get-Sha256Text $json
}

# ---- Watch surfaces -------------------------------------------------------

function Get-RepositoryFiles {
    # The expansion set is the sorted union of tracked files and non-ignored
    # untracked files beneath the repository root. Both halves are Git facts, so
    # there is no filesystem substitute: outside a repository the set is empty
    # and a declared watch surface expands to nothing.
    # Not cached: generation and status both run inside one dot-sourced process
    # per invocation, and the set changes between them whenever a watched file
    # is added, deleted or renamed.
    $listed = @(Invoke-GitRead @('-c','core.quotepath=off','ls-files','--cached','--others','--exclude-standard'))
    $unique = @{}
    foreach ($line in $listed) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $relative = $line.Trim().Replace('\','/')
        if ($relative.StartsWith('"')) { continue }
        if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $relative) -PathType Leaf)) { continue }
        $unique[$relative] = $true
    }
    return @(Sort-GuideOrdinal @($unique.Keys))
}

function Test-GuideWatchPattern([string]$Pattern) {
    if ([string]::IsNullOrWhiteSpace($Pattern)) { return 'watch pattern is empty' }
    if ($Pattern.Contains('\')) { return "watch pattern uses a backslash: $Pattern" }
    if ($Pattern.StartsWith('/')) { return "watch pattern is absolute: $Pattern" }
    if ($Pattern -match '^[A-Za-z]:') { return "watch pattern is absolute: $Pattern" }
    if ($Pattern -match '[\[\]\{\}\?!]') { return "watch pattern uses an unsupported wildcard: $Pattern" }
    # Never digest the whole repository: a signal that is always red is a signal
    # nobody reads, so the one pattern that watches everything is refused.
    if ($Pattern -ceq '**') { return 'watch pattern must be narrower than the repository: **' }
    $segments = @($Pattern -split '/')
    for ($i = 0; $i -lt $segments.Count; $i++) {
        $segment = $segments[$i]
        $isLast = ($i -eq $segments.Count - 1)
        if ($segment -eq '') { return "watch pattern has an empty segment: $Pattern" }
        if ($segment -eq '.' -or $segment -eq '..') { return "watch pattern has a relative segment: $Pattern" }
        if ($segment.Contains('**')) {
            if (-not $isLast -or $segment -cne '**') { return "watch pattern may use ** only as the complete final segment: $Pattern" }
            continue
        }
        if ($segment.Contains('*') -and -not $isLast) { return "watch pattern may use * only in the final segment: $Pattern" }
    }
    return ''
}

function Test-GuideWatchMatch([string]$Pattern, [string]$Path) {
    $segments = @($Pattern -split '/')
    if ($segments[$segments.Count - 1] -ceq '**') {
        if ($segments.Count -eq 1) { return $true }
        $prefix = (@($segments[0..($segments.Count - 2)]) -join '/') + '/'
        return $Path.StartsWith($prefix, [StringComparison]::Ordinal)
    }
    $pathSegments = @($Path -split '/')
    if ($pathSegments.Count -ne $segments.Count) { return $false }
    for ($i = 0; $i -lt $segments.Count; $i++) {
        if ($i -eq $segments.Count - 1 -and $segments[$i].Contains('*')) {
            $expression = '^' + ([regex]::Escape($segments[$i]).Replace('\*','[^/]*')) + '$'
            if ($pathSegments[$i] -cnotmatch $expression) { return $false }
        }
        elseif ($segments[$i] -cne $pathSegments[$i]) { return $false }
    }
    return $true
}

function Get-GuideWatchDigest([object[]]$Entries) {
    $builder = New-Object Text.StringBuilder
    foreach ($entry in @($Entries)) { [void]$builder.Append($entry.path).Append([char]0).Append($entry.digest).Append("`n") }
    return Get-Sha256Text $builder.ToString()
}

function Get-GuideWatchSurface([string]$Pattern, [hashtable]$Claimed) {
    # Overlapping declarations store each expanded path once for the section,
    # and the first declaration owns it, so the stored set is a function of
    # declaration order rather than of expansion order. MatchCount reports the
    # full expansion, because the zero-result generation error is about what the
    # pattern matches, not about what an earlier pattern already claimed.
    $byPath = @{}
    $matchCount = 0
    foreach ($relative in @(Get-RepositoryFiles)) {
        if (-not (Test-GuideWatchMatch $Pattern $relative)) { continue }
        $matchCount++
        if ($Claimed.ContainsKey($relative)) { continue }
        $Claimed[$relative] = $true
        $byPath[$relative] = [pscustomobject]@{ path = $relative; digest = (Get-FileDigest (Join-Path $ProjectRoot $relative)) }
    }
    $ordered = @()
    foreach ($path in @(Sort-GuideOrdinal @($byPath.Keys))) { $ordered += $byPath[$path] }
    return [pscustomobject]@{
        pattern = $Pattern
        digest  = (Get-GuideWatchDigest $ordered)
        entries = $ordered
        MatchCount = $matchCount
    }
}

# ---- Composition parsing --------------------------------------------------

function Get-GuideDirective([string]$Line) {
    $match = [regex]::Match($Line, '^\s*\[\[guide:([^\]\s]+)(?:\s+(.*))?\]\]\s*$')
    if (-not $match.Success) { return $null }
    $value = ''
    if ($match.Groups[2].Success) { $value = $match.Groups[2].Value.Trim() }
    return [pscustomobject]@{ Name = $match.Groups[1].Value; Value = $value }
}

function Get-GuideCitationList([string]$Text) {
    $found = @()
    foreach ($match in @([regex]::Matches($Text, '\[(code|authority):\s*([^\]]+)\]'))) {
        $found += [pscustomobject]@{ Kind = $match.Groups[1].Value; Target = $match.Groups[2].Value.Trim() }
    }
    return $found
}

function New-GuideParseError([string]$Message) { throw "Guide composition: $Message" }

function New-GuideSectionRecord([string]$Id, [string]$Kind, [string]$Heading, [int]$Level, [int]$StartLine) {
    return [pscustomobject]@{
        Id = $Id
        Kind = $Kind
        Heading = $Heading
        Level = $Level
        StartLine = $StartLine
        EndLine = $StartLine
        AuthoredMarkdown = ''
        AuthoredDigest = ''
        Blocks = (New-Object System.Collections.ArrayList)
        Tables = (New-Object System.Collections.ArrayList)
        WatchPatterns = (New-Object System.Collections.ArrayList)
        Citations = (New-Object System.Collections.ArrayList)
        DropLines = (New-Object System.Collections.ArrayList)
        Replacements = @{}
        Appends = @{}
        SawContent = $false
    }
}

# One pass over the composition Markdown. Produces the identified sections, the
# evidence-bearing blocks inside them, their exemptions, their table evidence
# and their declared watch patterns. Headings, navigation and literal code are
# structural and never require evidence.
function Read-GuideComposition([string]$Markdown, [switch]$Lenient) {
    $lines = @($Markdown -replace "`r`n?", "`n" -split "`n")
    $sections = New-Object System.Collections.ArrayList
    $ids = @{}
    $documentTitle = $null
    $current = $null
    $inCode = $false
    $lastBlock = $null
    $lastTable = $null
    $sawHeading = $false
    $exemptCounter = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^```') {
            $inCode = -not $inCode
            $lastBlock = $null
            $lastTable = $null
            if ($null -ne $current) { $current.SawContent = $true }
            continue
        }
        if ($inCode) { continue }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $directive = Get-GuideDirective $line
        if ($null -eq $directive -and $line -match '^\s*\[\[guide:') {
            New-GuideParseError "malformed directive (line $($i + 1))"
        }
        if ($null -ne $directive) {
            if ($directive.Name -ceq 'watch') {
                if ($null -eq $current) { New-GuideParseError "a watch declaration must be inside an identified section (line $($i + 1))" }
                if ($current.SawContent) { New-GuideParseError "a watch declaration must precede the section's first content block (line $($i + 1))" }
                $problem = Test-GuideWatchPattern $directive.Value
                if ($problem -and -not $Lenient) { New-GuideParseError "$problem (line $($i + 1))" }
                if (-not $problem) { [void]$current.WatchPatterns.Add($directive.Value) }
                [void]$current.DropLines.Add($i)
                continue
            }
            if ($directive.Name -ceq 'exempt') {
                if ($directive.Value -cne 'framing' -and $directive.Value -cne 'illustration') {
                    New-GuideParseError "unknown exemption '$($directive.Value)' (line $($i + 1))"
                }
                if ($null -eq $current -or $null -eq $lastBlock) { New-GuideParseError "an exemption must follow an evidence-bearing block (line $($i + 1))" }
                if ($lastBlock.Type -ceq 'table') { New-GuideParseError "an exemption cannot exempt a table row (line $($i + 1))" }
                if ($lastBlock.Exemption) { New-GuideParseError "a block carries more than one exemption (line $($i + 1))" }
                if (@($lastBlock.Citations).Count -gt 0) { New-GuideParseError "a block carries both a citation and an exemption (line $($i + 1))" }
                $lastBlock.Exemption = $directive.Value
                $lastBlock.ExemptToken = '@@STRATAEXEMPT' + $exemptCounter + '@@'
                $exemptCounter++
                $current.Appends[$lastBlock.LastLine] = $lastBlock.ExemptToken
                [void]$current.DropLines.Add($i)
                continue
            }
            if ($directive.Name -ceq 'table') {
                if ($directive.Value -cne 'shared') { New-GuideParseError "unknown table directive '$($directive.Value)' (line $($i + 1))" }
                if ($null -eq $current -or $null -eq $lastTable) { New-GuideParseError "a shared table declaration must follow a table (line $($i + 1))" }
                if ($lastTable.Shared) { New-GuideParseError "a table has more than one shared evidence declaration (line $($i + 1))" }
                $shared = @()
                $sharedText = @()
                $j = $i + 1
                while ($j -lt $lines.Count -and -not [string]::IsNullOrWhiteSpace($lines[$j])) {
                    $shared += Get-GuideCitationList $lines[$j]
                    $sharedText += $lines[$j].Trim()
                    [void]$current.DropLines.Add($j)
                    $j++
                }
                if (@($shared).Count -eq 0) { New-GuideParseError "a shared table declaration must be followed by at least one citation (line $($i + 1))" }
                $lastTable.Shared = $true
                foreach ($citation in $shared) { [void]$current.Citations.Add($citation) }
                $current.Replacements[$i] = '@@STRATATABLEEVIDENCE@@ ' + ($sharedText -join ' ')
                $i = $j - 1
                continue
            }
            if ($directive.Name -ceq 'section') {
                New-GuideParseError "a section identity line must follow a level-one or level-two heading (line $($i + 1))"
            }
            if ($directive.Name -ceq 'row') {
                New-GuideParseError "a row override token is valid only inside a table body row (line $($i + 1))"
            }
            New-GuideParseError "unknown directive '$($directive.Name)' (line $($i + 1))"
        }

        $headingMatch = [regex]::Match($line, '^(#{1,6})\s+(.+?)\s*#*$')
        if ($headingMatch.Success) {
            $level = $headingMatch.Groups[1].Value.Length
            $heading = $headingMatch.Groups[2].Value
            if ($level -le 2) {
                if ($null -ne $current) { [void]$sections.Add($current); $current = $null }
                $lastBlock = $null
                $lastTable = $null
                $identity = $null
                $identityLine = -1
                for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                    if ([string]::IsNullOrWhiteSpace($lines[$j])) { continue }
                    $candidate = Get-GuideDirective $lines[$j]
                    if ($null -ne $candidate -and $candidate.Name -ceq 'section') { $identity = $candidate; $identityLine = $j }
                    break
                }
                if ($null -eq $identity) {
                    # The document title is the one heading that owns no section: it holds no
                    # content of its own and another level-one heading follows it.
                    $titleOk = ($level -eq 1) -and (-not $sawHeading) -and ($null -eq $documentTitle)
                    if ($titleOk) {
                        for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                            if ([string]::IsNullOrWhiteSpace($lines[$j])) { continue }
                            $nextHeading = [regex]::Match($lines[$j], '^(#{1,6})\s+(.+?)\s*#*$')
                            if (-not ($nextHeading.Success -and $nextHeading.Groups[1].Value.Length -eq 1)) { $titleOk = $false }
                            break
                        }
                    }
                    if (-not $titleOk) { New-GuideParseError "the heading on line $($i + 1) has no [[guide:section <id> <kind>]] identity" }
                    $documentTitle = $heading
                    $sawHeading = $true
                    continue
                }
                $sawHeading = $true
                $valueMatch = [regex]::Match($identity.Value, '^(\S+)\s+(\S+)$')
                if (-not $valueMatch.Success) { New-GuideParseError "a section identity needs an id and a kind (line $($identityLine + 1))" }
                $sectionId = $valueMatch.Groups[1].Value
                $sectionKind = $valueMatch.Groups[2].Value
                if ($sectionId -cnotmatch '^[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*$') { New-GuideParseError "invalid section id '$sectionId' (line $($identityLine + 1))" }
                if ($GuideSectionKinds -cnotcontains $sectionKind) { New-GuideParseError "invalid section kind '$sectionKind' (line $($identityLine + 1))" }
                if ($ids.ContainsKey($sectionId)) { New-GuideParseError "duplicate section id '$sectionId' (line $($identityLine + 1))" }
                $ids[$sectionId] = $true
                $current = New-GuideSectionRecord $sectionId $sectionKind $heading $level $i
                [void]$current.DropLines.Add($identityLine)
                $i = $identityLine
                continue
            }
            if ($null -eq $current) { New-GuideParseError "the heading on line $($i + 1) precedes the first identified section" }
            $sawHeading = $true
            $current.SawContent = $true
            $lastBlock = $null
            $lastTable = $null
            continue
        }

        if ($null -eq $current) { New-GuideParseError "content on line $($i + 1) precedes the first identified section" }
        $current.SawContent = $true

        # A table is a header row followed by a delimiter row, exactly as the renderer detects it.
        if ($i + 1 -lt $lines.Count -and $line.Contains('|') -and $lines[$i + 1] -match '^\s*\|?\s*:?-{3,}') {
            $table = [pscustomobject]@{ Rows = (New-Object System.Collections.ArrayList); Shared = $false }
            $i++
            while ($i + 1 -lt $lines.Count -and $lines[$i + 1].Contains('|') -and -not [string]::IsNullOrWhiteSpace($lines[$i + 1])) {
                $i++
                $rowText = $lines[$i]
                $override = $false
                if ($rowText.Contains('[[guide:row override]]')) {
                    $override = $true
                    $current.Replacements[$i] = $rowText.Replace('[[guide:row override]]', '')
                }
                $rowCitations = @(Get-GuideCitationList $rowText)
                foreach ($citation in $rowCitations) { [void]$current.Citations.Add($citation) }
                [void]$table.Rows.Add([pscustomobject]@{ Line = $i; Override = $override; Citations = $rowCitations })
            }
            [void]$current.Tables.Add($table)
            $lastTable = $table
            $lastBlock = [pscustomobject]@{ Type='table'; FirstLine=$i; LastLine=$i; Citations=@(); Exemption=''; ExemptToken='' }
            continue
        }

        if ($line -match '^\s*(?:-{3,}|\*{3,}|_{3,})\s*$') { $lastBlock = $null; $lastTable = $null; continue }

        $blockType = 'paragraph'
        if ($line -match '^\s*[-+*]\s+\S' -or $line -match '^\s*\d+[.)]\s+\S') { $blockType = 'list-item' }
        elseif ($line -match '^>') { $blockType = 'callout' }

        $start = $i
        $end = $i
        if ($blockType -ceq 'paragraph') {
            while ($end + 1 -lt $lines.Count) {
                $next = $lines[$end + 1]
                if ([string]::IsNullOrWhiteSpace($next)) { break }
                if ($next -match '^(#{1,6})\s+' -or $next -match '^```' -or $next -match '^\s*[-+*]\s+' -or $next -match '^\s*\d+[.)]\s+' -or $next -match '^>') { break }
                if ($null -ne (Get-GuideDirective $next)) { break }
                if ($next.Contains('|') -and $end + 2 -lt $lines.Count -and $lines[$end + 2] -match '^\s*\|?\s*:?-{3,}') { break }
                $end++
            }
        }
        elseif ($blockType -ceq 'callout') {
            while ($end + 1 -lt $lines.Count -and $lines[$end + 1] -match '^>') { $end++ }
        }
        $text = (@($lines[$start..$end]) -join "`n")
        $block = [pscustomobject]@{
            Type = $blockType
            FirstLine = $start
            LastLine = $end
            Citations = @(Get-GuideCitationList $text)
            Exemption = ''
            ExemptToken = ''
        }
        foreach ($citation in $block.Citations) { [void]$current.Citations.Add($citation) }
        [void]$current.Blocks.Add($block)
        $lastBlock = $block
        $lastTable = $null
        $i = $end
    }
    if ($null -ne $current) { [void]$sections.Add($current) }
    if (@($sections).Count -eq 0) { New-GuideParseError 'the composition declares no identified section' }

    $ordered = @($sections)
    for ($s = 0; $s -lt $ordered.Count; $s++) {
        $section = $ordered[$s]
        $endLine = if ($s + 1 -lt $ordered.Count) { $ordered[$s + 1].StartLine - 1 } else { $lines.Count - 1 }
        $section.EndLine = $endLine
        $section.AuthoredMarkdown = (@($lines[$section.StartLine..$endLine]) -join "`n")
        $section.AuthoredDigest = Get-Sha256Text $section.AuthoredMarkdown
    }
    return [pscustomobject]@{ Sections = $ordered; DocumentTitle = $documentTitle }
}

# Coverage is enforced after parsing, so a parse failure never reports as a
# coverage failure and a coverage failure names the block that caused it.
function Test-GuideCoverage([object]$Section) {
    foreach ($block in @($Section.Blocks)) {
        if (@($block.Citations).Count -gt 0) { continue }
        if ($block.Exemption) { continue }
        New-GuideParseError "an unmarked uncited prose block on line $($block.FirstLine + 1) of section '$($Section.Id)'"
    }
    foreach ($table in @($Section.Tables)) {
        foreach ($row in @($table.Rows)) {
            $rowCitations = @($row.Citations).Count
            if ($row.Override) {
                if (-not $table.Shared) { New-GuideParseError "a row override on line $($row.Line + 1) has no shared table evidence to override" }
                if ($rowCitations -eq 0) { New-GuideParseError "a row override on line $($row.Line + 1) carries no row citation" }
                continue
            }
            if ($table.Shared) { continue }
            if ($rowCitations -eq 0) { New-GuideParseError "a table row on line $($row.Line + 1) of section '$($Section.Id)' has no evidence" }
        }
    }
}

function Get-GuideCoverageCounts([object]$Section) {
    $cited = 0
    $framing = 0
    $illustration = 0
    foreach ($block in @($Section.Blocks)) {
        if ($block.Exemption -ceq 'framing') { $framing++; continue }
        if ($block.Exemption -ceq 'illustration') { $illustration++; continue }
        if (@($block.Citations).Count -gt 0) { $cited++ }
    }
    $rows = 0
    $inherited = 0
    foreach ($table in @($Section.Tables)) {
        foreach ($row in @($table.Rows)) {
            $rows++
            if ($table.Shared -and -not $row.Override) { $inherited++ }
        }
    }
    return [pscustomobject]@{
        CitedBlocks = $cited
        Framing = $framing
        Illustration = $illustration
        TableRows = $rows
        InheritedRows = $inherited
    }
}

# ---- Resolution, digests and rendering ------------------------------------

function Resolve-GuideCitedTargets([object]$Section) {
    $unique = @{}
    foreach ($citation in @($Section.Citations)) {
        # NUL is below every character a target can carry, so sorting the joined
        # key ordinally is exactly "sorted by kind, then target".
        $key = $citation.Kind + [char]0 + $citation.Target
        if ($unique.ContainsKey($key)) { continue }
        $relative = if ($citation.Kind -ceq 'authority') { ($citation.Target -split '#',2)[0] } else { ($citation.Target -split ':',2)[0] }
        $relative = $relative.Replace('\','/').Trim()
        $unique[$key] = [pscustomobject]@{
            kind = $citation.Kind
            target = $citation.Target
            path = $relative
            digest = (Get-FileDigest (Join-Path $ProjectRoot $relative))
        }
    }
    $ordered = @()
    foreach ($key in @(Sort-GuideOrdinal @($unique.Keys))) { $ordered += $unique[$key] }
    return $ordered
}

function Test-GuideSectionReferences([object]$Section, [object]$Graphs) {
    $problems = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($citation in @($Section.Citations)) {
        $key = $citation.Kind + [char]0 + $citation.Target
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $problem = Test-GuideCitation $citation.Kind $citation.Target $ProjectRoot $Graphs
        if ($problem) { [void]$problems.Add($problem) }
    }
    if ($problems.Count -gt 0) {
        throw ("Guide composition has unresolvable references: " + (($problems | Select-Object -Unique) -join '; '))
    }
}

function Get-GuideSectionInputs([object]$Section) {
    $targets = @(Resolve-GuideCitedTargets $Section)
    $surfaces = @()
    $claimed = @{}
    foreach ($pattern in @($Section.WatchPatterns)) { $surfaces += Get-GuideWatchSurface $pattern $claimed }
    return [pscustomobject]@{
        CitedTargets = $targets
        WatchSurfaces = $surfaces
        InputDigest = (Get-GuideInputDigest $targets $surfaces)
    }
}

function Get-GuideSourceDigest([object[]]$Entries) {
    $builder = New-Object Text.StringBuilder
    foreach ($entry in @($Entries)) {
        [void]$builder.Append($entry.Id).Append([char]0).Append($entry.AuthoredDigest).Append([char]0).Append($entry.InputDigest).Append("`n")
    }
    return Get-Sha256Text $builder.ToString()
}

function Get-GuideSectionRenderMarkdown([object]$Section, [string[]]$Lines) {
    $rendered = New-Object System.Collections.Generic.List[string]
    $drop = @{}
    foreach ($index in @($Section.DropLines)) { $drop[[int]$index] = $true }
    for ($i = $Section.StartLine; $i -le $Section.EndLine; $i++) {
        if ($drop.ContainsKey($i)) { continue }
        $line = if ($Section.Replacements.ContainsKey($i)) { [string]$Section.Replacements[$i] } else { $Lines[$i] }
        if ($Section.Appends.ContainsKey($i)) { $line = $line + ' ' + [string]$Section.Appends[$i] }
        $rendered.Add($line)
    }
    return ($rendered -join "`n")
}

function Get-GuideProvenanceHtml([object]$Inputs) {
    if (@($Inputs.WatchSurfaces).Count -eq 0) { return '' }
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('<details class="guide-provenance"><summary>Watched sources</summary><ul>')
    foreach ($surface in @($Inputs.WatchSurfaces)) {
        [void]$builder.Append('<li><code>').Append([Net.WebUtility]::HtmlEncode($surface.pattern)).Append('</code>')
        if (@($surface.entries).Count -gt 0) {
            [void]$builder.Append('<ul>')
            foreach ($entry in @($surface.entries)) { [void]$builder.Append('<li>').Append([Net.WebUtility]::HtmlEncode($entry.path)).Append('</li>') }
            [void]$builder.Append('</ul>')
        }
        [void]$builder.Append('</li>')
    }
    [void]$builder.Append('</ul></details>')
    return $builder.ToString()
}

function Render-GuideSection([object]$Section, [object]$Inputs, [string[]]$Lines, [string]$RepoRoot, [object]$Graphs) {
    $markdown = Get-GuideSectionRenderMarkdown $Section $Lines
    if ($markdown -match '\[\[guide:') { New-GuideParseError "section '$($Section.Id)' contains a malformed or misplaced directive" }
    $problems = New-Object System.Collections.ArrayList
    $citedFiles = New-Object System.Collections.ArrayList
    $chips = New-Object System.Collections.ArrayList
    # Harvest before rendering: a path like `_strata/state/current.md` carries
    # underscores that inline conversion reads as emphasis, so a reference
    # validated after rendering is validated against the wrong string.
    $script:GuideCiteCounter = 0
    $marked = Convert-GuideCitations $markdown $RepoRoot $Graphs $problems $citedFiles $chips
    if ($problems.Count -gt 0) {
        throw ("Guide composition has unresolvable references: " + (($problems | Select-Object -Unique) -join '; '))
    }
    $html = Convert-Markdown $marked ('guide-' + $Section.Id + '-h-')
    foreach ($chip in @($chips)) { $html = $html.Replace($chip.Token, $chip.Html) }
    $html = [regex]::Replace($html, '(?s)<p>@@STRATATABLEEVIDENCE@@\s*(.*?)</p>', {
        param($m)
        '<div class="table-evidence"><span class="table-evidence-label">Table evidence</span>' + $m.Groups[1].Value + '</div>'
    })
    foreach ($block in @($Section.Blocks)) {
        if (-not $block.Exemption) { continue }
        $label = if ($block.Exemption -ceq 'framing') { 'Framing — not sourced' } else { 'Illustration — hypothetical' }
        $badge = '<span class="guide-exempt guide-exempt-' + $block.Exemption + '">' + $label + '</span>'
        $html = $html.Replace($block.ExemptToken, $badge)
    }
    $html = $html + (Get-GuideProvenanceHtml $Inputs)
    $id = [Net.WebUtility]::HtmlEncode($Section.Id)
    $kind = [Net.WebUtility]::HtmlEncode($Section.Kind)
    return ('<section class="guide-topic" data-guide-section-id="{0}" data-guide-section-kind="{1}"><div class="guide-topic-body" id="guide-section-{0}" data-search-item data-nav-target>{2}</div></section>' -f $id,$kind,$html)
}

function Get-GuideRenderedSectionList([string]$Html) {
    # A list, not a map: two boundaries carrying one id must be visible as a
    # defect rather than collapsing into a single entry.
    $found = @()
    foreach ($match in @([regex]::Matches($Html, '(?s)<section class="guide-topic" data-guide-section-id="([^"]*)"[^>]*>.*?</section>'))) {
        $found += [pscustomobject]@{ Id = [Net.WebUtility]::HtmlDecode($match.Groups[1].Value); Html = $match.Value }
    }
    return $found
}

function ConvertTo-GuideManifestJson([object[]]$Entries, [string]$SourceDigest, [string]$GeneratedAt, [string]$GenerationCommit) {
    $sections = @()
    foreach ($entry in @($Entries)) {
        $sections += ConvertTo-GuideJsonObject @(
            @('id',              (ConvertTo-GuideJsonString $entry.Id)),
            @('kind',            (ConvertTo-GuideJsonString $entry.Kind)),
            @('heading',         (ConvertTo-GuideJsonString $entry.Heading)),
            @('authored_digest', (ConvertTo-GuideJsonString $entry.AuthoredDigest)),
            @('input_digest',    (ConvertTo-GuideJsonString $entry.InputDigest)),
            @('rendered_digest', (ConvertTo-GuideJsonString $entry.RenderedDigest)),
            @('cited_targets',   (ConvertTo-GuideCitedTargetsJson $entry.CitedTargets)),
            @('watch_surfaces',  (ConvertTo-GuideWatchSurfacesJson $entry.WatchSurfaces))
        )
    }
    return ConvertTo-GuideJsonObject @(
        @('schema',            (ConvertTo-GuideJsonString $GuideManifestSchema)),
        @('generated_at',      (ConvertTo-GuideJsonString $GeneratedAt)),
        @('generation_commit', (ConvertTo-GuideJsonString $GenerationCommit)),
        @('composition_path',  (ConvertTo-GuideJsonString $GuideCompositionRelative)),
        @('source_digest',     (ConvertTo-GuideJsonString $SourceDigest)),
        @('sections',          (ConvertTo-GuideJsonArray $sections))
    )
}

function Test-GuideManifestPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if ($Path.Contains('\')) { return $false }
    if ($Path.StartsWith('/')) { return $false }
    if ($Path -match '^[A-Za-z]:') { return $false }
    foreach ($segment in @($Path -split '/')) {
        if ($segment -eq '' -or $segment -eq '.' -or $segment -eq '..') { return $false }
    }
    return $true
}

function New-GuideProvenanceFailure([string]$Reason) {
    return [pscustomobject]@{ Valid=$false; Reason=$Reason; Sections=@(); Rendered=@{}; SourceDigest=''; GenerationCommit='' }
}

function Test-GuideDigestField([object]$Value) {
    if ($Value -isnot [string]) { return $false }
    return ([string]$Value -cmatch '^[0-9a-f]{64}$')
}

function Test-GuideOrdinalAscending([object[]]$Keys) {
    for ($i = 1; $i -lt @($Keys).Count; $i++) {
        if ([StringComparer]::Ordinal.Compare([string]$Keys[$i - 1], [string]$Keys[$i]) -ge 0) { return $false }
    }
    return $true
}

# One contract, used in all three places provenance matters: reading an existing
# Guide for status, reading the previous Guide before carrying bytes forward,
# and checking the candidate before it replaces anything. Every failure maps to
# the confirmed closed reason-code set.
function Test-GuideProvenance([string]$Html) {
    $templates = @([regex]::Matches($Html, '<template id="strata-guide-manifest"'))
    if ($templates.Count -eq 0) { return New-GuideProvenanceFailure 'missing-manifest' }
    if ($templates.Count -gt 1) { return New-GuideProvenanceFailure 'corrupt-manifest' }
    $match = [regex]::Match($Html, '(?s)<template id="strata-guide-manifest" data-schema="([^"]*)">(.*?)</template>')
    if (-not $match.Success) { return New-GuideProvenanceFailure 'corrupt-manifest' }
    if ($match.Groups[1].Value -cne $GuideManifestSchema) { return New-GuideProvenanceFailure 'unsupported-manifest-schema' }

    $parsed = $null
    try { $parsed = [Net.WebUtility]::HtmlDecode($match.Groups[2].Value) | ConvertFrom-Json }
    catch { return New-GuideProvenanceFailure 'corrupt-manifest' }
    if ($null -eq $parsed -or $parsed -isnot [System.Management.Automation.PSCustomObject]) { return New-GuideProvenanceFailure 'corrupt-manifest' }

    $topLevel = @('schema','generated_at','generation_commit','composition_path','source_digest','sections')
    $present = @($parsed.PSObject.Properties | ForEach-Object { $_.Name })
    if (@($present).Count -ne @($topLevel).Count) { return New-GuideProvenanceFailure 'corrupt-manifest' }
    foreach ($name in $topLevel) { if ($present -cnotcontains $name) { return New-GuideProvenanceFailure 'corrupt-manifest' } }
    foreach ($name in @('schema','generation_commit','composition_path','source_digest')) {
        if ($parsed.$name -isnot [string]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
    }
    # generated_at is written as an ISO-8601 UTC timestamp, which ConvertFrom-Json deserializes to
    # [DateTime] on PowerShell 6 and later. The CLR type it returns is a host detail, not corruption,
    # so the wire format is what gets validated. Nothing downstream reads this field.
    $generatedAt = if ($parsed.generated_at -is [DateTime]) {
        ([DateTime]$parsed.generated_at).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    } else { [string]$parsed.generated_at }
    if ($generatedAt -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') { return New-GuideProvenanceFailure 'corrupt-manifest' }
    if ($parsed.sections -isnot [Array]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
    if ($parsed.schema -cne $GuideManifestSchema) { return New-GuideProvenanceFailure 'unsupported-manifest-schema' }
    if (-not (Test-GuideDigestField $parsed.source_digest)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
    if ([string]$parsed.composition_path -cne $GuideCompositionRelative) { return New-GuideProvenanceFailure 'invalid-manifest-path' }

    $sectionFields = @('id','kind','heading','authored_digest','input_digest','rendered_digest','cited_targets','watch_surfaces')
    $targetFields = @('kind','target','path','digest')
    $surfaceFields = @('pattern','digest','entries')
    $entryFields = @('path','digest')
    $ids = @{}
    $sections = @()
    $digestEntries = @()
    foreach ($section in @($parsed.sections)) {
        if ($section -isnot [System.Management.Automation.PSCustomObject]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
        $sectionPresent = @($section.PSObject.Properties | ForEach-Object { $_.Name })
        if (@($sectionPresent).Count -ne @($sectionFields).Count) { return New-GuideProvenanceFailure 'corrupt-manifest' }
        foreach ($name in $sectionFields) { if ($sectionPresent -cnotcontains $name) { return New-GuideProvenanceFailure 'corrupt-manifest' } }
        foreach ($name in @('id','kind','heading','authored_digest','input_digest','rendered_digest')) {
            if ($section.$name -isnot [string]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
        }
        if ($section.cited_targets -isnot [Array] -or $section.watch_surfaces -isnot [Array]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
        if ([string]$section.id -cnotmatch '^[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*$') { return New-GuideProvenanceFailure 'corrupt-manifest' }
        if ($GuideSectionKinds -cnotcontains [string]$section.kind) { return New-GuideProvenanceFailure 'corrupt-manifest' }
        foreach ($digest in @($section.authored_digest,$section.input_digest,$section.rendered_digest)) {
            if (-not (Test-GuideDigestField $digest)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
        }
        if ($ids.ContainsKey([string]$section.id)) { return New-GuideProvenanceFailure 'duplicate-section-id' }
        $ids[[string]$section.id] = $true

        $targetKeys = @()
        foreach ($target in @($section.cited_targets)) {
            if ($target -isnot [System.Management.Automation.PSCustomObject]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            $targetPresent = @($target.PSObject.Properties | ForEach-Object { $_.Name })
            if (@($targetPresent).Count -ne @($targetFields).Count) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            foreach ($name in $targetFields) {
                if ($targetPresent -cnotcontains $name) { return New-GuideProvenanceFailure 'corrupt-manifest' }
                if ($target.$name -isnot [string]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            }
            if (@('code','authority') -cnotcontains [string]$target.kind) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            if ([string]::IsNullOrWhiteSpace([string]$target.target)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            if (-not (Test-GuideManifestPath ([string]$target.path))) { return New-GuideProvenanceFailure 'invalid-manifest-path' }
            if (-not (Test-GuideDigestField $target.digest)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            $targetKeys += ([string]$target.kind + [char]0 + [string]$target.target)
        }
        # Sorted by kind then target, and therefore also unique.
        if (-not (Test-GuideOrdinalAscending $targetKeys)) { return New-GuideProvenanceFailure 'corrupt-manifest' }

        $patterns = @{}
        $storedPaths = @{}
        foreach ($surface in @($section.watch_surfaces)) {
            if ($surface -isnot [System.Management.Automation.PSCustomObject]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            $surfacePresent = @($surface.PSObject.Properties | ForEach-Object { $_.Name })
            if (@($surfacePresent).Count -ne @($surfaceFields).Count) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            foreach ($name in $surfaceFields) { if ($surfacePresent -cnotcontains $name) { return New-GuideProvenanceFailure 'corrupt-manifest' } }
            if ($surface.pattern -isnot [string] -or $surface.digest -isnot [string]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            if ($surface.entries -isnot [Array]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            if (Test-GuideWatchPattern ([string]$surface.pattern)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            if ($patterns.ContainsKey([string]$surface.pattern)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            $patterns[[string]$surface.pattern] = $true
            if (-not (Test-GuideDigestField $surface.digest)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            $entryPaths = @()
            foreach ($entry in @($surface.entries)) {
                if ($entry -isnot [System.Management.Automation.PSCustomObject]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
                $entryPresent = @($entry.PSObject.Properties | ForEach-Object { $_.Name })
                if (@($entryPresent).Count -ne @($entryFields).Count) { return New-GuideProvenanceFailure 'corrupt-manifest' }
                foreach ($name in $entryFields) {
                    if ($entryPresent -cnotcontains $name) { return New-GuideProvenanceFailure 'corrupt-manifest' }
                    if ($entry.$name -isnot [string]) { return New-GuideProvenanceFailure 'corrupt-manifest' }
                }
                if (-not (Test-GuideManifestPath ([string]$entry.path))) { return New-GuideProvenanceFailure 'invalid-manifest-path' }
                if (-not (Test-GuideDigestField $entry.digest)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
                # One stored path per section, however the declared patterns overlap.
                if ($storedPaths.ContainsKey([string]$entry.path)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
                $storedPaths[[string]$entry.path] = $true
                $entryPaths += [string]$entry.path
            }
            if (-not (Test-GuideOrdinalAscending $entryPaths)) { return New-GuideProvenanceFailure 'corrupt-manifest' }
            if ((Get-GuideWatchDigest @($surface.entries)) -cne [string]$surface.digest) { return New-GuideProvenanceFailure 'corrupt-manifest' }
        }

        if ((Get-GuideInputDigest @($section.cited_targets) @($section.watch_surfaces)) -cne [string]$section.input_digest) {
            return New-GuideProvenanceFailure 'corrupt-manifest'
        }
        $digestEntries += [pscustomobject]@{
            Id = [string]$section.id
            AuthoredDigest = [string]$section.authored_digest
            InputDigest = [string]$section.input_digest
        }
        $sections += $section
    }

    $sourceDigest = [string]$parsed.source_digest
    if ((Get-GuideSourceDigest $digestEntries) -cne $sourceDigest) { return New-GuideProvenanceFailure 'corrupt-manifest' }

    # The page and the manifest must agree about what produced them.
    $shellDigest = [regex]::Match($Html, '\bdata-source-digest="([^"]*)"', 'IgnoreCase')
    if (-not $shellDigest.Success -or [Net.WebUtility]::HtmlDecode($shellDigest.Groups[1].Value) -cne $sourceDigest) {
        return New-GuideProvenanceFailure 'corrupt-manifest'
    }
    $generationCommit = [string]$parsed.generation_commit
    $shellCommit = [regex]::Match($Html, '\bdata-generation-commit="([^"]*)"', 'IgnoreCase')
    if (-not $shellCommit.Success -or [Net.WebUtility]::HtmlDecode($shellCommit.Groups[1].Value) -cne $generationCommit) {
        return New-GuideProvenanceFailure 'corrupt-manifest'
    }

    $renderedList = @(Get-GuideRenderedSectionList $Html)
    if (@($renderedList).Count -ne @($sections).Count) { return New-GuideProvenanceFailure 'rendered-digest-mismatch' }
    $rendered = @{}
    foreach ($item in $renderedList) {
        if ($rendered.ContainsKey($item.Id)) { return New-GuideProvenanceFailure 'rendered-digest-mismatch' }
        $rendered[$item.Id] = $item.Html
    }
    foreach ($section in @($sections)) {
        $sectionId = [string]$section.id
        if (-not $rendered.ContainsKey($sectionId)) { return New-GuideProvenanceFailure 'rendered-digest-mismatch' }
        if ((Get-Sha256Text $rendered[$sectionId]) -cne [string]$section.rendered_digest) { return New-GuideProvenanceFailure 'rendered-digest-mismatch' }
    }

    return [pscustomobject]@{
        Valid = $true
        Reason = ''
        Sections = $sections
        Rendered = $rendered
        SourceDigest = $sourceDigest
        GenerationCommit = $generationCommit
    }
}

# Builds every composition artifact: the rendered sections, their navigation,
# the manifest and the coverage records. Throws on any generation error, before
# the caller has touched the existing Guide.
function Build-GuideComposition([string]$CompositionPath, [object]$Graphs, [string]$GeneratedAt, [string]$GenerationCommit) {
    $markdown = Read-Utf8 $CompositionPath
    if ($null -eq $markdown) { throw "Guide composition source could not be read: $CompositionPath" }
    $lines = @($markdown -replace "`r`n?", "`n" -split "`n")
    $parsed = Read-GuideComposition $markdown

    # Carry-forward: a section whose authored Markdown and whose resolved inputs
    # both still match the previous manifest reuses its previous rendered bytes.
    # Carried bytes may come only from a Guide whose whole provenance still
    # verifies: manifest, section boundaries and every rendered digest. A page
    # someone edited by hand must not be laundered into a fresh manifest.
    $previous = @{}
    if (Test-Path -LiteralPath $GuidePath -PathType Leaf) {
        try {
            $previousProvenance = Test-GuideProvenance ([IO.File]::ReadAllText($GuidePath, $Utf8Strict))
            if ($previousProvenance.Valid) {
                foreach ($entry in @($previousProvenance.Sections)) {
                    $entryId = [string]$entry.id
                    $previous[$entryId] = [pscustomobject]@{
                        AuthoredDigest = [string]$entry.authored_digest
                        InputDigest = [string]$entry.input_digest
                        Rendered = $previousProvenance.Rendered[$entryId]
                    }
                }
            }
        }
        catch { $previous = @{} }
    }

    $entries = @()
    $bodies = @()
    $warnings = @()
    $coverage = @()
    foreach ($section in @($parsed.Sections)) {
        Test-GuideCoverage $section
        # Before, not after, the carry-forward decision: routing and locator
        # rules can move without any cited file changing, and a carried section
        # must never ship a reference that no longer resolves.
        Test-GuideSectionReferences $section $Graphs
        $inputs = Get-GuideSectionInputs $section
        foreach ($surface in @($inputs.WatchSurfaces)) {
            if ($surface.MatchCount -eq 0) { New-GuideParseError "watch pattern '$($surface.pattern)' in section '$($section.Id)' matches no readable file" }
        }
        if (@($section.WatchPatterns).Count -eq 0 -and $GuideWatchKinds -ccontains $section.Kind) {
            $warnings += "GUIDE_WARNING section=$($section.Id) code=missing-watch-surface"
        }
        $carried = $false
        $rendered = ''
        if ($previous.ContainsKey($section.Id)) {
            $candidate = $previous[$section.Id]
            if ($candidate.AuthoredDigest -ceq $section.AuthoredDigest -and $candidate.InputDigest -ceq $inputs.InputDigest) {
                $rendered = $candidate.Rendered
                $carried = $true
            }
        }
        if (-not $carried) { $rendered = Render-GuideSection $section $inputs $lines $ProjectRoot $Graphs }
        $counts = Get-GuideCoverageCounts $section
        $coverage += ("GUIDE_COVERAGE section={0} cited_blocks={1} framing_exemptions={2} illustration_exemptions={3} table_rows={4} inherited_rows={5}" -f `
            $section.Id,$counts.CitedBlocks,$counts.Framing,$counts.Illustration,$counts.TableRows,$counts.InheritedRows)
        $entries += [pscustomobject]@{
            Id = $section.Id
            Kind = $section.Kind
            Heading = $section.Heading
            Level = $section.Level
            AuthoredDigest = $section.AuthoredDigest
            InputDigest = $inputs.InputDigest
            RenderedDigest = (Get-Sha256Text $rendered)
            CitedTargets = $inputs.CitedTargets
            WatchSurfaces = $inputs.WatchSurfaces
            CarriedForward = $carried
        }
        $bodies += $rendered
    }
    $sourceDigest = Get-GuideSourceDigest $entries
    $manifestJson = ConvertTo-GuideManifestJson $entries $sourceDigest $GeneratedAt $GenerationCommit
    $manifestHtml = '<template id="strata-guide-manifest" data-schema="' + $GuideManifestSchema + '">' + [Net.WebUtility]::HtmlEncode($manifestJson) + '</template>'
    return [pscustomobject]@{
        Sections = $entries
        DocumentTitle = $parsed.DocumentTitle
        Body = ($bodies -join '')
        ManifestHtml = $manifestHtml
        SourceDigest = $sourceDigest
        Warnings = $warnings
        Coverage = $coverage
    }
}

function Get-GuideCompositionNavigation([object]$Composition) {
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('<li data-nav-item data-target="how-it-works"><a href="#how-it-works">Guide</a><span class="nav-description">What the application does and how it behaves.</span><ul class="nav-topics">')
    $inGroup = $false
    foreach ($entry in @($Composition.Sections)) {
        $anchor = 'guide-section-' + [Net.WebUtility]::HtmlEncode($entry.Id)
        $label = [Net.WebUtility]::HtmlEncode($entry.Heading)
        if ($entry.Level -eq 1) {
            if ($inGroup) { [void]$builder.Append('</ul></li>') }
            [void]$builder.Append(("<li class=`"nav-group`" data-nav-item data-target=`"{0}`"><a href=`"#{0}`">{1}</a><ul class=`"nav-topics`">" -f $anchor,$label))
            $inGroup = $true
            continue
        }
        [void]$builder.Append(("<li data-nav-item data-target=`"{0}`"><a href=`"#{0}`">{1}</a></li>" -f $anchor,$label))
    }
    if ($inGroup) { [void]$builder.Append('</ul></li>') }
    [void]$builder.Append('</ul></li>')
    return $builder.ToString()
}

# ---- Composition status ---------------------------------------------------

function Get-GuideCurrentSectionState([string]$CompositionPath) {
    # Status never fails on a draft. When the composition cannot be parsed for
    # structure, every generated section is reported as changed rather than
    # raising a generation error a reader did not ask for.
    $markdown = Read-Utf8 $CompositionPath
    if ($null -eq $markdown) { return $null }
    $parsed = $null
    try { $parsed = Read-GuideComposition $markdown -Lenient }
    catch { return $null }
    $state = New-Object Collections.Specialized.OrderedDictionary
    foreach ($section in @($parsed.Sections)) {
        $inputs = Get-GuideSectionInputs $section
        $state[$section.Id] = [pscustomobject]@{
            Id = $section.Id
            AuthoredDigest = $section.AuthoredDigest
            InputDigest = $inputs.InputDigest
            CitedTargets = $inputs.CitedTargets
            WatchSurfaces = $inputs.WatchSurfaces
        }
    }
    return $state
}

function Get-GuidePathDigestMap([object]$CitedTargets, [object]$WatchSurfaces) {
    $map = @{}
    foreach ($target in @($CitedTargets)) { $map[[string]$target.path] = [string]$target.digest }
    foreach ($surface in @($WatchSurfaces)) {
        foreach ($entry in @($surface.entries)) { $map[[string]$entry.path] = [string]$entry.digest }
    }
    return $map
}

function Write-GuideCompositionStatus([string]$CompositionPath) {
    $state = Get-GuideCurrentSectionState $CompositionPath
    $currentEntries = @()
    if ($null -ne $state) { foreach ($key in @($state.Keys)) { $currentEntries += $state[$key] } }
    $currentDigest = Get-GuideSourceDigest $currentEntries

    if (-not (Test-Path -LiteralPath $GuidePath -PathType Leaf)) {
        Write-Output "GUIDE_MISSING current_digest=$currentDigest"
        return
    }
    try { $html = [IO.File]::ReadAllText($GuidePath, $Utf8Strict) }
    catch {
        Write-Output 'GUIDE_INVALID reason=utf8'
        return
    }
    $manifest = Test-GuideProvenance $html
    if (-not $manifest.Valid) {
        Write-Output "GUIDE_INVALID reason=$($manifest.Reason)"
        return
    }

    $baseCommit = $manifest.GenerationCommit
    $commitMatch = [regex]::Match($html, '\bdata-generation-commit="([^"]+)"', 'IgnoreCase')
    if ($commitMatch.Success) { $baseCommit = $commitMatch.Groups[1].Value }
    $commitsSince = 'unknown'
    $authorityCommitsSince = 'unknown'
    if ($baseCommit -match '^[0-9a-f]{40}$') {
        $null = @(Invoke-GitRead @('merge-base','--is-ancestor',$baseCommit,'HEAD'))
        if ($LASTEXITCODE -eq 0) {
            $count = @(Invoke-GitRead @('rev-list','--count',("$baseCommit..HEAD")))
            if ($count.Count -gt 0) { $commitsSince = $count[0] }
            $authorityCount = @(Invoke-GitRead @('rev-list','--count',("$baseCommit..HEAD"),'--','_strata/state','_strata/rationale','_strata/build-log'))
            if ($authorityCount.Count -gt 0) { $authorityCommitsSince = $authorityCount[0] }
        }
    }
    $authorityDirty = @(Invoke-GitRead @('status','--porcelain','--','_strata/state','_strata/rationale','_strata/build-log')).Count -gt 0

    $manifestById = @{}
    $orderedIds = @()
    if ($null -ne $state) { foreach ($key in @($state.Keys)) { $orderedIds += [string]$key } }
    foreach ($entry in @($manifest.Sections)) {
        $manifestById[[string]$entry.id] = $entry
        if ($orderedIds -cnotcontains [string]$entry.id) { $orderedIds += [string]$entry.id }
    }

    $stale = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($id in $orderedIds) {
        $changed = @{}
        $currentSection = $null
        if ($null -ne $state -and $state.Contains($id)) { $currentSection = $state[$id] }
        $manifestSection = $null
        if ($manifestById.ContainsKey($id)) { $manifestSection = $manifestById[$id] }
        if ($null -eq $currentSection -or $null -eq $manifestSection) {
            $changed[($GuideCompositionRelative + '#' + $id)] = $true
        }
        else {
            if ($currentSection.AuthoredDigest -cne [string]$manifestSection.authored_digest) { $changed[($GuideCompositionRelative + '#' + $id)] = $true }
            $currentMap = Get-GuidePathDigestMap $currentSection.CitedTargets $currentSection.WatchSurfaces
            $previousMap = Get-GuidePathDigestMap $manifestSection.cited_targets $manifestSection.watch_surfaces
            foreach ($path in @($currentMap.Keys)) {
                if (-not $previousMap.ContainsKey($path) -or $previousMap[$path] -cne $currentMap[$path]) { $changed[$path] = $true }
            }
            foreach ($path in @($previousMap.Keys)) {
                if (-not $currentMap.ContainsKey($path)) { $changed[$path] = $true }
            }
        }
        if ($changed.Count -eq 0) { continue }
        [void]$stale.Add([pscustomobject]@{ Id = $id; Paths = (Sort-GuideOrdinal @($changed.Keys)) })
        foreach ($path in @($changed.Keys)) { $seen[$path] = $true }
    }

    $sectionCount = @($manifest.Sections).Count
    if ($stale.Count -eq 0 -and $currentDigest -ceq $manifest.SourceDigest) {
        Write-Output ("GUIDE_CURRENT sections={0} digest={1} generated_from={2} commits_since={3} authority_commits_since={4} authority_worktree_dirty={5}" -f `
            $sectionCount,$currentDigest,$baseCommit,$commitsSince,$authorityCommitsSince,$authorityDirty.ToString().ToLowerInvariant())
        return
    }
    Write-Output ("GUIDE_STALE sections={0} changed_sections={1} changed_paths={2} generated_from={3}" -f `
        $sectionCount,$stale.Count,@($seen.Keys).Count,$baseCommit)
    foreach ($entry in $stale) {
        $encoded = @()
        foreach ($path in @($entry.Paths)) { $encoded += ConvertTo-GuideJsonString $path }
        Write-Output ("GUIDE_SECTION_STALE id={0} changed_paths_json={1}" -f $entry.Id,('[' + ($encoded -join ',') + ']'))
    }
}

function New-Guide([object]$Graphs, [string]$Digest) {
    $anchors = @{}
    foreach ($graph in @($Graphs.State,$Graphs.Rationale,$Graphs.BuildLog)) {
        foreach ($path in @($graph.Ordered)) { $anchors[$path.ToLowerInvariant()] = Get-DocAnchor $path }
    }
    $tickets = New-Object System.Collections.ArrayList
    foreach ($path in @($Graphs.State.Ordered)) {
        if ((Split-Path -Leaf $path) -ieq 'index.md') { continue }
        $text = Read-Utf8 $path
        if ($null -eq $text) { continue }
        $current = $null
        foreach ($line in @($text -split "`n")) {
            if ($line -match '^- ([A-Z][A-Z0-9]*-[0-9]+) — (OPEN|IN PROGRESS|BLOCKED|DONE) — (\S.+)$') {
                $current = [pscustomobject]@{ Id=$Matches[1]; Status=$Matches[2]; Description=$Matches[3]; Source=$path; Body=(New-Object System.Collections.ArrayList); Why=(New-Object System.Collections.ArrayList); How=(New-Object System.Collections.ArrayList) }
                [void]$tickets.Add($current)
                continue
            }
            if ($null -ne $current -and $line -match '^\s{2,}\S') { [void]$current.Body.Add($line) }
            if ($null -ne $current -and $line -match '^\s{2,}- (Why|How):\s+(.+)$') {
                $kind = $Matches[1]
                foreach ($match in [regex]::Matches($Matches[2], '\[[^\]]+\]\(([^)]+)\)')) {
                    $raw = ($match.Groups[1].Value -split '#',2)[0]
                    $target = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $path) $raw))
                    [void]$current.$kind.Add($target)
                }
            }
        }
    }
    # A record that names a declared ticket is a source for it. Only ids State declares are
    # matched, so `SHA-256` and `UTF-8` cannot be mistaken for work items. The snippet is the
    # paragraph carrying the mention, not the whole record: the Guide shows what an authority
    # says about this ticket and points at the authority for the rest.
    $declared = @{}
    foreach ($ticket in $tickets) { $declared[$ticket.Id] = $ticket }
    foreach ($graph in @($Graphs.Rationale,$Graphs.BuildLog)) {
        foreach ($recordPath in @($graph.Ordered)) {
            if ((Split-Path -Leaf $recordPath) -ieq 'index.md') { continue }
            $recordText = Read-Utf8 $recordPath
            if ([string]::IsNullOrWhiteSpace($recordText)) { continue }
            foreach ($paragraph in ($recordText -split "(`r?`n){2,}")) {
                $trimmed = $paragraph.Trim()
                if ($trimmed.Length -lt 3) { continue }
                foreach ($id in $declared.Keys) {
                    if ($trimmed -notmatch ('(?<![A-Za-z0-9-])' + [regex]::Escape($id) + '(?![A-Za-z0-9-])')) { continue }
                    $bucket = if ($graph.Name -eq 'Rationale') { 'Why' } else { 'How' }
                    [void]$declared[$id].$bucket.Add([pscustomobject]@{ Path=$recordPath; Text=$trimmed })
                }
            }
        }
    }

    # Resolved before navigation: when a composed guide exists it is the document, and the authorities
    # are what it was composed from rather than pages of their own.
    $compositionPath = Join-Path $ProjectRoot '_strata/project_guide.md'
    $hasComposition = Test-Path -LiteralPath $compositionPath
    $generated = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $snapshot = Get-GitSnapshot
    $composition = $null
    # Validated in full before anything is written: a generation error here
    # leaves the previous Guide untouched.
    if ($hasComposition) { $composition = Build-GuideComposition $compositionPath $Graphs $generated $snapshot.Oid }

    $navigation = New-Object Text.StringBuilder
    [void]$navigation.Append('<ul>')
    if ($hasComposition) {
        # The composed guide is the document. Its own identified sections, not its
        # headings, are what a reader navigates by.
        [void]$navigation.Append((Get-GuideCompositionNavigation $composition))
    }
    if (-not $hasComposition -and $tickets.Count -gt 0) { [void]$navigation.Append('<li data-nav-item data-target="work-overview"><a href="#work-overview">Work overview</a><span class="nav-description">Current work with its linked reasons and evidence.</span></li>') }
    if (-not $hasComposition) { foreach ($graph in @($Graphs.State,$Graphs.Rationale,$Graphs.BuildLog)) { [void]$navigation.Append((Render-GuideNavigationNode $graph.Tree $anchors)) } }
    [void]$navigation.Append('</ul>')

    $body = New-Object Text.StringBuilder

    # The composed explanation is the Guide. It is the part a person reads; the authorities behind it
    # are the working material. It sits beside its own rendered output in `_strata/`, composed by an
    # agent and read here by exact path. It is a project surface: the canonical kit never carries one.
    if ($hasComposition) {
        # Identified sections render as flat siblings. Nothing folds them: the exact
        # bytes of each <section class="guide-topic"> element are digested, and an
        # exemption badge must not be hidden inside a disclosure.
        $documentHeading = if ([string]::IsNullOrWhiteSpace($composition.DocumentTitle)) { 'How it works' } else { $composition.DocumentTitle }
        [void]$body.AppendLine('<section class="guide-section" id="how-it-works" data-nav-target><h1>' + [Net.WebUtility]::HtmlEncode($documentHeading) + '</h1>')
        [void]$body.AppendLine('<div class="source">_strata/project_guide.md &mdash; composed explanation, not an authority</div>')
        [void]$body.Append($composition.Body)
        [void]$body.AppendLine('</section>')
    }
    if (-not $hasComposition -and $tickets.Count -gt 0) {
        [void]$body.AppendLine('<section class="guide-section" id="work-overview" data-nav-target><h1>Work overview</h1><p class="authority-intro">Current work with its linked reasons and implementation evidence.</p>')
        foreach ($ticket in $tickets) {
            $ticketId = [Net.WebUtility]::HtmlEncode($ticket.Id)
            [void]$body.AppendLine(('<article class="ticket" id="ticket-{0}" data-search-item><h2>{0}</h2><p><strong>{1}</strong> — {2}</p>' -f $ticketId,[Net.WebUtility]::HtmlEncode($ticket.Status),[Net.WebUtility]::HtmlEncode($ticket.Description)))
            # What State says: the ticket's own prose, in the words State uses.
            $bodyLines = @($ticket.Body)
            if ($bodyLines.Count -gt 0) {
                $stateAnchor = $anchors[$ticket.Source.ToLowerInvariant()]
                $stateRelative = [Net.WebUtility]::HtmlEncode((Get-Relative $ticket.Source $StrataRoot).Replace('\','/'))
                [void]$body.AppendLine("<h3>What State says</h3>")
                $prefix = 'ticket-' + $ticket.Id.ToLowerInvariant() + '-state-heading-'
                $rendered = Rewrite-GuideLinks (Convert-Markdown (($bodyLines -join "`n") -replace '(?m)^  ', '') $prefix) $ticket.Source $anchors
                [void]$body.AppendLine(('<div class="linked-record"><div class="source"><a href="#{0}">{1}</a></div>{2}</div>' -f $stateAnchor,$stateRelative,$rendered))
            }
            $labels = @{ Why = 'Why — what Rationale says'; How = 'How — what the Build Log says' }
            foreach ($kind in @('Why','How')) {
                $entries = @($ticket.$kind)
                if ($entries.Count -eq 0) {
                    [void]$body.AppendLine(('<h3>{0}</h3><p class="empty">No {1} record names {2}.</p>' -f $labels[$kind],$(if ($kind -eq 'Why') { 'Rationale' } else { 'Build Log' }),$ticketId))
                    continue
                }
                [void]$body.AppendLine("<h3>$($labels[$kind])</h3>")
                $targetNumber = 0
                foreach ($entry in $entries) {
                    $targetNumber++
                    $isSnippet = $entry -isnot [string]
                    $target = if ($isSnippet) { $entry.Path } else { $entry }
                    $markdown = if ($isSnippet) { $entry.Text } else { Remove-ContentsSection (Read-Utf8 $target) }
                    $embeddedPrefix = 'ticket-' + $ticket.Id.ToLowerInvariant() + '-' + $kind.ToLowerInvariant() + '-' + $targetNumber + '-heading-'
                    $rendered = Rewrite-GuideLinks (Convert-Markdown $markdown $embeddedPrefix) $target $anchors
                    $targetAnchor = $anchors[$target.ToLowerInvariant()]
                    $targetRelative = [Net.WebUtility]::HtmlEncode((Get-Relative $target $StrataRoot).Replace('\','/'))
                    [void]$body.AppendLine(('<div class="linked-record"><div class="source"><a href="#{0}">{1}</a></div>{2}</div>' -f $targetAnchor,$targetRelative,$rendered))
                }
            }
            [void]$body.AppendLine('</article>')
        }
        [void]$body.AppendLine('</section>')
    }
    foreach ($graph in @($(if ($hasComposition) { @() } else { $Graphs.State,$Graphs.Rationale,$Graphs.BuildLog }))) {
        $sectionId = 'authority-' + ([regex]::Replace($graph.Name.ToLowerInvariant(), '[^a-z0-9]+', '-')).Trim('-')
        [void]$body.AppendLine("<section class=`"guide-section`" id=`"$sectionId`"><h1>$([Net.WebUtility]::HtmlEncode($graph.Name))</h1>")
        [void]$body.Append((Render-GuideNode $graph.Tree 0 $anchors))
        $recordCount = @($graph.Ordered | Where-Object { (Split-Path -Leaf $_) -ine 'index.md' }).Count
        if ($recordCount -eq 0 -and $graph.Name -in @('Rationale','Build Log')) { [void]$body.AppendLine('<p class="empty">No records yet</p>') }
        [void]$body.AppendLine('</section>')
    }
    $shell = Read-Utf8 $GuideShellPath
    if ($null -eq $shell) { throw "Guide shell could not be read: $GuideShellPath" }
    # With a composition source the exposed digest is the section-derived one;
    # without it the authority digest computed by the caller is unchanged.
    $effectiveDigest = if ($hasComposition) { $composition.SourceDigest } else { $Digest }
    $script:GuideEmittedDigest = $effectiveDigest
    $script:GuideRecords = @()
    if ($hasComposition) { $script:GuideRecords = @($composition.Warnings) + @($composition.Coverage) }
    $html = $shell.Replace('@@STRATA_GENERATOR@@', [Net.WebUtility]::HtmlEncode($GeneratorVersion))
    $html = $html.Replace('@@STRATA_DIGEST@@', [Net.WebUtility]::HtmlEncode($effectiveDigest))
    $html = $html.Replace('@@STRATA_GENERATED_AT@@', [Net.WebUtility]::HtmlEncode($generated))
    $html = $html.Replace('@@STRATA_BASE_COMMIT@@', [Net.WebUtility]::HtmlEncode($snapshot.Oid))
    $html = $html.Replace('@@STRATA_BASE_COMMIT_SHORT@@', [Net.WebUtility]::HtmlEncode($snapshot.Short))
    $html = $html.Replace('@@STRATA_BASE_COMMIT_DATE@@', [Net.WebUtility]::HtmlEncode($snapshot.Date))
    $html = $html.Replace('@@STRATA_BASE_COMMIT_SUBJECT@@', [Net.WebUtility]::HtmlEncode($snapshot.Subject))
    $html = $html.Replace('<!--STRATA_NAVIGATION-->', $navigation.ToString())
    $html = $html.Replace('<!--STRATA_CONTENT-->', $body.ToString())
    $manifest = if ($hasComposition) { $composition.ManifestHtml } else { '' }
    $html = $html.Replace('<!--STRATA_MANIFEST-->', $manifest)
    return $html
}

function Test-GeneratedGuideHtml([string]$Html) {
    if ($Html -match '@@STRATA_|<!--STRATA_') { throw 'Generated Guide contains an unreplaced shell placeholder.' }
    if ($Html -match '(?is)<(?:script|img|iframe|frame|link|audio|video|source)\b[^>]*(?:src|href)\s*=') {
        throw 'Generated Guide contains a loadable resource attribute.'
    }
    # A CSS url() can only load something from inside a stylesheet or a style attribute. Scanning the
    # whole document instead caught authority prose: a Build Log record quoting the literal error
    # "error sending request for url (https://…)" inside a code span blocked generation entirely, and no
    # rewriting of that record would have been honest, because a dated record states what was seen.
    # The shell has its own check (GUIDE_SHELL_EXTERNAL); this one guards what generation emits.
    $stylePatterns = @(
        '(?is)<style\b[^>]*>(.*?)</style>',
        '(?i)\sstyle\s*=\s*"([^"]*)"',
        "(?i)\sstyle\s*=\s*'([^']*)'"
    )
    foreach ($stylePattern in $stylePatterns) {
        foreach ($styleMatch in [regex]::Matches($Html, $stylePattern)) {
            if ($styleMatch.Groups[1].Value -match '(?i)url\s*\(') {
                throw 'Generated Guide contains a CSS url() resource.'
            }
        }
    }
    if ([regex]::Matches($Html, '<script\b', 'IgnoreCase').Count -ne 1) { throw 'Generated Guide must contain exactly one canonical inline script.' }
    $ids = @{}
    foreach ($match in [regex]::Matches($Html, '\bid="([^"]+)"', 'IgnoreCase')) {
        $id = $match.Groups[1].Value
        if ($ids.ContainsKey($id)) { throw "Generated Guide contains duplicate id: $id" }
        $ids[$id] = $true
    }
    foreach ($match in [regex]::Matches($Html, 'href="#([^"]+)"', 'IgnoreCase')) {
        $fragment = [Net.WebUtility]::HtmlDecode($match.Groups[1].Value)
        if (-not $ids.ContainsKey($fragment)) { throw "Generated Guide contains unresolved fragment: #$fragment" }
    }
}
function Invoke-StrataContext {
    $modeCount = @($Check,$CheckAll,$GenerateGuide,$GuideStatus | Where-Object { $_ }).Count
    if ($modeCount -eq 0) { Show-Usage; return 0 }
    if ($modeCount -ne 1) { Write-Error 'Specify exactly one mode.'; Show-Usage; return 2 }
    if ($GenerateGuide -and -not $IsAgentInternalInvocation) {
        Write-Error '-GenerateGuide is agent-internal. Ask the agent to "update the Guide".'
        return 2
    }
    if ($Check -and ($null -eq $Paths -or $Paths.Count -eq 0)) { Write-Error '-Check requires -Paths.'; return 2 }
    if (-not $Check -and $null -ne $Paths -and $Paths.Count -gt 0) { Write-Error '-Paths is valid only with -Check.'; return 2 }

    if ($Check) {
        $applicable = $false
        foreach ($pathArgument in $Paths) {
            if ([IO.Path]::IsPathRooted($pathArgument)) {
                try { $normalized = (Get-Relative ([IO.Path]::GetFullPath($pathArgument)) $ProjectRoot).Replace('\','/') }
                catch { $normalized = $pathArgument.Replace('\','/') }
            }
            else { $normalized = $pathArgument.Replace('\','/') }
            $normalized = $normalized.TrimStart([char[]]@('.','/'))
            if ($normalized -match '^(?:_strata/|AGENTS\.md$|CLAUDE\.md$)') { $applicable = $true; break }
        }
        if (-not $applicable) {
            Write-Output ("CONTEXT_PASS paths={0} no-applicable-context-contract" -f ($Paths -join ','))
            return 0
        }
    }

    $graphs = Invoke-Validation
    if ($Findings.Count -gt 0) {
        foreach ($finding in $Findings) { Write-Output ("{0}: {1}" -f $finding.Code,$finding.Message) }
        Write-Output ("CONTEXT_FAIL ({0} findings)" -f $Findings.Count)
        return 1
    }

    if ($GuideStatus) {
        Write-GuideStatus $graphs
    }
    elseif ($GenerateGuide) {
        $tempGuide = $null
        try {
            $script:GuideRecords = @()
            $script:GuideEmittedDigest = $null
            $digest = Get-SourceDigest $graphs
            $html = New-Guide $graphs $digest
            if ($null -ne $script:GuideEmittedDigest) { $digest = $script:GuideEmittedDigest }
            Test-GeneratedGuideHtml $html
            # The candidate is held to the same provenance contract status will
            # apply to it. A Guide that would be born invalid never replaces one
            # that is valid, and emits no coverage record on its way out.
            if (Test-Path -LiteralPath (Join-Path $ProjectRoot '_strata/project_guide.md') -PathType Leaf) {
                $candidateProvenance = Test-GuideProvenance $html
                if (-not $candidateProvenance.Valid) {
                    throw "Generated Guide provenance is invalid: $($candidateProvenance.Reason)"
                }
            }
            $tempGuide = Join-Path $StrataRoot ('.project_guide.' + [Guid]::NewGuid().ToString('N') + '.tmp')
            [IO.File]::WriteAllText($tempGuide, $html, $Utf8NoBom)
            if (Test-Path -LiteralPath $GuidePath -PathType Leaf) {
                $backup = Join-Path $StrataRoot ('.project_guide.' + [Guid]::NewGuid().ToString('N') + '.bak')
                try { [IO.File]::Replace($tempGuide, $GuidePath, $backup, $true) }
                finally { if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Force } }
            }
            else { [IO.File]::Move($tempGuide, $GuidePath) }
            # Warnings precede coverage records, and a generation error emits neither.
            foreach ($record in @($script:GuideRecords)) { Write-Output $record }
            Write-Output "GUIDE_GENERATED digest=$digest path=$GuidePath"
        }
        catch {
            if ($null -ne $tempGuide -and (Test-Path -LiteralPath $tempGuide)) { Remove-Item -LiteralPath $tempGuide -Force }
            Write-Error "Guide generation failed without replacing the existing Guide: $($_.Exception.Message)"
            return 2
        }
    }
    else {
        if ($Check) { Write-Output ("CONTEXT_PASS paths={0}" -f ($Paths -join ',')) }
        else { Write-Output 'CONTEXT_PASS all' }
    }
    return 0
}

$StrataContextResult = @(Invoke-StrataContext)
$StrataContextExitCode = [int]$StrataContextResult[-1]
$StrataContextResult | Select-Object -SkipLast 1 | ForEach-Object { Write-Output $_ }
if ($MyInvocation.InvocationName -eq '.') { return $StrataContextExitCode }
exit $StrataContextExitCode
