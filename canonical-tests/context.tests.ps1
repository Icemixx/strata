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

function Invoke-Context([string]$Root, [string[]]$Arguments) {
    $script = Join-Path $Root '_strata\universal\context.ps1'
    $out = Join-Path $Root ('result-' + [Guid]::NewGuid().ToString('N') + '.txt')
    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$script) + $Arguments
    $process = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $argList -RedirectStandardOutput $out -RedirectStandardError ($out + '.err') -Wait -PassThru
    $text = ''
    if (Test-Path -LiteralPath $out) { $text += [IO.File]::ReadAllText($out) }
    if (Test-Path -LiteralPath ($out + '.err')) { $text += [IO.File]::ReadAllText($out + '.err') }
    return [pscustomobject]@{ ExitCode=$process.ExitCode; Output=$text }
}

function Assert-Test([string]$Name, [scriptblock]$Body) {
    try { & $Body; Write-Output "PASS $Name"; $script:Passed++ }
    catch { Write-Output "FAIL $Name :: $($_.Exception.Message)"; $script:Failed++ }
}

function Assert-True([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }

try {
    New-Item -ItemType Directory -Path $TempRoot | Out-Null

    Assert-Test 'no arguments shows help and writes nothing' {
        $root = New-Fixture 'help'
        $result = Invoke-Context $root @()
        Assert-True ($result.ExitCode -eq 0) "exit=$($result.ExitCode) $($result.Output)"
        Assert-True ($result.Output -match 'Usage:') 'usage was not shown'
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $root '_strata\project_guide.html'))) 'Guide was written'
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
        @{ Name='typed Why targets HOW'; Code='TYPED_LINK_TARGET'; Mutate={ param($r) Replace-Utf8 (Join-Path $r '_strata\state\current.md') '../rationale/R1.md' '../build-log/BUG-1.md' } }
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
        Assert-True ($html -match 'Generated from routed State') 'generated marker missing'
        Assert-True ($html -match 'id="ticket-BUG-1"') 'stable ticket anchor missing'
        Assert-True ($html -match '<h3>Why</h3>') 'ticket-linked WHY section missing'
        Assert-True ($html -match '<h3>How</h3>') 'ticket-linked HOW section missing'
        Assert-True ($html -notmatch '<script>alert') 'raw script executed'
        Assert-True ($html -notmatch 'href="javascript:') 'unsafe link survived'
        Assert-True ($html -notmatch '<img') 'remote image was embedded'
        Assert-True ($html -match '<table>') 'table was not rendered'
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
if ($Failed -ne 0) { exit 1 }
