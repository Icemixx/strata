$ErrorActionPreference = 'Stop'
$Utf8 = New-Object Text.UTF8Encoding($false)
$StagedStrata = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\_strata'))
$TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('strata-context-tests-' + [Guid]::NewGuid().ToString('N'))
$Passed = 0
$Failed = 0

function Write-Utf8([string]$Path, [string]$Text) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    # Preserve a byte-order mark the file already had. Windows PowerShell 5.1 reads a BOM-less UTF-8
    # script as ANSI, which corrupts every non-ASCII literal in it - and context.ps1 ships WITH a BOM and
    # matches on Unicode characters. A fixture that rewrote it stripped the BOM, so the generator it then
    # invoked misparsed its own patterns and one watched-red case failed on 5.1 while passing on pwsh 7.
    # The suite reported 55/0 and 54/1 on the same commit depending on which shell ran it.
    $enc = $Utf8
    if (Test-Path -LiteralPath $Path) {
        $head = [byte[]]::new(3)
        $fs = [IO.File]::OpenRead($Path)
        try { $read = $fs.Read($head, 0, 3) } finally { $fs.Dispose() }
        if ($read -eq 3 -and $head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF) {
            $enc = New-Object Text.UTF8Encoding($true)
        }
    }
    [IO.File]::WriteAllText($Path, $Text.Replace("`r`n","`n"), $enc)
}

