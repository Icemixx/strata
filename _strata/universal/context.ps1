[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$CheckAll,
    [switch]$GenerateGuide,
    [string[]]$Paths
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$GeneratorVersion = 'strata-context-1'
$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Findings = New-Object System.Collections.ArrayList
$UniversalRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$StrataRoot = [IO.Path]::GetFullPath((Split-Path -Parent $UniversalRoot))
$ProjectRoot = [IO.Path]::GetFullPath((Split-Path -Parent $StrataRoot))
$GuidePath = Join-Path $StrataRoot 'project_guide.html'
$RendererPath = Join-Path $UniversalRoot 'vendor\marked-0.3.19.min.js'

function Show-Usage {
    @'
Usage:
  context.ps1 -Check -Paths <changed paths>
  context.ps1 -CheckAll
  context.ps1 -GenerateGuide

-Check and -CheckAll are read-only. Only -GenerateGuide writes project_guide.html.
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
        if ($line -notmatch '^\s*-\s+\[([^\]]+)\]\(([^)]+)\)\s+(?:—|–|-)\s+\S.+$') {
            Add-Finding 'CONTENTS_ENTRY' "${IndexPath}:$($i + 1) is not a described direct-child link."
            continue
        }
        $targetText = $Matches[2]
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
        [void]$entries.Add([pscustomobject]@{ Label = $Matches[1]; Target = $target; Source = $IndexPath })
    }
    return $entries
}

function Build-AuthorityGraph([string]$Name, [string]$DirectoryName) {
    $root = Join-Path $StrataRoot $DirectoryName
    $rootIndex = Join-Path $root 'index.md'
    $owners = @{}
    $ordered = New-Object System.Collections.ArrayList
    $visitedIndexes = @{}
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        Add-Finding 'MISSING_AUTHORITY' "Missing $Name root: $root"
        return [pscustomobject]@{ Name=$Name; Root=$root; RootIndex=$rootIndex; Owners=$owners; Ordered=$ordered }
    }
    if (-not (Test-Path -LiteralPath $rootIndex -PathType Leaf)) {
        Add-Finding 'MISSING_INDEX' "Missing $Name root index: $rootIndex"
        return [pscustomobject]@{ Name=$Name; Root=$root; RootIndex=$rootIndex; Owners=$owners; Ordered=$ordered }
    }
    function Visit-Index([string]$IndexPath) {
        $key = [IO.Path]::GetFullPath($IndexPath).ToLowerInvariant()
        if ($visitedIndexes.ContainsKey($key)) {
            Add-Finding 'INDEX_CYCLE' "Index cycle or duplicate traversal at $IndexPath"
            return
        }
        $visitedIndexes[$key] = $true
        [void]$ordered.Add($IndexPath)
        foreach ($entry in @(Get-ContentsEntries $IndexPath $root)) {
            $targetKey = $entry.Target.ToLowerInvariant()
            if (-not $owners.ContainsKey($targetKey)) { $owners[$targetKey] = New-Object System.Collections.ArrayList }
            [void]$owners[$targetKey].Add($IndexPath)
            if ($owners[$targetKey].Count -gt 1) {
                Add-Finding 'MULTIPLE_OWNERS' "$($entry.Target) has more than one owning Contents entry."
            }
            if ((Split-Path -Leaf $entry.Target) -ieq 'index.md') { Visit-Index $entry.Target }
            else { [void]$ordered.Add($entry.Target) }
        }
    }
    Visit-Index $rootIndex
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
    return [pscustomobject]@{ Name=$Name; Root=$root; RootIndex=$rootIndex; Owners=$owners; Ordered=$ordered }
}

