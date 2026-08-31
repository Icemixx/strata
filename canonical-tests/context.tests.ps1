$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)
$StagedStrata = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\_strata'))
$TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('strata-context-tests-' + [Guid]::NewGuid().ToString('N'))
$Passed = 0
$Failed = 0

function Write-Utf8([string]$Path, [string]$Text) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [IO.File]::WriteAllText($Path, $Text.Replace("`r`n","`n"), $Utf8)
}

function Replace-Utf8([string]$Path, [string]$Old, [string]$New) {
    $text = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    Write-Utf8 $Path ($text.Replace($Old, $New))
}

function New-Fixture([string]$Name) {
    $root = Join-Path $TempRoot $Name
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    Copy-Item -LiteralPath $StagedStrata -Destination (Join-Path $root '_strata') -Recurse
    Write-Utf8 (Join-Path $root 'AGENTS.md') @'
# Agent Instructions Router

1. `_strata/universal_agent_instructions.md`
2. `_strata/project_instructions.md`
'@
    Write-Utf8 (Join-Path $root 'CLAUDE.md') @'
# Agent Instructions Router

@_strata/universal_agent_instructions.md

@_strata/project_instructions.md
'@
    Write-Utf8 (Join-Path $root '_strata\project_instructions.md') "# Project Instructions`n"
    Write-Utf8 (Join-Path $root '_strata\state\index.md') @'
# State

## Contents

- [Current work](current.md) — Work that is not complete.
- [Completed work](completed/index.md) — Cold completed work.
'@
    Write-Utf8 (Join-Path $root '_strata\state\current.md') @'
# Current work

- BUG-1 — IN PROGRESS — The fixture is under test.
  - Why: [R1](../rationale/R1.md)
  - How: [Implementation](../build-log/BUG-1.md)
'@
    Write-Utf8 (Join-Path $root '_strata\state\completed\index.md') "# Completed work`n`n## Contents`n"
    Write-Utf8 (Join-Path $root '_strata\rationale\index.md') @'
# Rationale

## Contents

- [R1](R1.md) — Why the fixture exists.
'@
    Write-Utf8 (Join-Path $root '_strata\rationale\R1.md') "# R1`n`nThe fixture exists to test routed context.`n"
    Write-Utf8 (Join-Path $root '_strata\build-log\index.md') @'
# Build Log

## Contents

- [BUG-1 implementation](BUG-1.md) — How the fixture was built.
'@
    Write-Utf8 (Join-Path $root '_strata\build-log\BUG-1.md') "# BUG-1 implementation`n`nThe fixture files were created.`n"
    return $root
}

function New-BrokenFixture([string]$Name) {
    $root = New-Fixture $Name
    Remove-Item -LiteralPath (Join-Path $root '_strata\state\index.md') -Force
    return $root
}

function Invoke-Context([string]$Root, [string[]]$Arguments) {
    $script = Join-Path $Root '_strata\universal\context.ps1'
    $bound = @{}
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        switch ($Arguments[$i]) {
            '-Check' { $bound.Check = $true }
            '-CheckAll' { $bound.CheckAll = $true }
            '-GenerateGuide' { $bound.GenerateGuide = $true }
            '-GuideStatus' { $bound.GuideStatus = $true }
            '-Paths' {
                $bound.Paths = @($Arguments[($i + 1)..($Arguments.Count - 1)])
                $i = $Arguments.Count
            }
            default { throw "Unsupported in-process context argument: $($Arguments[$i])" }
        }
    }
    $result = @(& {
        param([string]$ContextScript, [hashtable]$ContextParameters)
        . $ContextScript @ContextParameters
    } $script $bound 2>&1)
    $exitCode = [int]$result[-1]
    $text = (($result | Select-Object -SkipLast 1 | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine)
    return [pscustomobject]@{ ExitCode=$exitCode; Output=$text }
}

