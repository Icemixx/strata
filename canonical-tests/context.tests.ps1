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

function Invoke-GenerateGuideCapture([string]$Root) {
    $script = Join-Path $Root '_strata\universal\context.ps1'
    $captured = New-Object System.Collections.ArrayList
    $refused = $false
    $message = ''
    try {
        & { param([string]$ContextScript) . $ContextScript -GenerateGuide } $script 2>&1 |
            ForEach-Object { [void]$captured.Add($_.ToString()) }
    }
    catch { $refused = $true; $message = $_.Exception.Message }
    return [pscustomobject]@{
        Refused = $refused
        Message = $message
        Output = (($captured | ForEach-Object { $_ }) -join [Environment]::NewLine)
    }
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

$CompositionSource = @'
# Fixture Guide

# Operations
[[guide:section operations topic]]

## Work orders
[[guide:section operations.work-orders workflow]]
[[guide:watch app/*.py]]

A work order is created once and read many times. [code: app/service.py:create_work_order]

This section introduces the fixture and asserts nothing about the project.
[[guide:exempt framing]]

- The reason the fixture exists is recorded. [authority: _strata/rationale/R1.md]

| Field | Meaning |
| --- | --- |
| Status | The ticket state. |
| Owner | Who holds the order. |

[[guide:table shared]]
[code: db/schema.sql:work_order]

## Vehicles
[[guide:section operations.vehicles topic]]

Every vehicle is recorded against a work order. [authority: _strata/state/current.md#current-work]
'@

function Initialize-FixtureRepository([string]$Root) {
    # Watch expansion is the union of tracked and non-ignored untracked files.
    # Both halves are Git facts, so a composition fixture is a Git repository
    # rather than a filesystem fallback the kit would then have to ship.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & git -C $Root init --quiet 2>&1 | Out-Null }
    finally { $ErrorActionPreference = $previous }
}

function New-CompositionFixture([string]$Name, [string]$Markdown) {
    $root = New-Fixture $Name
    Write-Utf8 (Join-Path $root 'app\service.py') "def create_work_order(order):`n    return order`n"
    Write-Utf8 (Join-Path $root 'app\view.py') "def render_work_order(order):`n    return order`n"
    Write-Utf8 (Join-Path $root 'db\schema.sql') "create table work_order (id int);`n"
    Initialize-FixtureRepository $root
    $source = if ([string]::IsNullOrEmpty($Markdown)) { $CompositionSource } else { $Markdown }
    Write-Utf8 (Join-Path $root '_strata\project_guide.md') $source
    return $root
}

# A generation refusal surfaces as a terminating error here, not an exit code,
# because the harness runs with ErrorActionPreference Stop. Assert on the
# refusal, its reason, and that the previous Guide survived it.
function Assert-GuideRefused([string]$Root, [string]$Markdown, [string]$Expected, [string]$Why) {
    Write-Utf8 (Join-Path $Root '_strata\project_guide.md') $Markdown
    $refused = $false; $message = ''
    try { $null = Invoke-Context $Root @('-GenerateGuide') }
    catch { $refused = $true; $message = $_.Exception.Message }
    Assert-True $refused $Why
    Assert-True ($message -match $Expected) "expected '$Expected', got: $message"
}

function Get-GuideHtml([string]$Root) {
    return [IO.File]::ReadAllText((Join-Path $Root '_strata\project_guide.html'), [Text.Encoding]::UTF8)
}

function Set-GuideHtml([string]$Root, [string]$Html) {
    [IO.File]::WriteAllText((Join-Path $Root '_strata\project_guide.html'), $Html, $Utf8)
}

function Get-GuideSectionElement([string]$Html, [string]$Id) {
    $match = [regex]::Match($Html, ('(?s)<section class="guide-topic" data-guide-section-id="' + [regex]::Escape($Id) + '"[^>]*>.*?</section>'))
    Assert-True $match.Success "rendered section $Id is missing"
    return $match.Value
}

function Get-GuideManifest([string]$Html) {
    $encoded = [regex]::Match($Html, '(?s)<template id="strata-guide-manifest"[^>]*>(.*?)</template>').Groups[1].Value
    return ([Net.WebUtility]::HtmlDecode($encoded) | ConvertFrom-Json)
}

function New-ComposedGuide([string]$Name, [string]$Markdown) {
    $root = New-CompositionFixture $Name $Markdown
    $result = Invoke-Context $root @('-GenerateGuide')
    Assert-True ($result.ExitCode -eq 0) "composed generation failed: $($result.Output)"
    return [pscustomobject]@{ Root = $root; Output = $result.Output }
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

    Assert-Test 'debate uses provider sessions and supplies only the opening transport prompt' {
        $debate = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\debate.md'), [Text.Encoding]::UTF8)
        $router = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal_agent_instructions.md'), [Text.Encoding]::UTF8)
        Assert-True ($debate -match 'Head each round `## Round N — <product>`') 'round heading is not product-only'
        Assert-True ($debate -match 'participant that creates a debate returns one ready-to-paste opening prompt') 'creation-time transport prompt rule missing'
        Assert-True ([regex]::Matches($debate, 'ready-to-paste', 'IgnoreCase').Count -eq 1) 'debate does not define exactly one opening transport prompt'
        Assert-True ($debate -match 'After creation, the shared files and turn marker carry the handoff') 'post-creation simple handoff rule missing'
        Assert-True ($debate -match 'a simple\s+user instruction to proceed is sufficient') 'simple post-creation proceed rule missing'
        Assert-True ($debate -match 'Do not provide another transport prompt') 'post-creation prompt prohibition missing'
        Assert-True ($debate -match 'one `report-<product>\.md` and one `cross-<product>\.md` per participant') 'debate artifacts are not product-named'
        Assert-True ($debate -match 'DEBATE: converged — \[count\] settled — \[subject\]') 'converged stamp shape changed'
        Assert-True ($debate -match 'DEBATE: terminated — \[reason\] — \[count\] settled, \[count\] open — \[subject\]') 'terminated stamp shape changed'
        Assert-True ($debate -match 'DEBATE: void — \[reason\] — \[subject\]') 'void stamp shape changed'
        Assert-True ($router -match 'debate\.md` \| Reconcile independently-derived work with an agent from another provider') 'router does not describe provider-only debate'
    }

    Assert-Test 'spec building is one routed cold-start workflow' {
        $specPath = Join-Path $StagedStrata 'universal\spec-building.md'
        Assert-True (Test-Path -LiteralPath $specPath -PathType Leaf) 'shared specification procedure is missing'
        $spec = [IO.File]::ReadAllText($specPath, [Text.Encoding]::UTF8)
        $debate = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\debate.md'), [Text.Encoding]::UTF8)
        $router = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal_agent_instructions.md'), [Text.Encoding]::UTF8)
        Assert-True ($router -match 'spec-building\.md` \| Create, revise, review, confirm, or hand off a retained specification') 'specification procedure is not routed'
        Assert-True ($spec -match 'A specification is a cold-start implementation contract') 'cold-start contract is missing'
        Assert-True ($spec -match 'SPECIFICATION: draft') 'draft marker is missing'
        Assert-True ($spec -match 'SPECIFICATION: confirmed — implementation-ready') 'confirmed marker is missing'
        Assert-True ($spec -match 'no implementation-blocking decision remains') 'readiness gate is missing'
        Assert-True ($spec -match 'Provenance recovery for an inherited specification') 'inherited-spec provenance recovery is missing'
        Assert-True ($spec -match 'Do not begin with an arbitrary chat date window') 'provenance recovery is tied to a date window'
        Assert-True ($spec -match 'Do not elevate reversible internal engineering choices into user decisions') 'decision-ownership filter is missing'
        Assert-True ($router -match 'adding, changing, simplifying,\s+replacing, or removing an instruction') 'Strata recommendation signal does not cover additions and changes'
        Assert-True ($router -match 'report it promptly\s+as a separate Strata recommendation') 'reusable Strata recommendation signal is missing'
        Assert-True ($router -match 'accepted recommendation becomes separately authorized kit work') 'recommendation does not preserve authorization boundary'
        $active = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\active-agent.md'), [Text.Encoding]::UTF8)
        Assert-True ($active -match 'reusable Strata improvement that has not yet been reported') 'closing recommendation backstop is missing'
        Assert-True ($debate -match 'Follow `_strata/universal/spec-building\.md`') 'debate does not invoke the shared workflow'
        Assert-True ([regex]::Matches($debate, 'written to be implemented by someone', 'IgnoreCase').Count -eq 0) 'debate still owns a parallel specification workflow'
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
        @{ Name='external Guide shell resource'; Code='GUIDE_SHELL_EXTERNAL'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\universal\guide-shell.html') '<body ' '<img src="https://example.invalid/a.png"><body ' } },
        @{ Name='duplicate Guide manifest placeholder'; Code='GUIDE_SHELL_PLACEHOLDER'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\universal\guide-shell.html') '<!--STRATA_MANIFEST-->' '<!--STRATA_MANIFEST--><!--STRATA_MANIFEST-->' } }
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

        # Composition rendering, coverage and provenance have their own tests below.
        # What this test still owns is the authority-only Guide it just generated.
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

    Assert-Test 'composed Guide renders identified sections as flat siblings' {
        $composed = New-ComposedGuide 'composition-render' ''
        $html = Get-GuideHtml $composed.Root
        Assert-True ($html -match '<section class="guide-topic" data-guide-section-id="operations" data-guide-section-kind="topic">') 'group section boundary missing'
        Assert-True ($html -match '<section class="guide-topic" data-guide-section-id="operations\.work-orders" data-guide-section-kind="workflow">') 'workflow section boundary missing'
        Assert-True ($html -match '<section class="guide-topic" data-guide-section-id="operations\.vehicles" data-guide-section-kind="topic">') 'topic section boundary missing'
        $workOrders = Get-GuideSectionElement $html 'operations.work-orders'
        Assert-True ($workOrders -notmatch '<section class="guide-topic"[^>]*>.*<section class="guide-topic"') 'sections are nested rather than siblings'
        Assert-True ($html -notmatch '<details class="topic"') 'composition sections were folded into disclosures'
        Assert-True ($html -match 'id="guide-section-operations\.work-orders"[^>]*data-search-item') 'search hook was not re-attached to the section'
        Assert-True ($html -match 'id="guide-section-operations\.work-orders"[^>]*data-nav-target') 'navigation hook was not re-attached to the section'
        Assert-True ($html -match '#guide-section-operations">Operations</a><ul class="nav-topics"><li[^>]*><a href="#guide-section-operations\.work-orders">Work orders</a></li><li[^>]*><a href="#guide-section-operations\.vehicles">Vehicles</a></li></ul>') 'group did not nest its sections in navigation'
        Assert-True ($html -notmatch 'href="#guide-section-fixture-guide"') 'the document title was navigated as a section'
        Assert-True (-not ($html -match '\[\[guide:')) 'a raw directive reached the rendered page'
        Assert-True ($html -match '<template id="strata-guide-manifest" data-schema="strata-guide-manifest/v1">') 'the manifest template is missing'
        Assert-True ($html.IndexOf('<template id="strata-guide-manifest"') -lt $html.IndexOf('<script>')) 'the manifest is not immediately before the canonical script'
        Assert-GuideIntegrity $html
    }

    Assert-Test 'composed Guide renders visible exemption badges and table evidence' {
        $composed = New-ComposedGuide 'composition-badges' ''
        $html = Get-GuideHtml $composed.Root
        Assert-True ($html -match '<span class="guide-exempt guide-exempt-framing">Framing — not sourced</span>') 'framing badge missing'
        Assert-True ($html -notmatch '(?s)<details[^>]*>(?:(?!</details>).)*Framing — not sourced') 'the framing badge is hidden inside a disclosure'
        Assert-True ([regex]::Matches($html, '<div class="table-evidence">').Count -eq 1) 'the shared table evidence strip was not rendered once'
        Assert-True ($html -match '<span class="table-evidence-label">Table evidence</span>') 'the table evidence label is missing'
        $illustration = $CompositionSource.Replace('[[guide:exempt framing]]', '[[guide:exempt illustration]]')
        $second = New-ComposedGuide 'composition-illustration' $illustration
        $secondHtml = Get-GuideHtml $second.Root
        Assert-True ($secondHtml -match '<span class="guide-exempt guide-exempt-illustration">Illustration — hypothetical</span>') 'illustration badge missing'
    }

    Assert-Test 'coverage records are emitted per section in document order' {
        $composed = New-ComposedGuide 'composition-coverage' ''
        $lines = @($composed.Output -split "`r?`n" | Where-Object { $_ -match '^GUIDE_' })
        $coverage = @($lines | Where-Object { $_ -match '^GUIDE_COVERAGE' })
        Assert-True ($coverage.Count -eq 3) "expected three coverage records: $($composed.Output)"
        Assert-True ($coverage[0] -eq 'GUIDE_COVERAGE section=operations cited_blocks=0 framing_exemptions=0 illustration_exemptions=0 table_rows=0 inherited_rows=0') "first coverage record: $($coverage[0])"
        Assert-True ($coverage[1] -eq 'GUIDE_COVERAGE section=operations.work-orders cited_blocks=2 framing_exemptions=1 illustration_exemptions=0 table_rows=2 inherited_rows=2') "second coverage record: $($coverage[1])"
        Assert-True ($coverage[2] -eq 'GUIDE_COVERAGE section=operations.vehicles cited_blocks=1 framing_exemptions=0 illustration_exemptions=0 table_rows=0 inherited_rows=0') "third coverage record: $($coverage[2])"
        Assert-True ($lines[$lines.Count - 1] -match '^GUIDE_GENERATED digest=[0-9a-f]{64} ') 'coverage records do not precede GUIDE_GENERATED'
    }

    Assert-Test 'table evidence counts shared, augmented and overridden rows' {
        $markdown = @'
## Fields
[[guide:section reference.fields topic]]

| Field | Meaning |
| --- | --- |
| Status | Shared evidence only. |
| Owner | Augmented. [code: app/view.py:render_work_order] |
| Notes | Overridden. [[guide:row override]] [code: app/view.py:render_work_order] |

[[guide:table shared]]
[code: db/schema.sql:work_order]
'@
        $composed = New-ComposedGuide 'composition-tables' $markdown
        $coverage = @($composed.Output -split "`r?`n" | Where-Object { $_ -match '^GUIDE_COVERAGE' })
        Assert-True ($coverage.Count -eq 1) "expected one coverage record: $($composed.Output)"
        Assert-True ($coverage[0] -eq 'GUIDE_COVERAGE section=reference.fields cited_blocks=0 framing_exemptions=0 illustration_exemptions=0 table_rows=3 inherited_rows=2') "table coverage: $($coverage[0])"
        $html = Get-GuideHtml $composed.Root
        Assert-True ($html -notmatch 'guide:row override') 'the raw row override token reached the page'
        Assert-GuideIntegrity $html
    }

    Assert-Test 'watched red: composition grammar defects fail generation' {
        $root = New-CompositionFixture 'composition-grammar' ''
        $cases = @(
            @{ Markdown = "# Guide`n[[guide:section guide topic]]`n`n## Orphan`n`nUncited. [code: app/service.py:create_work_order]`n"; Expected = 'has no \[\[guide:section'; Why = 'a heading without identity must fail generation' },
            @{ Markdown = "# Guide`n`n## Orphan`n[[guide:section orphan topic]]`n`nCited. [code: app/service.py:create_work_order]`n"; Expected = 'may omit its identity only when the next heading is also level one'; Why = 'a bare document title followed by a level-two heading must name the constraint it broke, not blame the one heading allowed to have no identity' },
            @{ Markdown = "# Orphan`n[[guide:section Bad-Id topic]]`n`nCited. [code: app/service.py:create_work_order]`n"; Expected = 'invalid section id'; Why = 'an invalid section id must fail generation' },
            @{ Markdown = "# Orphan`n[[guide:section orphan mystery]]`n`nCited. [code: app/service.py:create_work_order]`n"; Expected = 'invalid section kind'; Why = 'an invalid section kind must fail generation' },
            @{ Markdown = "# One`n[[guide:section same topic]]`n`nCited. [code: app/service.py:create_work_order]`n`n# Two`n[[guide:section same topic]]`n`nCited. [code: app/service.py:create_work_order]`n"; Expected = 'duplicate section id'; Why = 'a duplicate section id must fail generation before rendering' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`n[[guide:unknown value]]`n`nCited. [code: app/service.py:create_work_order]`n"; Expected = 'unknown directive'; Why = 'an unknown directive must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`nCited. [code: app/service.py:create_work_order]`n`n[[guide:section two topic]]`n"; Expected = 'section identity line must follow'; Why = 'a misplaced identity directive must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`n[[guide:row override]]`n`nCited. [code: app/service.py:create_work_order]`n"; Expected = 'row override token is valid only'; Why = 'a row override outside a table must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`nCited. [code: app/service.py:create_work_order]`n`n[[guide:watch app/*.py]]`n"; Expected = 'must precede'; Why = 'a watch declaration after content must fail generation' }
        )
        foreach ($case in $cases) { Assert-GuideRefused $root $case.Markdown $case.Expected $case.Why }
    }

    Assert-Test 'watched red: coverage and exemption defects fail generation' {
        $root = New-CompositionFixture 'composition-coverage-red' ''
        $cases = @(
            @{ Markdown = "# One`n[[guide:section one topic]]`n`nThis prose asserts project behaviour and cites nothing.`n"; Expected = 'unmarked uncited prose block'; Why = 'unmarked uncited prose must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`nCited. [code: app/service.py:create_work_order]`n[[guide:exempt framing]]`n"; Expected = 'both a citation and an exemption'; Why = 'a citation plus an exemption must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`nUncited framing.`n[[guide:exempt framing]]`n[[guide:exempt illustration]]`n"; Expected = 'more than one exemption'; Why = 'two exemptions on one block must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`nUncited framing.`n[[guide:exempt guesswork]]`n"; Expected = 'unknown exemption'; Why = 'an unknown exemption class must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`n| A | B |`n| --- | --- |`n| One | Two. [code: app/service.py:create_work_order] |`n[[guide:exempt framing]]`n"; Expected = 'cannot exempt a table row'; Why = 'an exemption on a table row must fail generation' }
        )
        foreach ($case in $cases) { Assert-GuideRefused $root $case.Markdown $case.Expected $case.Why }
    }

    Assert-Test 'watched red: table evidence defects fail generation' {
        $root = New-CompositionFixture 'composition-table-red' ''
        $cases = @(
            @{ Markdown = "# One`n[[guide:section one topic]]`n`n| A | B |`n| --- | --- |`n| One | Overridden. [[guide:row override]] |`n`n[[guide:table shared]]`n[code: db/schema.sql:work_order]`n"; Expected = 'carries no row citation'; Why = 'an override without a row citation must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`n| A | B |`n| --- | --- |`n| One | Cited. [code: app/service.py:create_work_order] |`n| Two | Uncited. |`n"; Expected = 'has no evidence'; Why = 'a heterogeneous row without evidence must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`n| A | B |`n| --- | --- |`n| One | Shared. |`n`n[[guide:table shared]]`n[code: db/schema.sql:work_order]`n`n[[guide:table shared]]`n[code: db/schema.sql:work_order]`n"; Expected = 'more than one shared evidence declaration'; Why = 'two shared declarations on one table must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`n| A | B |`n| --- | --- |`n| One | Overridden. [[guide:row override]] [code: app/service.py:create_work_order] |`n"; Expected = 'no shared table evidence to override'; Why = 'an override with no shared set must fail generation' },
            @{ Markdown = "# One`n[[guide:section one topic]]`n`nCited. [code: app/service.py:create_work_order]`n`n[[guide:table shared]]`n[code: db/schema.sql:work_order]`n"; Expected = 'shared table declaration must follow a table'; Why = 'a shared declaration not after a table must fail generation' }
        )
        foreach ($case in $cases) { Assert-GuideRefused $root $case.Markdown $case.Expected $case.Why }
    }

    Assert-Test 'watched red: watch pattern grammar and zero expansion fail generation' {
        $root = New-CompositionFixture 'composition-watch-red' ''
        $prefix = "# One`n[[guide:section one workflow]]`n"
        $suffix = "`nCited. [code: app/service.py:create_work_order]`n"
        $patterns = @(
            @{ Pattern = '**'; Expected = 'narrower than the repository' },
            @{ Pattern = '/app/service.py'; Expected = 'absolute' },
            @{ Pattern = 'C:/app/service.py'; Expected = 'absolute' },
            @{ Pattern = 'app\service.py'; Expected = 'backslash' },
            @{ Pattern = 'app/../app/service.py'; Expected = 'relative segment' },
            @{ Pattern = 'app//service.py'; Expected = 'empty segment' },
            @{ Pattern = 'app/**/service.py'; Expected = 'complete final segment' },
            @{ Pattern = 'app/x**'; Expected = 'complete final segment' },
            @{ Pattern = 'ap*/service.py'; Expected = 'only in the final segment' },
            @{ Pattern = 'app/{service}.py'; Expected = 'unsupported wildcard' },
            @{ Pattern = 'app/[sv]*.py'; Expected = 'unsupported wildcard' },
            @{ Pattern = 'app/service?.py'; Expected = 'unsupported wildcard' }
        )
        foreach ($case in $patterns) {
            Assert-GuideRefused $root ($prefix + '[[guide:watch ' + $case.Pattern + ']]' + "`n" + $suffix) $case.Expected "watch pattern $($case.Pattern) must fail generation"
        }
        Assert-GuideRefused $root ($prefix + "[[guide:watch app/nothing/*.py]]`n" + $suffix) 'matches no readable file' 'a watch pattern matching nothing must fail generation'
    }

    Assert-Test 'a workflow section without a watch surface warns but generates' {
        $markdown = "# One`n[[guide:section one workflow]]`n`nCited. [code: app/service.py:create_work_order]`n"
        $composed = New-ComposedGuide 'composition-warning' $markdown
        Assert-True ($composed.Output -match 'GUIDE_WARNING section=one code=missing-watch-surface') "warning missing: $($composed.Output)"
        $lines = @($composed.Output -split "`r?`n" | Where-Object { $_ -match '^GUIDE_' })
        $warningIndex = [array]::IndexOf($lines, 'GUIDE_WARNING section=one code=missing-watch-surface')
        $coverageIndex = [array]::IndexOf($lines, 'GUIDE_COVERAGE section=one cited_blocks=1 framing_exemptions=0 illustration_exemptions=0 table_rows=0 inherited_rows=0')
        Assert-True ($warningIndex -ge 0 -and $coverageIndex -gt $warningIndex) "warnings must precede coverage records: $($composed.Output)"
        $topic = $markdown.Replace('one workflow', 'one topic')
        $quiet = New-ComposedGuide 'composition-warning-topic' $topic
        Assert-True ($quiet.Output -notmatch 'GUIDE_WARNING') 'a topic section without a watch surface must not warn'
    }

    Assert-Test 'composition guide status reports current and per-section staleness' {
        $composed = New-ComposedGuide 'composition-status' ''
        $status = Invoke-Context $composed.Root @('-GuideStatus')
        Assert-True ($status.ExitCode -eq 0) "status failed: $($status.Output)"
        Assert-True ($status.Output -match '^GUIDE_CURRENT sections=3 digest=[0-9a-f]{64} generated_from=\S+ commits_since=\S+ authority_commits_since=\S+ authority_worktree_dirty=(?:true|false)$') "composed current record: $($status.Output)"
        $before = Get-GuideHtml $composed.Root

        Write-Utf8 (Join-Path $composed.Root 'app\service.py') "def create_work_order(order):`n    return order.id`n"
        $status = Invoke-Context $composed.Root @('-GuideStatus')
        Assert-True ($status.Output -match '^GUIDE_STALE sections=3 changed_sections=1 changed_paths=1 generated_from=\S+') "cited-file stale record: $($status.Output)"
        Assert-True ($status.Output -match 'GUIDE_SECTION_STALE id=operations\.work-orders changed_paths_json=\["app/service\.py"\]') "changed path array: $($status.Output)"
        Assert-True ($status.Output -notmatch 'GUIDE_CHANGE') 'the composition path emitted an authority-only advisory'
        Assert-True ((Get-GuideHtml $composed.Root) -eq $before) 'GuideStatus modified the Guide'

        $source = Join-Path $composed.Root '_strata\project_guide.md'
        Write-Utf8 $source ([IO.File]::ReadAllText($source, [Text.Encoding]::UTF8).Replace('Every vehicle is recorded', 'Each vehicle is recorded'))
        $status = Invoke-Context $composed.Root @('-GuideStatus')
        Assert-True ($status.Output -match 'GUIDE_SECTION_STALE id=operations\.vehicles changed_paths_json=\["_strata/project_guide\.md#operations\.vehicles"\]') "composition-only change: $($status.Output)"
    }

    Assert-Test 'composition guide status reports watch-surface additions, deletions and renames' {
        $composed = New-ComposedGuide 'composition-watch-status' ''
        $added = Join-Path $composed.Root 'app\report.py'
        Write-Utf8 $added "def render_report(order):`n    return order`n"
        $status = Invoke-Context $composed.Root @('-GuideStatus')
        Assert-True ($status.Output -match 'GUIDE_SECTION_STALE id=operations\.work-orders changed_paths_json=\["app/report\.py"\]') "watch addition: $($status.Output)"
        Assert-True ($status.Output -match '^GUIDE_STALE sections=3 changed_sections=1 changed_paths=1 ') "watch addition summary: $($status.Output)"

        Remove-Item -LiteralPath $added -Force
        Remove-Item -LiteralPath (Join-Path $composed.Root 'app\view.py') -Force
        $status = Invoke-Context $composed.Root @('-GuideStatus')
        Assert-True ($status.Output -match 'GUIDE_SECTION_STALE id=operations\.work-orders changed_paths_json=\["app/view\.py"\]') "watch deletion: $($status.Output)"
        Assert-True ($status.Output -match '^GUIDE_STALE ') 'a deleted watch entry must be stale, not invalid'
        Assert-True ($status.Output -notmatch 'GUIDE_INVALID') 'a deleted watch entry must not invalidate the Guide'

        Write-Utf8 (Join-Path $composed.Root 'app\view.py') "def render_work_order(order):`n    return order`n"
        Move-Item -LiteralPath (Join-Path $composed.Root 'app\service.py') -Destination (Join-Path $composed.Root 'app\services.py')
        $status = Invoke-Context $composed.Root @('-GuideStatus')
        Assert-True ($status.Output -match 'changed_paths_json=\["app/service\.py","app/services\.py"\]') "watch rename: $($status.Output)"
    }

    Assert-Test 'watched red: manifest defects report the closed reason codes' {
        $composed = New-ComposedGuide 'composition-manifest-red' ''
        $original = Get-GuideHtml $composed.Root

        Set-GuideHtml $composed.Root ([regex]::Replace($original, '(?s)<template id="strata-guide-manifest".*?</template>', ''))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=missing-manifest$') 'missing manifest was not reported'

        Set-GuideHtml $composed.Root ([regex]::Replace($original, '(?s)(<template id="strata-guide-manifest" data-schema="strata-guide-manifest/v1">).*?(</template>)', '$1{&quot;schema$2'))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=corrupt-manifest$') 'corrupt manifest was not reported'

        Set-GuideHtml $composed.Root ($original.Replace('data-schema="strata-guide-manifest/v1"', 'data-schema="strata-guide-manifest/v2"'))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=unsupported-manifest-schema$') 'unsupported schema was not reported'

        Set-GuideHtml $composed.Root ($original.Replace('&quot;id&quot;:&quot;operations.vehicles&quot;', '&quot;id&quot;:&quot;operations&quot;'))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=duplicate-section-id$') 'a duplicate manifest section id was not reported'

        Set-GuideHtml $composed.Root ($original.Replace('&quot;path&quot;:&quot;app/service.py&quot;', '&quot;path&quot;:&quot;../app/service.py&quot;'))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=invalid-manifest-path$') 'an invalid manifest path was not reported'

        Set-GuideHtml $composed.Root ($original.Replace('A work order is created once', 'A work order is created twice'))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=rendered-digest-mismatch$') 'a rendered digest mismatch was not reported'

        Set-GuideHtml $composed.Root ($original.Replace('&quot;kind&quot;:&quot;code&quot;', '&quot;extra&quot;:&quot;x&quot;,&quot;kind&quot;:&quot;code&quot;'))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=corrupt-manifest$') 'an unknown nested field was not reported'

        Set-GuideHtml $composed.Root (([regex]'&quot;digest&quot;:&quot;[0-9a-f]{64}&quot;').Replace($original, '&quot;digest&quot;:&quot;abc&quot;', 1))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=corrupt-manifest$') 'a malformed nested digest was not reported'

        $zeroed = '&quot;path&quot;:&quot;app/view.py&quot;,&quot;digest&quot;:&quot;' + ('0' * 64) + '&quot;'
        Set-GuideHtml $composed.Root (([regex]'&quot;path&quot;:&quot;app/view\.py&quot;,&quot;digest&quot;:&quot;[0-9a-f]{64}&quot;').Replace($original, $zeroed, 1))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=corrupt-manifest$') 'a watch-surface digest mismatch was not reported'

        Set-GuideHtml $composed.Root ($original.Replace('</template>', '</template><template id="strata-guide-manifest" data-schema="strata-guide-manifest/v1">{}</template>'))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=corrupt-manifest$') 'a duplicate manifest template was not reported'

        Set-GuideHtml $composed.Root ([regex]::Replace($original, 'data-source-digest="[0-9a-f]{64}"', ('data-source-digest="' + ('a' * 64) + '"')))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=corrupt-manifest$') 'a shell and manifest digest disagreement was not reported'

        $vehicles = Get-GuideSectionElement $original 'operations.vehicles'
        Set-GuideHtml $composed.Root ($original.Replace($vehicles, ($vehicles + $vehicles)))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=rendered-digest-mismatch$') 'a duplicate section boundary was not reported'

        Set-GuideHtml $composed.Root $original
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_CURRENT ') 'the restored Guide is not current again'
    }

    Assert-Test 'unchanged sections carry forward verbatim' {
        $composed = New-ComposedGuide 'composition-carry-forward' ''
        $before = Get-GuideHtml $composed.Root
        $vehiclesBefore = Get-GuideSectionElement $before 'operations.vehicles'
        $workOrdersBefore = Get-GuideSectionElement $before 'operations.work-orders'
        $source = Join-Path $composed.Root '_strata\project_guide.md'
        Write-Utf8 $source ([IO.File]::ReadAllText($source, [Text.Encoding]::UTF8).Replace('A work order is created once and read many times.', 'A work order is created once and read repeatedly.'))
        $again = Invoke-Context $composed.Root @('-GenerateGuide')
        Assert-True ($again.ExitCode -eq 0) "regeneration failed: $($again.Output)"
        $after = Get-GuideHtml $composed.Root
        Assert-True ((Get-GuideSectionElement $after 'operations.vehicles') -ceq $vehiclesBefore) 'an unchanged section was not carried forward byte-identically'
        Assert-True ((Get-GuideSectionElement $after 'operations.work-orders') -cne $workOrdersBefore) 'the edited section was not recomposed'
        $digestBefore = [regex]::Match($before, '&quot;id&quot;:&quot;operations\.vehicles&quot;.*?&quot;rendered_digest&quot;:&quot;([0-9a-f]{64})&quot;').Groups[1].Value
        $digestAfter = [regex]::Match($after, '&quot;id&quot;:&quot;operations\.vehicles&quot;.*?&quot;rendered_digest&quot;:&quot;([0-9a-f]{64})&quot;').Groups[1].Value
        Assert-True ($digestBefore.Length -eq 64 -and $digestBefore -ceq $digestAfter) 'the carried-forward rendered digest changed'
    }

    Assert-Test 'the manifest and section digests are deterministic' {
        $first = New-ComposedGuide 'composition-determinism-a' ''
        $second = New-ComposedGuide 'composition-determinism-b' ''
        $firstHtml = Get-GuideHtml $first.Root
        $secondHtml = Get-GuideHtml $second.Root
        $firstDigest = [regex]::Match($firstHtml, 'data-source-digest="([0-9a-f]{64})"').Groups[1].Value
        $secondDigest = [regex]::Match($secondHtml, 'data-source-digest="([0-9a-f]{64})"').Groups[1].Value
        Assert-True ($firstDigest -ceq $secondDigest) 'two identical compositions produced different source digests'
        Assert-True ($first.Output -match ("GUIDE_GENERATED digest=" + $firstDigest + " ")) 'the emitted digest is not the section-derived digest'
        $manifestFirst = [regex]::Match($firstHtml, '(?s)<template id="strata-guide-manifest"[^>]*>(.*?)</template>').Groups[1].Value
        $manifestSecond = [regex]::Match($secondHtml, '(?s)<template id="strata-guide-manifest"[^>]*>(.*?)</template>').Groups[1].Value
        $stripFirst = [regex]::Replace($manifestFirst, '&quot;generated_at&quot;:&quot;[^&]*&quot;', '')
        $stripSecond = [regex]::Replace($manifestSecond, '&quot;generated_at&quot;:&quot;[^&]*&quot;', '')
        Assert-True ($stripFirst -ceq $stripSecond) 'the manifest is not byte-deterministic'
        Assert-True ($manifestFirst -notmatch '\s{2,}') 'the manifest contains insignificant whitespace'
        Assert-True ($manifestFirst.IndexOf('&quot;schema&quot;') -lt $manifestFirst.IndexOf('&quot;generated_at&quot;')) 'manifest property order is not invariant'
        Assert-True ($manifestFirst -notmatch '\\\\') 'the manifest contains platform-specific path separators'
    }

    Assert-Test 'failed composition generation preserves the existing Guide' {
        $root = New-CompositionFixture 'composition-atomic' ''
        $guide = Join-Path $root '_strata\project_guide.html'
        Write-Utf8 $guide 'SENTINEL'
        Assert-GuideRefused $root "# One`n[[guide:section one topic]]`n`nUncited prose.`n" 'unmarked uncited prose block' 'coverage failure must refuse generation'
        Assert-True ([IO.File]::ReadAllText($guide) -eq 'SENTINEL') 'a coverage failure replaced the existing Guide'
        Assert-GuideRefused $root "# One`n[[guide:section one topic]]`n`nInvented. [code: app/service.py:no_such_symbol]`n" 'locator not found' 'an invented locator must refuse generation'
        Assert-True ([IO.File]::ReadAllText($guide) -eq 'SENTINEL') 'a citation failure replaced the existing Guide'
        Assert-GuideRefused $root "# One`n[[guide:section one workflow]]`n[[guide:watch app/nothing/*.py]]`n`nCited. [code: app/service.py:create_work_order]`n" 'matches no readable file' 'a zero-expansion watch surface must refuse generation'
        Assert-True ([IO.File]::ReadAllText($guide) -eq 'SENTINEL') 'a watch failure replaced the existing Guide'
    }

    Assert-Test 'the authority-only status fields are unchanged' {
        $root = New-Fixture 'authority-status-fields'
        $status = Invoke-Context $root @('-GuideStatus')
        Assert-True ($status.Output -match '^GUIDE_MISSING current_digest=[0-9a-f]{64}$') "authority missing record: $($status.Output)"
        Assert-True ((Invoke-Context $root @('-GenerateGuide')).ExitCode -eq 0) 'authority-only generation failed'
        $status = Invoke-Context $root @('-GuideStatus')
        Assert-True ($status.Output -match '^GUIDE_CURRENT digest=[0-9a-f]{64} generated_from=\S+ commits_since=\S+ authority_commits_since=\S+ authority_worktree_dirty=(?:true|false)$') "authority current record: $($status.Output)"
        Assert-True ($status.Output -notmatch 'sections=') 'the authority-only path emitted a composition field'
        $record = Join-Path $root '_strata\rationale\R1.md'
        Write-Utf8 $record ([IO.File]::ReadAllText($record, [Text.Encoding]::UTF8) + "`nChanged after generation.`n")
        $status = Invoke-Context $root @('-GuideStatus')
        Assert-True ($status.Output -match '^GUIDE_STALE generated_digest=[0-9a-f]{64} current_digest=[0-9a-f]{64} generated_from=\S+ commits_since=\S+ authority_commits_since=\S+ authority_worktree_dirty=(?:true|false)$') "authority stale record: $($status.Output)"
        Assert-True ($status.Output -notmatch 'GUIDE_SECTION_STALE') 'the authority-only path emitted a section record'
        Assert-True ($status.Output -notmatch 'changed_sections=') 'the authority-only path emitted a composition field'
        $guide = Join-Path $root '_strata\project_guide.html'
        $html = [IO.File]::ReadAllText($guide, [Text.Encoding]::UTF8)
        Assert-True ($html -notmatch '<template id="strata-guide-manifest"') 'an authority-only Guide embedded a composition manifest'
        Set-GuideHtml $root ([regex]::Replace($html, '\sdata-source-digest="[0-9a-f]{64}"', ''))
        $status = Invoke-Context $root @('-GuideStatus')
        Assert-True ($status.Output -match '^GUIDE_INVALID reason=missing-digest current_digest=[0-9a-f]{64}$') "authority invalid record: $($status.Output)"
    }

    Assert-Test 'the first colon separates a code path from its locator' {
        $root = New-CompositionFixture 'composition-first-colon' ''
        Write-Utf8 (Join-Path $root 'db\schema.sql') "create table work_order (id int);`n-- schema:object`n"
        Write-Utf8 (Join-Path $root 'x') "stable_symbol`n"
        $markdown = "# One`n[[guide:section one topic]]`n`nA compound locator keeps its colons. [code: db/schema.sql:schema:object]`n`nA one-character path is a path, not a drive letter. [code: x:stable_symbol]`n"
        Write-Utf8 (Join-Path $root '_strata\project_guide.md') $markdown
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "first-colon resolution failed: $($result.Output)"
        $html = Get-GuideHtml $root
        Assert-True ($html -match 'cite-code" title="code">db/schema\.sql:schema:object<') 'the compound locator was not rendered'
        Assert-True ($html -match 'cite-code" title="code">x:stable_symbol<') 'the one-character path was not rendered'
        Assert-GuideRefused $root "# One`n[[guide:section one topic]]`n`nInvented. [code: x:no_such_symbol]`n" 'locator not found' 'a one-character path must still resolve its locator'
    }

    Assert-Test 'a composition Contents heading is a section, not a stripped index' {
        $markdown = "# Guide`n[[guide:section guide topic]]`n`n## Contents`n[[guide:section guide.contents topic]]`n`n- Work orders are explained first. [code: app/service.py:create_work_order]`n`n## Work orders`n[[guide:section guide.work-orders topic]]`n`nA work order is created once. [code: app/service.py:create_work_order]`n"
        $composed = New-ComposedGuide 'composition-contents' $markdown
        $html = Get-GuideHtml $composed.Root
        Assert-True ($html -match '<section class="guide-topic" data-guide-section-id="guide\.contents"') 'the Contents section was stripped from the composition'
        Assert-True ($html -match 'Work orders are explained first\.') 'the Contents section body was stripped'
        $coverage = @($composed.Output -split "`r?`n" | Where-Object { $_ -match '^GUIDE_COVERAGE' })
        Assert-True ($coverage.Count -eq 3) "every composition heading is a section: $($composed.Output)"
        Assert-GuideIntegrity $html
    }

    Assert-Test 'an incomplete composition draft does not fail ordinary checks' {
        $root = New-CompositionFixture 'composition-draft' "# Draft`n`nProse with no identity and no citation.`n"
        $result = Invoke-Context $root @('-CheckAll')
        Assert-True ($result.ExitCode -eq 0) "an incomplete draft failed CheckAll: $($result.Output)"
        Assert-True ($result.Output -match 'CONTEXT_PASS all') "an incomplete draft failed CheckAll: $($result.Output)"
        $result = Invoke-Context $root @('-Check','-Paths','_strata/state/current.md')
        Assert-True ($result.ExitCode -eq 0) "an incomplete draft failed Check: $($result.Output)"
        $status = Invoke-Context $root @('-GuideStatus')
        Assert-True ($status.ExitCode -eq 0) "an incomplete draft failed GuideStatus: $($status.Output)"
        Assert-True ($status.Output -match '^GUIDE_MISSING current_digest=[0-9a-f]{64}$') "draft status: $($status.Output)"
    }

    Assert-Test 'a Git warning on stderr does not empty a watch surface' {
        # Git writes advisory warnings to stderr and still exits 0. Under
        # ErrorActionPreference Stop that became a terminating error inside the
        # read seam, every watch surface expanded to nothing, and eight tests
        # failed with "matches no readable file" on one harness and not another.
        $realGit = @(Get-Command git -CommandType Application)[0].Source
        $root = New-CompositionFixture 'composition-git-warning' ''
        $shim = Join-Path $root '.shim'
        New-Item -ItemType Directory -Path $shim -Force | Out-Null
        $shimText = "@echo off`r`n>&2 echo warning: unable to access 'C:/Users/test/.config/git/ignore': Permission denied`r`n`"$realGit`" %*`r`n"
        [IO.File]::WriteAllText((Join-Path $shim 'git.cmd'), $shimText, $Utf8)
        $previousPath = $env:PATH
        $env:PATH = $shim + ';' + $previousPath
        try {
            # Probe the shim with the preference relaxed: what is under test is
            # the production seam, which must survive the harness's Stop.
            $probePreference = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try { $warned = @(& git -C $root rev-parse --is-inside-work-tree 2>&1) }
            finally { $ErrorActionPreference = $probePreference }
            Assert-True (@($warned | Where-Object { $_.ToString() -match 'Permission denied' }).Count -eq 1) 'the shim did not reproduce a stderr warning'
            Assert-True ($ErrorActionPreference -eq 'Stop') 'the seam is not being exercised under ErrorActionPreference Stop'
            $result = Invoke-Context $root @('-GenerateGuide')
            Assert-True ($result.ExitCode -eq 0) "generation failed while Git warned on stderr: $($result.Output)"
            $manifest = Get-GuideManifest (Get-GuideHtml $root)
            $surfaces = @($manifest.sections | Where-Object { $_.id -eq 'operations.work-orders' })[0].watch_surfaces
            Assert-True (@($surfaces[0].entries).Count -eq 2) 'the watch surface expanded to nothing while Git warned on stderr'
        }
        finally { $env:PATH = $previousPath }
    }

    Assert-Test 'watched red: corrupted previous HTML cannot be carried forward' {
        $composed = New-ComposedGuide 'composition-launder' ''
        $original = Get-GuideHtml $composed.Root
        Set-GuideHtml $composed.Root ($original.Replace('Every vehicle is recorded', 'TAMPERED evidence is recorded'))
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_INVALID reason=rendered-digest-mismatch$') 'the tampered page was not reported invalid'
        $again = Invoke-Context $composed.Root @('-GenerateGuide')
        Assert-True ($again.ExitCode -eq 0) "regeneration failed: $($again.Output)"
        $after = Get-GuideHtml $composed.Root
        Assert-True ($after -notmatch 'TAMPERED') 'hand-edited bytes were laundered into a fresh manifest'
        Assert-True ($after -match 'Every vehicle is recorded against a work order') 'the section was not recomposed from its source'
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_CURRENT ') 'the regenerated Guide is not current'
    }

    Assert-Test 'watched red: a malformed candidate preserves the previous Guide' {
        $root = New-CompositionFixture 'composition-candidate' ''
        $guide = Join-Path $root '_strata\project_guide.html'
        Write-Utf8 $guide 'SENTINEL'
        # A tampered shell injects a section boundary the manifest cannot account
        # for. The candidate must be refused before it replaces anything.
        Replace-Utf8 (Join-Path $root '_strata\universal\guide-shell.html') '<!--STRATA_MANIFEST-->' '<section class="guide-topic" data-guide-section-id="ghost" data-guide-section-kind="topic"><div>ghost</div></section><!--STRATA_MANIFEST-->'
        $result = Invoke-GenerateGuideCapture $root
        Assert-True $result.Refused "a malformed candidate was not refused: $($result.Output)"
        Assert-True ($result.Message -match 'provenance is invalid: rendered-digest-mismatch') "unexpected refusal: $($result.Message)"
        Assert-True ([IO.File]::ReadAllText($guide) -eq 'SENTINEL') 'a malformed candidate replaced the existing Guide'
        Assert-True ($result.Output -notmatch 'GUIDE_COVERAGE') "a refused candidate emitted coverage records: $($result.Output)"
        Assert-True ($result.Output -notmatch 'GUIDE_WARNING') "a refused candidate emitted warnings: $($result.Output)"
        Assert-True ($result.Output -notmatch 'GUIDE_GENERATED') 'a refused candidate reported a generated Guide'
    }

    Assert-Test 'overlapping watch patterns store each expanded path once' {
        $markdown = "# One`n[[guide:section one workflow]]`n[[guide:watch app/*.py]]`n[[guide:watch app/**]]`n`nCited. [code: app/service.py:create_work_order]`n"
        $composed = New-ComposedGuide 'composition-watch-overlap' $markdown
        $manifest = Get-GuideManifest (Get-GuideHtml $composed.Root)
        $section = @($manifest.sections)[0]
        Assert-True (@($section.watch_surfaces).Count -eq 2) 'both declarations were not stored'
        Assert-True ($section.watch_surfaces[0].pattern -ceq 'app/*.py') 'declaration order was not preserved'
        $paths = @()
        foreach ($surface in @($section.watch_surfaces)) { foreach ($entry in @($surface.entries)) { $paths += $entry.path } }
        Assert-True (@($paths).Count -eq (@($paths | Sort-Object -Unique)).Count) 'an overlapping path was stored twice'
        Assert-True (@($section.watch_surfaces[0].entries).Count -eq 2) 'the first declaration does not own the overlap'
        Assert-True (@($section.watch_surfaces[1].entries).Count -eq 0) 'a later declaration re-stored an owned path'
        Assert-True ((Invoke-Context $composed.Root @('-GuideStatus')).Output -match '^GUIDE_CURRENT ') 'an overlapping declaration did not validate'
    }

    Assert-Test 'a no-change regeneration carries every section and still validates references' {
        $composed = New-ComposedGuide 'composition-revalidate' ''
        $before = Get-GuideHtml $composed.Root
        $again = Invoke-Context $composed.Root @('-GenerateGuide')
        Assert-True ($again.ExitCode -eq 0) "no-change regeneration failed: $($again.Output)"
        $after = Get-GuideHtml $composed.Root
        foreach ($id in @('operations','operations.work-orders','operations.vehicles')) {
            Assert-True ((Get-GuideSectionElement $after $id) -ceq (Get-GuideSectionElement $before $id)) "section $id was not carried forward"
        }
        # References are revalidated for every section on every generation, so a
        # reference that stops resolving refuses the whole run even when other
        # sections are eligible to carry forward.
        Remove-Item -LiteralPath (Join-Path $composed.Root 'app\service.py') -Force
        $refused = $false; $message = ''
        try { $null = Invoke-Context $composed.Root @('-GenerateGuide') }
        catch { $refused = $true; $message = $_.Exception.Message }
        Assert-True $refused 'an unresolvable reference did not refuse generation'
        Assert-True ($message -match 'cited file not found') "unexpected refusal: $message"
        Assert-True ((Get-GuideHtml $composed.Root) -ceq $after) 'a refused generation replaced the Guide'
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

    Assert-Test 'a url( in authority prose is not a CSS resource' {
        $root = New-Fixture 'prose-url'
        Write-Utf8 (Join-Path $root '_strata\build-log\2026-07-23-codex-probe.md') @'
# 2026-07-23 - Codex nested-delegation probe

- Verbatim result: `ERROR: stream disconnected before completion: error sending request for url (https://api.openai.com/v1/responses)`; exit code `1`.
'@
        Replace-Utf8 (Join-Path $root '_strata\build-log\index.md') '## Contents' "## Contents`n`n- [Codex nested-delegation probe](2026-07-23-codex-probe.md) - The nested probe's verbatim failure."
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "a literal url( inside a code span blocked generation: $($result.Output)"
        $guide = [IO.File]::ReadAllText((Join-Path $root '_strata\project_guide.html'), [Text.Encoding]::UTF8)
        Assert-True ($guide -match 'api\.openai\.com') 'the verbatim error was not carried into the Guide'
    }

    Assert-Test 'watched red: a CSS url() in the shell still fails generation' {
        $root = New-Fixture 'shell-url'
        Replace-Utf8 (Join-Path $root '_strata\universal\guide-shell.html') '</style>' "  body { background-image: url(evil.png); }`n</style>"
        $result = Invoke-GenerateGuideCapture $root
        Assert-True ($result.ExitCode -ne 0) 'a CSS url() in a style block was allowed through'
        Assert-True ($result.Output -match 'CSS url\(\) resource') "the failure did not name the CSS url() guard: $($result.Output)"
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