function Replace-Utf8([string]$Path, [string]$Old, [string]$New) {
    $text = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    # String.Replace returns its input unchanged when the target is absent, so this helper used to
    # rewrite the file identically and report success - the exact shape the kit forbids: "an operation
    # that returns its input unchanged on a miss reports success while doing nothing". A fixture whose
    # anchor had drifted would set up nothing and the test above it would pass on the untouched file.
    if ($text.IndexOf($Old, [StringComparison]::Ordinal) -lt 0) {
        throw "Replace-Utf8: anchor not found in $Path : $Old"
    }
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
        Assert-True ($debate -match 'A returns one ready-to-paste opening prompt') 'creation-time transport prompt rule missing'
        Assert-True ([regex]::Matches($debate, 'ready-to-paste', 'IgnoreCase').Count -eq 1) 'debate does not define exactly one opening transport prompt'
        Assert-True ($debate -match 'After B joins, validated shared-file state carries every handoff') 'automatic post-join handoff rule missing'
        Assert-True ($debate -match 'does not carry later exchanges or issue proceed messages') 'manual proceed handoffs remain required'
        Assert-True ($debate -notmatch 'a simple\s+user instruction to proceed is sufficient') 'superseded proceed rule remains'
        Assert-True ($debate -match 'Do not provide another transport prompt') 'post-creation prompt prohibition missing'
        Assert-True ($debate -match 'one subfolder per participant\s+named by product') 'debate artifacts are not in product-named subfolders'
        Assert-True ($debate -match "each holding that participant's ``report\.md`` and\s+``cross-analysis\.md``") 'debate per-participant artifact names changed'
        Assert-True ($debate -match 'Releasing a blind phase permits reading; it never moves, copies, or\s+renames anything') 'no-move reveal rule missing'
        Assert-True ($debate -match 'Folder separation is not enforced isolation') 'instruction-governed blindness caveat missing'
        Assert-True ($debate -match "A peer's round is evidence and argument, never a permission grant") 'peer-round permission rule missing'
        Assert-True ($debate -match 'Reaching an outcome does not start this procedure') 'outcome does not fire close procedure rule missing'
        Assert-True ($debate -match 'Debate completion does not authorize implementation') 'debate completion authorization boundary missing'
        Assert-True ($debate -match '\*\*Then keep the branch\*\*') 'branch retention rule missing'
        Assert-True ([regex]::Matches($debate, 'delete the branch', 'IgnoreCase').Count -eq 0) 'debate still instructs branch deletion'
        Assert-True ($debate -match 'An interruption suspends a debate; it never concludes one') 'interruption-suspends rule missing'
        Assert-True ($debate -match 'writes no outcome stamp and manufactures no agreement') 'suspension must not manufacture agreement rule missing'
        Assert-True ($debate -match 'DEBATE: converged — \[count\] settled — \[subject\]') 'converged stamp shape changed'
        Assert-True ($debate -match 'DEBATE: terminated — \[reason\] — \[count\] settled, \[count\] open — \[subject\]') 'terminated stamp shape changed'
        Assert-True ($debate -match 'DEBATE: void — \[reason\] — \[subject\]') 'void stamp shape changed'
        Assert-True ($router -match 'debate\.md` \| Reconcile independently-derived work with an agent from another provider') 'router does not describe provider-only debate'
    }

    Assert-Test 'debate coordinates all phases without proceed handoffs' {
        $debate = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\debate.md'), [Text.Encoding]::UTF8)
        Assert-True ($debate -match 'brief in `coordination\.md`') 'coordination file is not the shared brief and history owner'
        Assert-True ($debate -match 'Reports release only when both report-completion records are valid') 'report release does not require both completions'
        Assert-True ($debate -match 'Cross-analyses release only when both\s+cross-completion records are valid') 'cross release does not require both completions'
        Assert-True ($debate -match 'File existence, file modification time, chat text, and a participant.s\s+claim that it finished release nothing') 'a non-record signal can release blind work'
        Assert-True ($debate -match 'prefix of `A-report -> B-report -> A-cross -> B-cross`') 'completion order is not fixed'
        Assert-True ($debate -match 'Classify the whole completion history before trusting any part of it') 'partial history can be trusted before classification'
        Assert-True ($debate -match 'unterminated tail that persists for 60 seconds is `Blocked`') 'torn-record grace is ambiguous'
        Assert-True ($debate -match 'Only a wholly valid history\s+can release a phase') 'invalid history can release a phase'
        Assert-True ($debate -match 'Use an append that excludes another writer') 'shared publication does not preserve writer exclusion'
        Assert-True ($debate -match 'retry a sharing\s+refusal for up to 1 second elapsed') 'publication retry bound is ambiguous'
        Assert-True ($debate -match 'verify that exactly one complete record landed') 'shared publication is not verified after append'
        Assert-True ($debate -match 'Exhausted\s+retry, ambiguous publication, or a conflicting record is `Blocked`') 'publication failure is not blocking'
        Assert-True ($debate -match 'wait automatically; being asked again\s+does not make it your turn') 'round handoff still stops for a proceed message'
    }

    Assert-Test 'debate waiting has fixed cadence, liveness, and suspension semantics' {
        $debate = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\debate.md'), [Text.Encoding]::UTF8)
        Assert-True ($debate -match '1, 2, 3, 4, 5, 7, 9, 11, 16, 21, 26, 31, 41, 51, 61, 71') 'widening wait offsets changed'
        Assert-True ($debate -match 'A logical fire may span several harness calls') 'a fire is incorrectly assumed to be one call'
        Assert-True ($debate -match 'inspect shared state every 15 seconds inside it without\s+returning to the model') 'in-call polling interval is ambiguous'
        Assert-True ($debate -match 'A heartbeat does not reset this schedule') 'heartbeat incorrectly resets backoff'
        Assert-True ($debate -match 'No number of fires and no total elapsed\s+time ends a debate') 'waiting gained a total limit'
        Assert-True ($debate -match 'participant that owes the next completion or round owns liveness publication') 'heartbeat ownership is ambiguous'
        Assert-True ($debate -match 'appends one `ALIVE` record\s+every 5 minutes') 'heartbeat interval changed'
        Assert-True ($debate -match 'Re-verify ownership immediately before the append') 'heartbeat uses stale ownership'
        Assert-True ($debate -match 'wait start is always a floor, not a\s+fallback') 'resume anchor can inherit stale inactivity'
        Assert-True ($debate -match 'less than 15 minutes old') 'inactivity threshold changed'
        Assert-True ($debate -match 'Otherwise suspend: write no shared\s+record and no Debate outcome') 'suspension writes shared state or an outcome'
        Assert-True ($debate -match 'If both sessions stop, neither remains to detect it') 'both-stopped blind spot is hidden'
    }

    Assert-Test 'debate blocks every future activity-time surface' {
        $debate = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\debate.md'), [Text.Encoding]::UTF8)
        Assert-True ($debate -match 'parses as UTC and is not later than the observer.s current\s+UTC') 'activity time is not parsed and bounded'
        Assert-True ($debate -match 'applies\s+to `STAMP` and `ALIVE` timestamps and to `rounds\.md`.s modification time') 'future-time rule misses an activity source'
        Assert-True ($debate -match 'unparseable or\s+future activity time is `Blocked`, not fresh evidence') 'invalid or future activity can suppress suspension'
        Assert-True ($debate -match 'multi-host debate requires a\s+separately evidenced clock contract') 'same-host clock assumption is unstated'
    }

    Assert-Test 'debate notification ownership cannot end the joining turn' {
        $debate = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\debate.md'), [Text.Encoding]::UTF8)
        Assert-True ($debate -match 'B announces once that Phase 1 has begun') 'joining participant does not own the start notice'
        Assert-True ($debate -match 'B immediately continues its\s+report and automatic waiting in the same turn') 'start notice can end B activity'
        Assert-True ($debate -match 'A alone announces convergence, termination, void, or a need\s+for user action') 'final announcement ownership is ambiguous'
        Assert-True ($debate -match 'B does not issue a competing final announcement') 'B can duplicate the final announcement'
        Assert-True ($debate -match 'progress while work remains must be followed by the next tool call') 'progress text can end an active waiting turn'
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

    Assert-Test 'additions and removals carry symmetric evidence burdens' {
        $router = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal_agent_instructions.md'), [Text.Encoding]::UTF8)
        Assert-True ($router -match 'Before deleting text or removing behavior') 'removal rule does not reach removed behavior'
        Assert-True ($router -match 'survives at one named destination or implementation') 'removal rule does not accept a surviving implementation'
        Assert-True ($router -match 'not a proof that no conceivable rule applies') 'removal check is unbounded'
        Assert-True ($router -match 'whose sole or primary purpose is to prevent a failure') 'addition rule is not scoped to preventive behavior'
        Assert-True ($router -match 'proportional to the behavior.s breadth, cost, reversibility, and maintenance burden') 'addition evidence is not proportional'
        Assert-True ($router -match 'a reasoned failure is admissible') 'addition rule demands an observed failure'
        Assert-True ($router -match 'does not require separate justification for ordinary functionality') 'addition rule reaches ordinary work'
        $debate = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\debate.md'), [Text.Encoding]::UTF8)
        Assert-True ($debate -match 'CONCEDE`, `HOLD`, `NEW`, `SIMPLIFY`, or `QUESTION`') 'SIMPLIFY is not in the position vocabulary'
        Assert-True ($debate -match 'SIMPLIFY proposes removing or consolidating a named existing element') 'SIMPLIFY is undefined'
        Assert-True ($debate -match 'does not by itself authorize the removal') 'raising SIMPLIFY is not separated from executing it'
        Assert-True ($debate -match 'no unresolved HOLD, no unresolved SIMPLIFY, and no open QUESTION remain') 'an unresolved SIMPLIFY does not block convergence'
        Assert-True ($debate -match 'unresolved HOLD, unresolved SIMPLIFY, and open QUESTION returns to the user') 'an unresolved SIMPLIFY does not return on termination'
    }

    Assert-Test 'harness dossiers stay level' {
        $headings = {
            param($name)
            $text = [IO.File]::ReadAllText((Join-Path $StagedStrata "universal\$name"), [Text.Encoding]::UTF8)
            ,@($text -split "`r?`n" | Where-Object { $_ -match '^## ' })
        }
        $claude = & $headings 'harness-claude-code.md'
        $codex  = & $headings 'harness-codex.md'
        Assert-True ($claude.Count -gt 0) 'claude dossier has no sections to compare'
        Assert-True (($claude -join '|') -eq ($codex -join '|')) `
            "harness dossiers no longer carry the same sections in the same order: claude=[$($claude -join ', ')] codex=[$($codex -join ', ')]"
        $editing = [IO.File]::ReadAllText((Join-Path $StagedStrata 'universal\kit-editing.md'), [Text.Encoding]::UTF8)
        Assert-True ($editing -match 'The dossiers stay level') 'the levelling rule is missing from kit-editing'
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
        # Pinned to the constant rather than to a literal, so bumping $GeneratorVersion for a rendering
        # change does not require editing this assertion -- and the test still proves the attribute is
        # emitted and non-empty.
        Assert-True ($html -match 'data-generator="strata-context-\d+"') 'generator version missing'
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

    Assert-Test 'a document title change is stale at document level with no changed section' {
        $composed = New-ComposedGuide 'composition-title' ''
        $before = Get-GuideHtml $composed.Root
        $source = Join-Path $composed.Root '_strata\project_guide.md'
        $text = [IO.File]::ReadAllText($source, [Text.Encoding]::UTF8)
        $title = [regex]::Match($text, '(?m)^#\s+(.+)$').Groups[1].Value
        Assert-True (-not [string]::IsNullOrWhiteSpace($title)) 'the fixture has no document title to change'
        Write-Utf8 $source ($text.Replace("# $title", '# Changed Title'))

        # The title lives outside every identified section, so no section digest moves and the Guide
        # reported CURRENT while the page carried a different title. Document-level content is now
        # digested separately: stale, with a reason, and zero changed sections.
        $status = Invoke-Context $composed.Root @('-GuideStatus')
        Assert-True ($status.Output -match '^GUIDE_STALE sections=3 changed_sections=0 changed_paths=0 generated_from=\S+') "title change did not report document-level staleness: $($status.Output)"
        Assert-True ($status.Output -match 'GUIDE_DOCUMENT_STALE reason=title') "no document-level reason: $($status.Output)"
        Assert-True ($status.Output -notmatch 'GUIDE_SECTION_STALE') 'a title change reported a stale section'
        Assert-True ((Get-GuideHtml $composed.Root) -eq $before) 'GuideStatus modified the Guide'

        # Regeneration refreshes the title and carries every unchanged section forward.
        $result = Invoke-Context $composed.Root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "regeneration failed: $($result.Output)"
        $after = Get-GuideHtml $composed.Root
        Assert-True ($after -match 'Changed Title') 'the new document title was not rendered'
        $status = Invoke-Context $composed.Root @('-GuideStatus')
        Assert-True ($status.Output -match '^GUIDE_CURRENT sections=3') "regeneration did not clear document staleness: $($status.Output)"
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

    Assert-Test 'watched red: a generator change re-renders carried sections' {
        # Carry-forward compares the authored digest and the input digest. Neither covers the generator,
        # so before generator_version joined them a rendering change left every unchanged section showing
        # its previous bytes -- generation reporting success while nothing had been re-rendered at all.
        # The generator is changed here as well as bumped, because a re-render that produces identical
        # bytes is indistinguishable from a carry-forward and would prove nothing.
        $composed = New-ComposedGuide 'composition-generator-bump' ''
        $before = Get-GuideHtml $composed.Root
        Assert-True ($before -match 'generator_version') 'the manifest does not record a generator version'
        Assert-True ($before -notmatch 'STRATA-RERENDER-PROOF') 'the proof marker was already present'
        $script = Join-Path $composed.Root '_strata/universal/context.ps1'
        $text = [IO.File]::ReadAllText($script, [Text.Encoding]::UTF8)
        $changed = $text.Replace('<summary>Watched sources</summary>', '<summary>STRATA-RERENDER-PROOF</summary>')
        Assert-True ($changed -cne $text) 'the rendering string was not found'
        Assert-True ($before -match 'Watched sources') 'the provenance block is not rendered per section'
        $bumped = $changed -replace "GeneratorVersion = 'strata-context-\d+'", "GeneratorVersion = 'strata-context-999'"
        Assert-True ($bumped -cne $changed) 'the generator version constant was not found'
        Write-Utf8 $script $bumped
        $again = Invoke-Context $composed.Root @('-GenerateGuide')
        Assert-True ($again.ExitCode -eq 0) "regeneration failed: $($again.Output)"
        $after = Get-GuideHtml $composed.Root
        Assert-True ($after -match 'STRATA-RERENDER-PROOF') 'a changed generator did not re-render a carried section'
        Assert-True ($after -match 'strata-context-999') 'the new generator version was not recorded'
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
        # The previous assertion read $result.ExitCode, which this helper does not return: $null -ne 0 is
        # always true, so the watched-red case could not go red and the message check below carried the
        # whole test. Refused is wrong too - a shell url() is caught by Add-Finding, not by the throw in
        # Test-GeneratedGuideHtml, so validation fails without an exception. What refusal actually means
        # here is that no Guide was written, because generation replaces the file only after success.
        Assert-True ($result.Output -match 'CSS url\(\) resource') "the failure did not name the CSS url() guard: $($result.Output)"
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $root '_strata\project_guide.html'))) 'a CSS url() in a style block still produced a Guide'
    }

    # ---------------------------------------------------------------------
    # One shared heading anchor map.
    #
    # Repeated headings are ordinary prose inside a record. The four consumers
    # - rendering, navigation, link rewriting and citation validation - must
    # agree on one allocation, or navigation silently lands on the first
    # occurrence and a citation to a later one is refused as invented.
    # ---------------------------------------------------------------------
    $AnchorPrefix = 'doc-state-anchors-md-heading-'
    $AnchorFixtureRecord = @'
# Anchor fixture

Every occurrence is addressed by name: [the second](#notes-2), [the literal](#notes-2-2),
[the third](#notes-3), [the detail](#detail) and [verification](#verification).

## Notes

The first occurrence answers a bare fragment.

### Detail

A level-three heading. Navigation displays level two; the map still counts this one.

## Notes

The second occurrence.

## Notes 2

A literal heading whose slug is the suffix the second occurrence already took.

## Notes

The third occurrence.

## Verification:

Trailing punctuation is trimmed out of the slug.

```text
## Fenced only
```
'@

    function Add-AnchorRecord([string]$Root) {
        Replace-Utf8 (Join-Path $Root '_strata\state\index.md') "## Contents`n" "## Contents`n`n- [Anchors](anchors.md) - Repeated headings addressed by name.`n"
        Write-Utf8 (Join-Path $Root '_strata\state\anchors.md') $AnchorFixtureRecord
    }

    function New-AnchorGuide([string]$Name) {
        $root = New-Fixture $Name
        Add-AnchorRecord $root
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "exit=$($result.ExitCode) $($result.Output)"
        return (Get-GuideHtml $root)
    }

    function Assert-AnchorId([string]$Html, [string]$Slug) {
        Assert-True ($Html.Contains('id="' + $AnchorPrefix + $Slug + '"')) "the map did not allocate #$Slug"
    }

    Assert-Test 'repeated headings allocate one anchor per occurrence in document order' {
        $html = New-AnchorGuide 'anchor-map'
        foreach ($slug in @('anchor-fixture','notes','detail','notes-2','notes-2-2','notes-3','verification')) {
            Assert-AnchorId $html $slug
        }
        # A literal "Notes 2" heading meeting the generated notes-2 is the collision the contract
        # names: a candidate is tested against everything already allocated, not counted per slug.
        Assert-True ([regex]::Matches($html, [regex]::Escape('id="' + $AnchorPrefix + 'notes-2"')).Count -eq 1) 'notes-2 was allocated twice'
        # A heading inside a fence is sample text. The renderer never emits it.
        Assert-True (-not $html.Contains($AnchorPrefix + 'fenced-only')) 'a fenced heading was allocated an anchor'
        Assert-GuideIntegrity $html
    }

    Assert-Test 'navigation and same-file links reach the intended heading occurrence' {
        $html = New-AnchorGuide 'anchor-navigation'
        # Not merely unique ids: each repeated topic must target its own occurrence. Before the
        # shared map, three of these four navigation items carried the first occurrence's anchor.
        foreach ($slug in @('notes','notes-2','notes-2-2','notes-3','verification')) {
            Assert-True ($html.Contains('data-target="' + $AnchorPrefix + $slug + '"')) "navigation does not target #$slug"
        }
        # Level two is what navigation displays, so the level-three heading is counted but not listed.
        Assert-True (-not $html.Contains('data-target="' + $AnchorPrefix + 'detail"')) 'a level-three heading was listed as a topic'
        Assert-True (-not $html.Contains('data-target="' + $AnchorPrefix + 'fenced-only"')) 'a fenced heading was listed as a topic'
        foreach ($slug in @('notes-2','notes-2-2','notes-3','detail','verification')) {
            Assert-True ($html.Contains('href="#' + $AnchorPrefix + $slug + '"')) "a same-file fragment did not resolve to #$slug"
        }
        Assert-GuideIntegrity $html
    }

    Assert-Test 'citation targets are exactly the anchors the renderer emits' {
        $root = New-CompositionFixture 'anchor-citations' ''
        Add-AnchorRecord $root
        Write-Utf8 (Join-Path $root '_strata\project_guide.md') @'
# Anchors
[[guide:section anchors topic]]

The third occurrence is cited by its own anchor. [authority: _strata/state/anchors.md#notes-3]

The literal heading is cited by its collision-resolved anchor. [authority: _strata/state/anchors.md#notes-2-2]

The level-three heading is addressable too. [authority: _strata/state/anchors.md#detail]
'@
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "a citation to a later occurrence was refused: $($result.Output)"
    }

    Assert-Test 'watched red: a citation to an unallocated anchor fails generation' {
        $root = New-CompositionFixture 'anchor-citation-red' ''
        Add-AnchorRecord $root
        Assert-GuideRefused $root @'
# Anchors
[[guide:section anchors topic]]

There is no fourth occurrence. [authority: _strata/state/anchors.md#notes-4]
'@ 'authority anchor not found' 'an anchor the map never allocated must refuse generation'
        # A heading inside a fence is not a target: accepting it points a reference at a heading the
        # renderer never emitted, which is the same defect as inventing the anchor outright.
        Assert-GuideRefused $root @'
# Anchors
[[guide:section anchors topic]]

The fenced heading is sample text. [authority: _strata/state/anchors.md#fenced-only]
'@ 'authority anchor not found' 'a fenced heading must not be a citation target'
    }

    Assert-Test 'watched red: heading text supplied as a fragment does not resolve' {
        # `#Verification:` is the heading, not the anchor it was allocated. Accepting it would mean
        # slugging supplied fragments, which makes `#Notes 2` an alias for the second `Notes` - the
        # one distinction a suffixed anchor exists to hold. The refusal names the record that wrote
        # the link, the fragment and the record it points into.
        $root = New-Fixture 'anchor-fragment-red'
        Add-AnchorRecord $root
        Replace-Utf8 (Join-Path $root '_strata\state\anchors.md') '[verification](#verification)' '[verification](#Verification:)'
        $refused = $false; $message = ''
        try { $null = Invoke-Context $root @('-GenerateGuide') }
        catch { $refused = $true; $message = $_.Exception.Message }
        Assert-True $refused 'heading text supplied as a fragment still generated a Guide'
        Assert-True ($message -match 'unresolved link fragment') "the refusal did not name the fragment: $message"
        Assert-True ($message -match 'state/anchors\.md links to #Verification:') "the refusal did not name the source link: $message"
        Assert-True ($message -match 'not a heading anchor in state/anchors\.md') "the refusal did not name the target record: $message"
    }

    Assert-Test 'a stripped Contents index is not a citation target' {
        # Compatibility note, pinned: `## Contents` is removed before a record renders, so no anchor
        # for it exists on the page. A citation to #contents used to validate against the raw file
        # and pass, pointing a reference at a heading no reader can reach.
        $root = New-CompositionFixture 'anchor-contents' ''
        Write-Utf8 (Join-Path $root '_strata\project_guide.md') @'
# Anchors
[[guide:section anchors topic]]

The index record itself is citable by its own heading. [authority: _strata/state/index.md#state]
'@
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "a heading the record does render was refused: $($result.Output)"
        Assert-GuideRefused $root @'
# Anchors
[[guide:section anchors topic]]

The stripped index is not a target. [authority: _strata/state/index.md#contents]
'@ 'authority anchor not found' 'a stripped Contents index must not be a citation target'
    }

    Assert-Test 'watched red: navigation slugged apart from the map collapses onto the first occurrence' {
        # The navigation test above went red before the shared map, but on the renderer's duplicate
        # id - not on its own target failure. This breaks navigation alone: the map still allocates
        # correctly and rendering still emits notes, notes-2 and notes-3, while the topic anchors go
        # back to slugging the heading text. Generation succeeds and every nav href resolves to a
        # real id, so Assert-GuideIntegrity passes; only the per-occurrence assertion can see it.
        $root = New-Fixture 'anchor-navigation-red'
        Add-AnchorRecord $root
        Replace-Utf8 (Join-Path $root '_strata\universal\context.ps1') `
            '[void]$topics.Add([pscustomobject]@{ Anchor = $safePrefix + $entry.Slug; Title = $entry.Title })' `
            '[void]$topics.Add([pscustomobject]@{ Anchor = $safePrefix + (Get-HeadingSlug $entry.Title); Title = $entry.Title })'
        $result = Invoke-Context $root @('-GenerateGuide')
        Assert-True ($result.ExitCode -eq 0) "the break was meant to generate, not refuse: $($result.Output)"
        $html = Get-GuideHtml $root
        Assert-AnchorId $html 'notes-2'
        Assert-AnchorId $html 'notes-3'
        Assert-GuideIntegrity $html
        # notes-2 is a poor witness: the literal "Notes 2" heading slugs to it directly, so it
        # survives the break while pointing at the wrong occurrence - which is the original defect.
        Assert-True (-not $html.Contains('data-target="' + $AnchorPrefix + 'notes-3"')) 'the navigation break did not take'
        Assert-True (-not $html.Contains('data-target="' + $AnchorPrefix + 'notes-2-2"')) 'the collision-resolved topic survived the break'
        Assert-True ([regex]::Matches($html, [regex]::Escape('data-target="' + $AnchorPrefix + 'notes"')).Count -gt 1) 'repeated topics did not collapse onto the first occurrence'
    }

    Assert-Test 'watched red: a map that stops counting a rendered level refuses generation' {
        # The renderer consumes the map by position, which holds only while both walk the same
        # headings. Dropping level three from the map leaves every heading after the first one
        # misnumbered; rendering must say so rather than emit anchors nothing else resolves.
        $root = New-Fixture 'anchor-alignment-red'
        Add-AnchorRecord $root
        Replace-Utf8 (Join-Path $root '_strata\universal\context.ps1') `
            "if (`$line -match '^(#{1,6})\s+(.+?)\s*#*`$') {`n            `$level = `$Matches[1].Length" `
            "if (`$line -match '^(#{1,2})\s+(.+?)\s*#*`$') {`n            `$level = `$Matches[1].Length"
        $refused = $false; $message = ''
        try { $null = Invoke-Context $root @('-GenerateGuide') }
        catch { $refused = $true; $message = $_.Exception.Message }
        Assert-True $refused 'a map that skips a rendered heading level still generated a Guide'
        Assert-True ($message -match 'heading map disagrees with the renderer') "the refusal did not name the disagreement: $message"
    }
    Assert-Test 'watched red: a relative link cannot ship in a self-contained Guide' {
        # The Guide is one offline file with nothing beside it, so a link that is still a file path
        # goes nowhere. Records are link-rewritten and a routed target becomes an in-page anchor, but
        # a composition source is not rewritten at all and an unrouted target is left as written -
        # either way the path survives into the page. The unresolved-fragment check cannot see it:
        # that check only inspects hrefs beginning with #, and this one begins with a path.
        $root = New-CompositionFixture 'relative-link' ''
        Assert-GuideRefused $root @'
# Anchors
[[guide:section anchors topic]]

A link to [a record](_strata/state/current.md) that stays a file path. [authority: _strata/state/current.md]
'@ 'relative link' 'a relative link must not ship in the Guide'
    }

    Assert-Test 'an in-page anchor and an absolute link are both still allowed' {
        # The guard refuses a path, not a link. Everything the Guide legitimately emits is either an
        # in-page anchor or scheme-qualified, and this pins that so the guard cannot be tightened
        # into refusing the Guide's own navigation.
        $composed = New-ComposedGuide 'relative-link-allowed' @'
# Anchors
[[guide:section anchors topic]]

The upstream project is public. [authority: _strata/state/current.md]

See [the site](https://example.invalid/docs) for background. [authority: _strata/state/current.md]
'@
        $html = Get-GuideHtml $composed.Root
        Assert-True ($html -match 'href="https://example\.invalid/docs"') 'an absolute link was not preserved'
        # A composed Guide renders no authority sections, so its in-page anchors are its own sections.
        Assert-True ($html -match 'href="#guide-section-anchors"') 'the Guide emits no in-page anchors'
        Assert-GuideIntegrity $html
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