function Invoke-PublicContext([string]$Root, [string[]]$Arguments) {
    # The public path: the shipped script run exactly as README documents it.
    # The single-process contract above forbids the launch cmdlet in this file
    # and any child launch inside context.ps1; running the script is neither.
    $target = Join-Path $Root '_strata\universal\context.ps1'
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $target @Arguments 2>&1 }
    finally { $ErrorActionPreference = $previous }
    return [pscustomobject]@{
        Output   = (($out | ForEach-Object { $_.ToString() }) -join "`n")
        ExitCode = $LASTEXITCODE
    }
}

function Assert-Test([string]$Name, [scriptblock]$Body) {
    try { & $Body; Write-Output "PASS $Name"; $script:Passed++ }
    catch { Write-Output "FAIL $Name :: $($_.Exception.Message) :: $($_.ScriptStackTrace)"; $script:Failed++ }
}

function Assert-True([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }

function Assert-GuideIntegrity([string]$Html) {
    $ids = @([regex]::Matches($Html, '\bid="([^"]+)"', 'IgnoreCase') | ForEach-Object { $_.Groups[1].Value })
    Assert-True ((@($ids | Sort-Object -Unique)).Count -eq $ids.Count) 'Guide contains duplicate IDs'
    foreach ($fragment in @([regex]::Matches($Html, 'href="#([^"]+)"', 'IgnoreCase') | ForEach-Object { [Net.WebUtility]::HtmlDecode($_.Groups[1].Value) })) {
        Assert-True ($fragment -in $ids) "Guide contains unresolved fragment: #$fragment"
    }
    Assert-True ($Html -notmatch '(?is)<(?:script|img|iframe|frame|link|audio|video|source)\b[^>]*(?:src|href)\s*=') 'Guide loads an external resource'
    Assert-True ($Html -notmatch '(?i)url\s*\(') 'Guide contains a CSS url() resource'
    Assert-True ([regex]::Matches($Html, '<script\b', 'IgnoreCase').Count -eq 1) 'Guide does not contain exactly one canonical script'
}

try {
    New-Item -ItemType Directory -Path $TempRoot | Out-Null

    Assert-Test 'no arguments shows help and writes nothing' {
        $root = New-Fixture 'help'
        $result = Invoke-Context $root @()
        Assert-True ($result.ExitCode -eq 0) "exit=$($result.ExitCode) $($result.Output)"
        Assert-True ($result.Output -match 'Usage:') 'usage was not shown'
        Assert-True ($result.Output -notmatch 'GenerateGuide') 'internal generation mode was exposed in user help'
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $root '_strata\project_guide.html'))) 'Guide was written'
    }

    Assert-Test 'context execution stays in one PowerShell process' {
        $launchToken = 'Start-' + 'Process'
        $powershellToken = 'power' + 'shell.exe'
        $scriptHostToken = 'c' + 'script.exe'
        $contextSource = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\context.ps1'), [Text.Encoding]::UTF8)
        $testSource = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8)
        Assert-True ($contextSource -notmatch [regex]::Escape($launchToken)) 'context.ps1 starts a child process'
        Assert-True ($contextSource -notmatch [regex]::Escape($powershellToken)) 'context.ps1 starts child PowerShell'
        Assert-True ($contextSource -notmatch [regex]::Escape($scriptHostToken)) 'context.ps1 starts Windows Script Host'
        Assert-True ($testSource -notmatch [regex]::Escape($launchToken)) 'canonical tests start a child process'
    }

    Assert-Test 'direct user Guide generation is rejected' {
        $root = New-Fixture 'user-generation-rejected'
        $contextScript = Join-Path $root '_strata\universal\context.ps1'
        $escapedScript = $contextScript.Replace("'", "''")
        $runspace = [PowerShell]::Create()
        try {
            [void]$runspace.AddScript("& '$escapedScript' -GenerateGuide")
            $invokeError = ''
            try { [void]$runspace.Invoke() }
            catch { $invokeError = $_.Exception.Message }
            $errorText = @($invokeError) + @($runspace.Streams.Error | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
            Assert-True ($errorText -match 'agent-internal') "direct generation rejection missing: $errorText"
            Assert-True (-not (Test-Path -LiteralPath (Join-Path $root '_strata\project_guide.html'))) 'direct user invocation wrote Guide'
        }
        finally { $runspace.Dispose() }
    }

    Assert-Test 'valid full graph passes' {
        $root = New-Fixture 'pass'
        $result = Invoke-Context $root @('-CheckAll')
        Assert-True ($result.ExitCode -eq 0) "exit=$($result.ExitCode) $($result.Output)"
        Assert-True ($result.Output -match 'CONTEXT_PASS all') 'pass marker missing'
    }

    Assert-Test 'unrelated changed path skips context graph' {
        $root = New-Fixture 'unrelated-path'
        Replace-Utf8 (Join-Path $root '_strata\rationale\index.md') 'R1.md' 'missing.md'
        $result = Invoke-Context $root @('-Check','-Paths','lib/example.dart')
        Assert-True ($result.ExitCode -eq 0) "exit=$($result.ExitCode) $($result.Output)"
        Assert-True ($result.Output -match 'no-applicable-context-contract') 'impact-based marker missing'
    }

    $redCases = @(
        @{ Name='broken link'; Code='BROKEN_LINK'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\rationale\index.md') 'R1.md' 'missing.md' } },
        @{ Name='unindexed record'; Code='UNINDEXED_RECORD'; Mutate={ param($r) Write-Utf8 (Join-Path $r '_strata\rationale\orphan.md') "# Orphan`n" } },
        @{ Name='DONE in current'; Code='DONE_IN_CURRENT'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\state\current.md') 'IN PROGRESS' 'DONE' } },
        @{ Name='router imports harness'; Code='ROUTER_NOT_THIN'; Mutate={ param($r) $p=Join-Path $r 'AGENTS.md'; Write-Utf8 $p ([IO.File]::ReadAllText($p,[Text.Encoding]::UTF8) + "`n_strata/universal/harness-codex.md`n") } },
        @{ Name='Contents lacks description'; Code='CONTENTS_ENTRY'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\build-log\index.md') ' — How the fixture was built.' '' } },
        @{ Name='typed Why targets HOW'; Code='TYPED_LINK_TARGET'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\state\current.md') '../rationale/R1.md' '../build-log/BUG-1.md' } },
        @{ Name='missing Guide shell'; Code='MISSING_REQUIRED_FILE'; Mutate={ param($r) Remove-Item -LiteralPath (Join-Path $r '_strata\universal\guide-shell.html') -Force } },
        @{ Name='duplicate Guide shell placeholder'; Code='GUIDE_SHELL_PLACEHOLDER'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\universal\guide-shell.html') '<!--STRATA_CONTENT-->' '<!--STRATA_CONTENT--><!--STRATA_CONTENT-->' } },
        @{ Name='external Guide shell resource'; Code='GUIDE_SHELL_EXTERNAL'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\universal\guide-shell.html') '<body ' '<img src="https://example.invalid/a.png"><body ' } }
    )
    foreach ($case in $redCases) {
        Assert-Test ("watched red: " + $case.Name) {
            $root = New-Fixture ('red-' + $case.Name.Replace(' ','-'))
            & $case.Mutate $root
            $result = Invoke-Context $root @('-CheckAll')
            Assert-True ($result.ExitCode -eq 1) "exit=$($result.ExitCode) $($result.Output)"
            Assert-True ($result.Output -match [regex]::Escape($case.Code)) "missing $($case.Code): $($result.Output)"
        }
    }

    Assert-Test 'failed generation preserves existing Guide' {
        $root = New-Fixture 'atomic-failure'
        $guide = Join-Path $root '_strata\project_guide.html'
        Write-Utf8 $guide 'SENTINEL'
        Replace-Utf8 (Join-Path $root '_strata\rationale\index.md') 'R1.md' 'missing.md'
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 1) "exit=$($result.ExitCode) $($result.Output)"
        Assert-True ([IO.File]::ReadAllText($guide) -eq 'SENTINEL') 'existing Guide changed'
    }

    Assert-Test 'Guide is offline and sanitizes authority content' {
        $root = New-Fixture 'guide'
        Write-Utf8 (Join-Path $root '_strata\rationale\R1.md') @'
# R1

<script>alert("x")</script>

[unsafe](javascript:alert(1))

![remote image](https://example.invalid/image.png)

| Check | Result |
| --- | --- |
| Render | Passed |
'@
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "exit=$($result.ExitCode) $($result.Output)"
        $html = [IO.File]::ReadAllText((Join-Path $root '_strata\project_guide.html'))
        Assert-True ($html -match 'data-source-digest="[0-9a-f]{64}"') 'digest missing'
        Assert-True ($html -match 'Guide snapshot generated from commit') 'snapshot marker missing'
        Assert-True ($html -match 'data-generator="strata-context-2"') 'generator version missing'
        Assert-True ($html -match 'data-generation-commit="[^"]+"') 'generation commit missing'
        Assert-True ($html -match 'id="ticket-BUG-1"') 'stable ticket anchor missing'
        Assert-True ($html -match '<h3>What State says</h3>') 'ticket State prose missing'

        # Watched red: prove each citation check fails on a planted defect before trusting a pass.
        $composed = Join-Path $root '_sediment\guide'
        [void][IO.Directory]::CreateDirectory($composed)
        $guideMd = Join-Path $composed 'project_guide.md'
        Write-Utf8 $guideMd "# How it works`n`nThe fixture is under test. [code: _strata/state/current.md:BUG-1] [authority: _strata/rationale/R1.md]`n"
        $ok = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($ok.ExitCode -eq 0) "valid citations should generate: $($ok.Output)"
        $composedHtml = [IO.File]::ReadAllText((Join-Path $root '_strata\project_guide.html'))
        Assert-True ($composedHtml -match 'id="how-it-works"') 'composed section missing'
        Assert-True ($composedHtml -match 'class="cite cite-code"') 'code reference not rendered'
        Assert-True ($composedHtml -match 'class="cite cite-authority"') 'authority reference not rendered'

        # A generation refusal surfaces as a terminating error here, not an exit code, because the
        # harness runs with ErrorActionPreference Stop. Assert on the refusal and its reason.
        function Assert-GuideRefused([string]$Root, [string]$Markdown, [string]$Expected, [string]$Why) {
            Write-Utf8 (Join-Path $Root '_sediment\guide\project_guide.md') $Markdown
            $refused = $false; $message = ''
            try { $null = Invoke-Context $Root @('-GenerateGuide') }
            catch { $refused = $true; $message = $_.Exception.Message }
            Assert-True $refused $Why
            Assert-True ($message -match $Expected) "expected '$Expected', got: $message"
        }
        Assert-GuideRefused $root "# How it works`n`nInvented. [code: _strata/state/current.md:NO_SUCH_SYMBOL]`n" 'locator not found' 'a locator absent from its cited file must fail generation'
        Assert-GuideRefused $root "# How it works`n`nInvented. [code: nope/missing.py:thing]`n" 'cited file not found' 'a missing cited file must fail generation'
        Assert-GuideRefused $root "# How it works`n`nInvented. [authority: _sediment/guide/project_guide.md]`n" 'not routed|not found' 'an unrouted authority target must fail generation'
        # Two levels, and the left pane must show both. v1 composed six groups as "# " headings and
        # the renderer harvested only "## ", so sixteen sections rendered as flat siblings.
        $grouped = "# SmartAutoBase`n`n# Operations`n`n## Work orders`n`nThe trio. [code: _strata/state/current.md:BUG-1]`n`n## Vehicles`n`nEvery car. [code: _strata/state/current.md:BUG-1]`n`n# Financial`n`n## Payments`n`nSettled against a work order. [authority: _strata/rationale/R1.md]`n"
        Write-Utf8 $guideMd $grouped
        $groupedRun = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($groupedRun.ExitCode -eq 0) "grouped composition should generate: $($groupedRun.Output)"
        $groupedHtml = [IO.File]::ReadAllText((Join-Path $root '_strata\project_guide.html'))
        Assert-True ($groupedHtml -match '(?s)#guide-heading-operations">Operations</a><ul class="nav-topics"><li[^>]*><a href="#guide-heading-work-orders">Work orders</a></li><li[^>]*><a href="#guide-heading-vehicles">Vehicles</a></li></ul>') 'group did not nest its sections in navigation'
        Assert-True ($groupedHtml -match '#guide-heading-financial">Financial</a><ul class="nav-topics"><li[^>]*><a href="#guide-heading-payments">Payments</a>') 'second group did not nest its sections'
        Assert-True ($groupedHtml -notmatch 'href="#guide-heading-smartautobase"') 'document title was navigated as a group'
        Assert-True ($groupedHtml -match '</details>\s*<h1 id="guide-heading-financial">') 'a group heading was folded into the topic above it'
        Assert-True ($groupedHtml -match '<details class="topic" id="guide-heading-work-orders" open>') 'first topic was not left open'
        Assert-True ($groupedHtml -notmatch '<details class="topic" id="guide-heading-payments" open>') 'a later topic was left open'
        [IO.File]::Delete($guideMd)
        Assert-True ($html -match '<h3>Why[^<]*what Rationale says</h3>') 'ticket-linked WHY section missing'
        Assert-True ($html -match '<h3>How[^<]*what the Build Log says</h3>') 'ticket-linked HOW section missing'
        Assert-True ($html -notmatch '<script>alert') 'raw script executed'
        Assert-True ($html -notmatch 'href="javascript:') 'unsafe link survived'
        Assert-True ($html -notmatch '<img') 'remote image was embedded'
        Assert-True ($html -match '<table>') 'table was not rendered'
        Assert-True ($html -match 'id="search"' -and $html -match 'id="themeToggle"' -and $html -match 'id="toTop"') 'Guide shell controls missing'
        Assert-GuideIntegrity $html
    }

    Assert-Test 'Guide mirrors nested routing and plain-language descriptions' {
        $root = New-Fixture 'nested-guide'
        Replace-Utf8 (Join-Path $root '_strata\state\index.md') "## Contents`n" "## Contents`n`n- [Operations](operations/index.md) - Day-to-day workflows in plain language.`n"
        Write-Utf8 (Join-Path $root '_strata\state\operations\index.md') "# Operations`n`nHow people use the project in normal operation.`n`n## Contents`n`n- [Work orders](work-orders.md) - Create and review work orders safely.`n"
        Write-Utf8 (Join-Path $root '_strata\state\operations\work-orders.md') "# Work orders`n`nUse this workflow to create and review work orders.`n`n## Shared heading`n`n[This section](#shared-heading) and [the decision section](../../rationale/R1.md#shared-heading) must resolve.`n"
        $rationale = Join-Path $root '_strata\rationale\R1.md'
        Write-Utf8 $rationale ([IO.File]::ReadAllText($rationale,[Text.Encoding]::UTF8) + "`n## Shared heading`n`nThe routed decision remains readable.`n")
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "exit=$($result.ExitCode) $($result.Output)"
        $html = [IO.File]::ReadAllText((Join-Path $root '_strata\project_guide.html'))
        Assert-True ($html -match 'Day-to-day workflows in plain language\.') 'branch description missing'
        Assert-True ($html -match 'Create and review work orders safely\.') 'leaf description missing'
        Assert-True ($html -match 'class="topic-card"') 'topic cards missing'
        Assert-True ($html.IndexOf('>Operations<') -lt $html.IndexOf('>Current work<')) 'declared State order was not preserved'
        Assert-True ($html -match 'href="#doc-state-operations-work-orders-md-heading-shared-heading"') 'same-file fragment was not rewritten'
        Assert-True ($html -match 'href="#doc-rationale-r1-md-heading-shared-heading"') 'cross-file fragment was not rewritten'
        Assert-GuideIntegrity $html
    }

    Assert-Test 'Guide status is read-only and detects stale authorities' {
        $root = New-Fixture 'guide-status'
        $result = Invoke-Context $root @('-GuideStatus')
        Assert-True ($result.ExitCode -eq 0 -and $result.Output -match 'GUIDE_MISSING') "missing status failed: $($result.Output)"
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "generation failed: $($result.Output)"
        $guide = Join-Path $root '_strata\project_guide.html'
        $before = [IO.File]::ReadAllText($guide)
        $result = Invoke-Context $root @('-GuideStatus')
        Assert-True ($result.ExitCode -eq 0 -and $result.Output -match 'GUIDE_CURRENT') "current status failed: $($result.Output)"
        $record = Join-Path $root '_strata\rationale\R1.md'
        Write-Utf8 $record ([IO.File]::ReadAllText($record,[Text.Encoding]::UTF8) + "`nChanged after generation.`n")
        $result = Invoke-Context $root @('-GuideStatus')
        Assert-True ($result.ExitCode -eq 0 -and $result.Output -match 'GUIDE_STALE') "stale status failed: $($result.Output)"
        Assert-True ([IO.File]::ReadAllText($guide) -eq $before) 'GuideStatus modified the Guide'
    }

    Assert-Test 'public invocation prints findings and exits non-zero' {
        $root = New-BrokenFixture 'public-fail'
        $target = Join-Path $root '_strata\universal\context.ps1'
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $target -CheckAll 2>&1
        $exit = $LASTEXITCODE
        $text = ($out | ForEach-Object { $_.ToString() }) -join "`n"
        Assert-True ($text -match 'CONTEXT_FAIL') 'public run printed no CONTEXT_FAIL'
        Assert-True ($exit -eq 1) "public run exited $exit, expected 1"
    }

    Assert-Test 'public help is printed with no arguments' {
        $r = Invoke-PublicContext (New-Fixture 'public-help') @()
        Assert-True ($r.Output -match 'Usage:') 'no usage text on the public path'
        Assert-True ($r.ExitCode -eq 0) "help exited $($r.ExitCode), expected 0"
    }

    Assert-Test 'public CheckAll passes a valid graph' {
        $r = Invoke-PublicContext (New-Fixture 'public-pass') @('-CheckAll')
        Assert-True ($r.Output -match 'CONTEXT_PASS all') 'no pass marker on the public path'
        Assert-True ($r.ExitCode -eq 0) "pass exited $($r.ExitCode), expected 0"
    }

    Assert-Test 'public GuideStatus reports a status' {
        $r = Invoke-PublicContext (New-Fixture 'public-status') @('-GuideStatus')
        Assert-True ($r.Output -match 'GUIDE_(MISSING|CURRENT|STALE)') 'no guide status on the public path'
    }

    Assert-Test 'public GenerateGuide is rejected' {
        $r = Invoke-PublicContext (New-Fixture 'public-generate') @('-GenerateGuide')
        Assert-True ($r.ExitCode -ne 0) 'direct user generation was not rejected'
    }

    Assert-Test 'the shipped script decodes as UTF-8 on the documented host' {
        $bytes = [IO.File]::ReadAllBytes((Join-Path $StagedStrata 'universal\context.ps1'))
        Assert-True ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) `
            'context.ps1 has no UTF-8 BOM, so PowerShell 5.1 mis-decodes its Unicode literals'
    }

    Assert-Test 'inline code survives emphasis processing' {
        $root = New-Fixture 'inline-code'
        Write-Utf8 (Join-Path $root '_strata\rationale\R1.md') @'
# R1

Run `context.ps1 -CheckAll` and read `_strata/state/index.md` before deciding.
'@
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "generation failed: $($result.Output)"
        $guide = [IO.File]::ReadAllText((Join-Path $root '_strata\project_guide.html'), [Text.Encoding]::UTF8)
        Assert-True ($guide -notmatch '@@STRATA') 'the Guide contains unrestored placeholder tokens'
        Assert-True ($guide -match '<code>context\.ps1 -CheckAll</code>') 'the code span was not rendered'
    }
}
finally {
    if (Test-Path -LiteralPath $TempRoot) {
        $resolved = [IO.Path]::GetFullPath($TempRoot)
        $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if (-not $resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing cleanup outside temp: $resolved" }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

Write-Output "RESULT passed=$Passed failed=$Failed"
if ($Failed -ne 0) { throw "Canonical context tests failed: $Failed" }
$global:LASTEXITCODE = 0