function Test-RequiredFiles {
    foreach ($relative in @(
        'universal_agent_instructions.md',
        'universal\active-agent.md',
        'universal\context-routing.md',
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
    $script:Findings.Clear()
    Test-RequiredFiles
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

function Convert-Markdown([string]$Markdown) {
    if (-not (Test-Path -LiteralPath $RendererPath -PathType Leaf)) { throw "Bundled renderer is missing: $RendererPath" }
    $safeMarkdown = [regex]::Replace($Markdown, '!\[([^\]]*)\]\(([^)]+)\)', '[Image: $1]($2)')
    $temp = Join-Path ([IO.Path]::GetTempPath()) ('strata-render-' + [Guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($temp) | Out-Null
    $input = Join-Path $temp 'input.md'
    $output = Join-Path $temp 'output.html'
    $runner = Join-Path $temp 'runner.js'
    try {
        [IO.File]::WriteAllText($input, $safeMarkdown, $Utf8NoBom)
        $marked = [IO.File]::ReadAllText($RendererPath, $Utf8Strict)
        $runnerText = @'
var fso = new ActiveXObject("Scripting.FileSystemObject");
function readUtf8(path) { var s = new ActiveXObject("ADODB.Stream"); s.Type=2; s.Charset="utf-8"; s.Open(); s.LoadFromFile(path); var v=s.ReadText(); s.Close(); return v; }
function writeUtf8(path,text) { var s = new ActiveXObject("ADODB.Stream"); s.Type=2; s.Charset="utf-8"; s.Open(); s.WriteText(text); s.Position=0; s.Type=1; s.Position=3; var b=s.Read(); s.Close(); var o=new ActiveXObject("ADODB.Stream"); o.Type=1; o.Open(); o.Write(b); o.SaveToFile(path,2); o.Close(); }
var md=readUtf8(WScript.Arguments(0));
var html=marked(md,{gfm:true,tables:true,sanitize:true,mangle:false,headerPrefix:"source-"});
writeUtf8(WScript.Arguments(1),html);
'@
        [IO.File]::WriteAllText($runner, $marked + "`n" + $runnerText, $Utf8NoBom)
        $process = Start-Process -FilePath "$env:SystemRoot\System32\cscript.exe" -ArgumentList @('//E:JScript','//Nologo',$runner,$input,$output) -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $output -PathType Leaf)) { throw "Bundled Markdown renderer failed with exit $($process.ExitCode)." }
        return [IO.File]::ReadAllText($output, $Utf8Strict)
    }
    finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    }
}

function Remove-ContentsSection([string]$Markdown) {
    return [regex]::Replace($Markdown, '(?ms)^## Contents\s*\n.*?(?=^##\s|\z)', '').Trim()
}

function Get-DocAnchor([string]$Path) {
    $relative = (Get-Relative $Path $StrataRoot).Replace('\','/').ToLowerInvariant()
    return 'doc-' + ([regex]::Replace($relative, '[^a-z0-9]+', '-')).Trim('-')
}

function Rewrite-GuideLinks([string]$Html, [string]$SourcePath, [hashtable]$Anchors) {
    return [regex]::Replace($Html, 'href="([^"]+)"', {
        param($m)
        $raw = $m.Groups[1].Value
        if ($raw.StartsWith('#') -or $raw -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') { return $m.Value }
        $pathPart = ($raw -split '#',2)[0]
        try { $target = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $SourcePath) ([Uri]::UnescapeDataString($pathPart)))) }
        catch { return $m.Value }
        $key = $target.ToLowerInvariant()
        if ($Anchors.ContainsKey($key)) { return 'href="#' + $Anchors[$key] + '"' }
        return $m.Value
    })
}

function New-Guide([object]$Graphs, [string]$Digest) {
    $anchors = @{}
    foreach ($graph in @($Graphs.State,$Graphs.Rationale,$Graphs.BuildLog)) {
        foreach ($path in @($graph.Ordered)) { $anchors[$path.ToLowerInvariant()] = Get-DocAnchor $path }
    }
    $body = New-Object Text.StringBuilder
    $tickets = New-Object System.Collections.ArrayList
    foreach ($path in @($Graphs.State.Ordered)) {
        if ((Split-Path -Leaf $path) -ieq 'index.md') { continue }
        $text = Read-Utf8 $path
        if ($null -eq $text) { continue }
        $current = $null
        foreach ($line in @($text -split "`n")) {
            if ($line -match '^- ([A-Z][A-Z0-9]*-[0-9]+) — (OPEN|IN PROGRESS|BLOCKED|DONE) — (\S.+)$') {
                $current = [pscustomobject]@{ Id=$Matches[1]; Status=$Matches[2]; Description=$Matches[3]; Source=$path; Why=(New-Object System.Collections.ArrayList); How=(New-Object System.Collections.ArrayList) }
                [void]$tickets.Add($current)
                continue
            }
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
    if ($tickets.Count -gt 0) {
        [void]$body.AppendLine('<section class="authority"><h1>Work overview</h1>')
        foreach ($ticket in $tickets) {
            $ticketId = [Net.WebUtility]::HtmlEncode($ticket.Id)
            [void]$body.AppendLine(('<article id="ticket-{0}"><h2>{0}</h2><p><strong>{1}</strong> — {2}</p>' -f $ticketId,[Net.WebUtility]::HtmlEncode($ticket.Status),[Net.WebUtility]::HtmlEncode($ticket.Description)))
            foreach ($kind in @('Why','How')) {
                $targets = @($ticket.$kind)
                if ($targets.Count -eq 0) { continue }
                [void]$body.AppendLine("<h3>$kind</h3>")
                foreach ($target in $targets) {
                    $markdown = Remove-ContentsSection (Read-Utf8 $target)
                    $rendered = Rewrite-GuideLinks (Convert-Markdown $markdown) $target $anchors
                    [void]$body.AppendLine(('<div class="linked-record">{0}</div>' -f $rendered))
                }
            }
            [void]$body.AppendLine('</article>')
        }
        [void]$body.AppendLine('</section>')
    }
    foreach ($graph in @($Graphs.State,$Graphs.Rationale,$Graphs.BuildLog)) {
        [void]$body.AppendLine("<section class=`"authority`"><h1>$([Net.WebUtility]::HtmlEncode($graph.Name))</h1>")
        $records = 0
        foreach ($path in @($graph.Ordered)) {
            $markdown = Read-Utf8 $path
            if ($null -eq $markdown) { continue }
            $markdown = Remove-ContentsSection $markdown
            if ([string]::IsNullOrWhiteSpace($markdown)) { continue }
            if ((Split-Path -Leaf $path) -ine 'index.md') { $records++ }
            $rendered = Convert-Markdown $markdown
            $rendered = Rewrite-GuideLinks $rendered $path $anchors
            $anchor = $anchors[$path.ToLowerInvariant()]
            $relative = (Get-Relative $path $StrataRoot).Replace('\','/')
            $rendered = [regex]::Replace($rendered, '<li>([A-Z][A-Z0-9]*-[0-9]+) —', '<li><strong>$1</strong> —')
            [void]$body.AppendLine("<article id=`"$anchor`" data-source=`"$([Net.WebUtility]::HtmlEncode($relative))`"><div class=`"source`">$([Net.WebUtility]::HtmlEncode($relative))</div>$rendered</article>")
        }
        if ($records -eq 0 -and $graph.Name -in @('Rationale','Build Log')) { [void]$body.AppendLine('<p class="empty">No records yet</p>') }
        [void]$body.AppendLine('</section>')
    }
    $generated = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    return @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Project Guide</title><style>
:root{color-scheme:light dark;--bg:#fff;--fg:#202124;--muted:#667085;--card:#f7f8fa;--line:#d0d5dd;--link:#175cd3} @media(prefers-color-scheme:dark){:root{--bg:#101828;--fg:#f2f4f7;--muted:#98a2b3;--card:#1d2939;--line:#475467;--link:#84adff}} *{box-sizing:border-box}body{margin:0 auto;max-width:1100px;padding:2rem;font:16px/1.55 system-ui,sans-serif;background:var(--bg);color:var(--fg)}header{border-bottom:1px solid var(--line);margin-bottom:2rem}.generated,.source,.empty{color:var(--muted)}#search{width:100%;padding:.75rem;margin:1rem 0;border:1px solid var(--line);border-radius:.5rem;background:var(--card);color:var(--fg)}article{padding:1rem;margin:1rem 0;background:var(--card);border:1px solid var(--line);border-radius:.5rem;overflow:auto}.source{font-size:.8rem}a{color:var(--link)}table{border-collapse:collapse}th,td{border:1px solid var(--line);padding:.4rem}pre{overflow:auto;padding:.75rem;border:1px solid var(--line)}
</style></head><body data-generator="$GeneratorVersion" data-source-digest="$Digest"><header><h1>Project Guide</h1><p class="generated">Generated from routed State, Rationale, and Build Log. Do not edit this file.</p><p class="generated">Generated $generated · source digest <code>$Digest</code></p><input id="search" type="search" placeholder="Search the Guide" aria-label="Search the Guide"></header><main>$($body.ToString())</main><script>(function(){var q=document.getElementById('search');q.addEventListener('input',function(){var n=q.value.toLowerCase();document.querySelectorAll('article').forEach(function(a){a.hidden=n&&a.textContent.toLowerCase().indexOf(n)<0;});});})();</script></body></html>
"@
}
$modeCount = @($Check,$CheckAll,$GenerateGuide | Where-Object { $_ }).Count
if ($modeCount -eq 0) { Show-Usage; exit 0 }
if ($modeCount -ne 1) { Write-Error 'Specify exactly one mode.'; Show-Usage; exit 2 }
if ($Check -and ($null -eq $Paths -or $Paths.Count -eq 0)) { Write-Error '-Check requires -Paths.'; exit 2 }
if (-not $Check -and $null -ne $Paths -and $Paths.Count -gt 0) { Write-Error '-Paths is valid only with -Check.'; exit 2 }

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
        exit 0
    }
}

$graphs = Invoke-Validation
if ($Findings.Count -gt 0) {
    foreach ($finding in $Findings) { Write-Output ("{0}: {1}" -f $finding.Code,$finding.Message) }
    Write-Output ("CONTEXT_FAIL ({0} findings)" -f $Findings.Count)
    exit 1
}

if ($GenerateGuide) {
    $tempGuide = $null
    try {
        $digest = Get-SourceDigest $graphs
        $html = New-Guide $graphs $digest
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
        exit 2
    }
}
else {
    if ($Check) { Write-Output ("CONTEXT_PASS paths={0}" -f ($Paths -join ',')) }
    else { Write-Output 'CONTEXT_PASS all' }
}
