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
    try {
        $safeRoot = $ProjectRoot.Replace('\','/')
        $output = @(& git -c "safe.directory=$safeRoot" -C $ProjectRoot @GitArguments 2>$null)
        if ($LASTEXITCODE -ne 0) { return @() }
        return $output
    }
    catch { return @() }
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
        '<!--STRATA_CONTENT-->'
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

function Get-RecordOutline([string]$Markdown, [string]$HeadingPrefix) {
    # A composed guide has two levels and the left pane must show both: "# " names a group of
    # subjects, "## " names a subject. Harvesting only the second flattens six groups into sixteen
    # siblings, which is the grouping being lost between composition and page.
    # Slugs are deduplicated across every level, exactly as Convert-Markdown deduplicates them, or
    # navigation links at an id the renderer never emitted.
    $safePrefix = [regex]::Replace($HeadingPrefix, '[^a-zA-Z0-9_-]', '-')
    $used = @{}
    $items = New-Object System.Collections.ArrayList
    $inCode = $false
    $seenHeading = $false
    $firstTitle = $null
    foreach ($line in @($Markdown -replace "`r`n?", "`n" -split "`n")) {
        if ($line -match '^```') { $inCode = -not $inCode; continue }
        if ($inCode) { continue }
        if ($line -notmatch '^(#{1,6})\s+(.+?)\s*#*$') { continue }
        $level = $Matches[1].Length
        $title = $Matches[2]
        $slug = ([regex]::Replace($title.ToLowerInvariant(), '[^a-z0-9_]+', '-')).Trim('-')
        if ($used.ContainsKey($slug)) { $used[$slug] = $used[$slug] + 1; $slug = $slug + '-' + $used[$slug] }
        else { $used[$slug] = 1 }
        if (-not $seenHeading) {
            $seenHeading = $true
            # The document opens with its own title, which is not a group. Hold it back and only
            # discard it once a later "# " proves it was a title rather than the first group.
            if ($level -eq 1) { $firstTitle = [pscustomobject]@{ Level = 1; Anchor = $safePrefix + $slug; Title = $title }; continue }
        }
        if ($level -gt 2) { continue }
        if ($level -eq 1) { $firstTitle = $null }
        [void]$items.Add([pscustomobject]@{ Level = $level; Anchor = $safePrefix + $slug; Title = $title })
    }
    if ($null -ne $firstTitle) { [void]$items.Insert(0, $firstTitle) }
    return $items
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
    $parts = $Target -split '(?<!^[A-Za-z]):', 2
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
        if ($kind -eq 'code') { [void]$CitedFiles.Add((($target -split '(?<!^[A-Za-z]):', 2)[0])) }
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

    $navigation = New-Object Text.StringBuilder
    [void]$navigation.Append('<ul>')
    if ($hasComposition) {
        # The composed guide is the document. Its own sections are what a reader navigates by.
        [void]$navigation.Append('<li data-nav-item data-target="how-it-works"><a href="#how-it-works">Guide</a><span class="nav-description">What the application does and how it behaves.</span><ul class="nav-topics">')
        $inGroup = $false
        foreach ($topic in @(Get-RecordOutline (Read-Utf8 $compositionPath) 'guide-heading-')) {
            $label = [Net.WebUtility]::HtmlEncode($topic.Title)
            if ($topic.Level -eq 1) {
                if ($inGroup) { [void]$navigation.Append('</ul></li>') }
                [void]$navigation.Append(("<li class=`"nav-group`" data-nav-item data-target=`"{0}`"><a href=`"#{0}`">{1}</a><ul class=`"nav-topics`">" -f $topic.Anchor,$label))
                $inGroup = $true
            }
            else {
                [void]$navigation.Append(("<li data-nav-item data-target=`"{0}`"><a href=`"#{0}`">{1}</a></li>" -f $topic.Anchor,$label))
            }
        }
        if ($inGroup) { [void]$navigation.Append('</ul></li>') }
        [void]$navigation.Append('</ul></li>')
    }
    if (-not $hasComposition -and $tickets.Count -gt 0) { [void]$navigation.Append('<li data-nav-item data-target="work-overview"><a href="#work-overview">Work overview</a><span class="nav-description">Current work with its linked reasons and evidence.</span></li>') }
    if (-not $hasComposition) { foreach ($graph in @($Graphs.State,$Graphs.Rationale,$Graphs.BuildLog)) { [void]$navigation.Append((Render-GuideNavigationNode $graph.Tree $anchors)) } }
    [void]$navigation.Append('</ul>')

    $body = New-Object Text.StringBuilder

    # The composed explanation is the Guide. It is the part a person reads; the authorities behind it
    # are the working material. It sits beside its own rendered output in `_strata/`, composed by an
    # agent and read here by exact path. It is a project surface: the canonical kit never carries one.
    $citationProblems = New-Object System.Collections.ArrayList
    $citedFiles = New-Object System.Collections.ArrayList
    if ($hasComposition) {
        $composed = Read-Utf8 $compositionPath
        if (-not [string]::IsNullOrWhiteSpace($composed)) {
            $chips = New-Object System.Collections.ArrayList
            $script:GuideCiteCounter = 0
            $marked = Convert-GuideCitations (Remove-ContentsSection $composed) $ProjectRoot $Graphs $citationProblems $citedFiles $chips
            $rendered = Convert-Markdown $marked 'guide-heading-'
            foreach ($chip in @($chips)) { $rendered = $rendered.Replace($chip.Token, $chip.Html) }
            $rendered = Expand-RecordTopics $rendered
            [void]$body.AppendLine('<section class="guide-section" id="how-it-works" data-nav-target><h1>How it works</h1>')
            [void]$body.AppendLine('<article class="record" id="doc-guide-composition" data-depth="0" data-search-item data-nav-target>')
            [void]$body.AppendLine('<div class="source">_strata/project_guide.md &mdash; composed explanation, not an authority</div>')
            [void]$body.Append($rendered)
            [void]$body.AppendLine('</article></section>')
        }
        if ($citationProblems.Count -gt 0) {
            throw ("Guide composition has unresolvable references: " + (($citationProblems | Select-Object -Unique) -join '; '))
        }
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
    $generated = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $snapshot = Get-GitSnapshot
    $html = $shell.Replace('@@STRATA_GENERATOR@@', [Net.WebUtility]::HtmlEncode($GeneratorVersion))
    $html = $html.Replace('@@STRATA_DIGEST@@', [Net.WebUtility]::HtmlEncode($Digest))
    $html = $html.Replace('@@STRATA_GENERATED_AT@@', [Net.WebUtility]::HtmlEncode($generated))
    $html = $html.Replace('@@STRATA_BASE_COMMIT@@', [Net.WebUtility]::HtmlEncode($snapshot.Oid))
    $html = $html.Replace('@@STRATA_BASE_COMMIT_SHORT@@', [Net.WebUtility]::HtmlEncode($snapshot.Short))
    $html = $html.Replace('@@STRATA_BASE_COMMIT_DATE@@', [Net.WebUtility]::HtmlEncode($snapshot.Date))
    $html = $html.Replace('@@STRATA_BASE_COMMIT_SUBJECT@@', [Net.WebUtility]::HtmlEncode($snapshot.Subject))
    $html = $html.Replace('<!--STRATA_NAVIGATION-->', $navigation.ToString())
    $html = $html.Replace('<!--STRATA_CONTENT-->', $body.ToString())
    return $html
}

function Test-GeneratedGuideHtml([string]$Html) {
    if ($Html -match '@@STRATA_|<!--STRATA_') { throw 'Generated Guide contains an unreplaced shell placeholder.' }
    if ($Html -match '(?is)<(?:script|img|iframe|frame|link|audio|video|source)\b[^>]*(?:src|href)\s*=') {
        throw 'Generated Guide contains a loadable resource attribute.'
    }
    if ($Html -match '(?i)url\s*\(') { throw 'Generated Guide contains a CSS url() resource.' }
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
            $digest = Get-SourceDigest $graphs
            $html = New-Guide $graphs $digest
            Test-GeneratedGuideHtml $html
            $tempGuide = Join-Path $StrataRoot ('.project_guide.' + [Guid]::NewGuid().ToString('N') + '.tmp')
            [IO.File]::WriteAllText($tempGuide, $html, $Utf8NoBom)
            if (Test-Path -LiteralPath $GuidePath -PathType Leaf) {
                $backup = Join-Path $StrataRoot ('.project_guide.' + [Guid]::NewGuid().ToString('N') + '.bak')
                try { [IO.File]::Replace($tempGuide, $GuidePath, $backup, $true) }
                finally { if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Force } }
            }
            else { [IO.File]::Move($tempGuide, $GuidePath) }
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
