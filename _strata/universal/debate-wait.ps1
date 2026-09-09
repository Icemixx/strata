<#
.SYNOPSIS
    One bounded liveness fire for the unattended Debate procedure.

.DESCRIPTION
    `_strata/universal/debate.md` prescribes automatic file-backed coordination: a participant that
    owes nothing waits, re-reading validated shared state until the record it awaits appears. This
    script is that wait, and it is the only implementation. Both participants run this same file.

    It exists because the procedure was previously realized twice - once per harness, in two shell
    languages - from prose alone. Three defects followed, each an asymmetry rather than a
    misunderstanding of the rule: a resume anchor floored in one implementation and not the other, a
    round marker that matched in one and not the other, and a fire bound that held its duration in one
    and accumulated its own work time in the other. One implementation cannot diverge from itself.

    Exactly one line is written to the output stream, and it is the result:

        FOUND            the awaited completion record is present in a wholly valid history
        fire complete    the interval elapsed with nothing found; issue the next fire immediately
        SUSPENDED - ...  the participant owing liveness has been silent past the threshold
        Blocked ...      shared state cannot be trusted; stop, report this line, repair nothing

    A fire is one logical check. How many harness calls it takes to span one is a harness question:
    consult the applicable `harness-<product>.md` dossier rather than assuming a single call.

.PARAMETER Product
    This session's product name. It must match A or B in the brief; everything else is derived.

.PARAMETER Await
    The completion record or round turn this wait is for. Round waiting releases when the latest valid
    turn marker names this participant or a valid Debate outcome closes the rounds file.

.PARAMETER WaitStarted
    UTC instant this wait began, set once by the caller and passed unchanged to every later fire of
    the same wait. It is the floor of the inactivity anchor, so a resumed session gets a fresh window
    rather than re-suspending on the activity that suspended it. This script never assigns it.

.PARAMETER Interval
    Seconds this fire runs. The caller takes it from the tier schedule in `debate.md`, which owns the
    offsets; this script owns only the honouring of one interval. The bound is wall-clock, so a short
    interval is a faithful small fire rather than a special case, and the timing contract can be
    tested in seconds instead of minutes.

.PARAMETER DebatePath
    Directory holding `coordination.md` and `rounds.md`.

.NOTES
    This file is deliberately ASCII-only. A round marker written with an em dash stopped matching when
    the character was recoded in transport; the marker pattern therefore uses `.` for that position and
    depends on no agreement between the file's encoding and the console's.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Product,
    [Parameter(Mandatory)][ValidateSet('report-complete', 'cross-complete', 'round')][string]$Await,
    [Parameter(Mandatory)][datetime]$WaitStarted,
    [Parameter(Mandatory)][ValidateRange(1, 600)][int]$Interval,
    [string]$DebatePath = '.'
)

$ErrorActionPreference = 'Stop'

# Fixed by the procedure, not by the caller. Both participants must run identical timings, so these
# are constants here rather than parameters: a caller cannot introduce an asymmetry it is not
# permitted to have. Only $Interval varies, and only across the published tier values.
$poll = 15          # re-read shared state this often inside a fire
$heartbeat = 300    # append ALIVE every 5 minutes while this session owes liveness
$stale = 900        # 15 minutes of silence from the owing participant suspends the debate
$tornGrace = 60     # an unterminated tail older than this is not a write in flight

$f = Join-Path $DebatePath 'coordination.md'
$r = Join-Path $DebatePath 'rounds.md'

if (-not (Test-Path -LiteralPath $f)) { 'Blocked coordination file not found'; return }

# A wait that re-anchors on each fire silently skips a heartbeat that was already due and re-suspends
# a resumed session on its first check. Taking it as a parameter makes assigning it unrepresentable;
# validating its kind keeps a local-time value from being read as UTC.
if ($WaitStarted.Kind -ne [DateTimeKind]::Utc) { 'Blocked WaitStarted must be a UTC [datetime]'; return }

# Roles come from the brief, never from a literal.
$brief = Get-Content -LiteralPath $f -Encoding utf8
$A = (($brief | Where-Object { $_ -match '^A: ' }) -split ': ', 2)[1]
$B = (($brief | Where-Object { $_ -match '^B: ' }) -split ': ', 2)[1]
if (-not $A -or -not $B) { 'Blocked brief does not name both participants'; return }

# Without this the peer of an unrecognized name resolves to A, and the session then keeps A's
# liveness and reads A's eligibility while believing it is someone else - wrong, and silent.
$me = $Product
if ($me -ne $A -and $me -ne $B) { 'Blocked Product is not a participant named in the brief'; return }
$peer = if ($me -eq $A) { $B } else { $A }

# The kit is product-agnostic, so a product name is untrusted regex input.
$Ax = [regex]::Escape($A)
$Bx = [regex]::Escape($B)
$ts = '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z'
$stampRe = "^STAMP \| (report|cross)-complete \| ($Ax|$Bx) \| $ts \| END$"
$aliveRe = "^ALIVE \| ($Ax|$Bx) \| $ts \| END$"
$markRe = "^Round \d+ complete . next: ($Ax|$Bx)$"
$outcomeRe = '^DEBATE: (converged . \d+ settled . .+|terminated . .+ . \d+ settled, \d+ open . .+|void . .+ . .+)$'

function Terminated {
    $s = [IO.File]::Open($script:f, 'Open', 'Read', 'ReadWrite')
    try {
        if ($s.Length -eq 0) { return $false }
        [void]$s.Seek(-1, 'End')
        $s.ReadByte() -eq 10
    } finally { $s.Dispose() }
}

function HasHeading { @(Get-Content -LiteralPath $script:f -Encoding utf8) -contains '## Completion history' }

function Records {
    $all = @(Get-Content -LiteralPath $script:f -Encoding utf8)
    $h = [array]::IndexOf($all, '## Completion history')
    if ($h -lt 0 -or $h + 1 -ge $all.Length) { return @() }
    @($all[($h + 1)..($all.Length - 1)] | Where-Object { $_.Trim() -ne '' })
}

# Classify the whole history before trusting any part of it. Only a wholly valid history releases.
function HistoryState {
    # A missing heading is no history section, not an empty one. Treating it as empty releases nothing
    # but accepts everything after it as the whole truth.
    if (-not (HasHeading)) { return 'Blocked completion-history heading missing' }
    if (-not (Terminated)) {
        # A genuine in-flight write completes in milliseconds. Age the tail rather than counting reads,
        # so escalation survives a fire boundary that would reset a counter.
        if (([datetime]::UtcNow - (Get-Item -LiteralPath $script:f).LastWriteTimeUtc).TotalSeconds -ge $script:tornGrace) {
            return 'Blocked persistent unterminated record'
        }
        return 'InFlight'
    }
    $rec = Records
    if (@($rec | Where-Object { $_ -notmatch $script:stampRe -and $_ -notmatch $script:aliveRe }).Count) {
        return 'Blocked completed malformed record'
    }
    $keys = @($rec | Where-Object { $_ -match $script:stampRe } | ForEach-Object { $x = $_ -split ' \| '; "$($x[1])/$($x[2])" })
    if (@($keys | Group-Object | Where-Object Count -gt 1).Count) { return 'Blocked duplicate completion' }
    $prefixes = @('', "report-complete/$script:A",
        "report-complete/$script:A report-complete/$script:B",
        "report-complete/$script:A report-complete/$script:B cross-complete/$script:A",
        "report-complete/$script:A report-complete/$script:B cross-complete/$script:A cross-complete/$script:B")
    if (($keys -join ' ') -notin $prefixes) { return 'Blocked out-of-order completion history' }
    return 'Valid'
}

function BlindPhasesComplete {
    $cross = @(Records | Where-Object { $_ -match $script:stampRe -and $_ -match '^STAMP \| cross-complete \| ' })
    $cross.Count -eq 2
}

# The latest completed turn comes from two files: the newest STAMP during blind phases, and during
# rounds the newest turn marker, whose completer is whoever the marker does not name. A marker carries
# no timestamp, so rounds.md's modification time supplies one; 15-minute staleness needs no finer
# resolution. A loop reading only coordination.md picks the wrong writer for the whole rounds phase.
function LatestTurn {
    $s = Records | Where-Object { $_ -match $script:stampRe } | Select-Object -Last 1
    $sa = $null
    if ($s) {
        $x = $s -split ' \| '
        $sa = [pscustomobject]@{ Author = $x[2]; Time = [datetime]::Parse($x[3]).ToUniversalTime() }
    }
    $ra = $null
    if ((BlindPhasesComplete) -and (Test-Path -LiteralPath $script:r)) {
        $m = Get-Content -LiteralPath $script:r -Encoding utf8 | Where-Object { $_ -match $script:markRe } | Select-Object -Last 1
        if ($m) {
            $nxt = ($m -split 'next: ')[1]
            $author = if ($nxt -eq $script:A) { $script:B } else { $script:A }
            $ra = [pscustomobject]@{ Author = $author; Time = (Get-Item -LiteralPath $script:r).LastWriteTimeUtc }
        }
    }
    if ($ra -and (-not $sa -or $ra.Time -gt $sa.Time)) { return $ra }
    return $sa
}

function Eligible { param($who) $t = LatestTurn; if (-not $t) { return $who -eq $script:A }; return $t.Author -ne $who }

function LastAlive {
    param($who)
    $l = Records | Where-Object { $_ -match $script:aliveRe -and ($_ -split ' \| ')[1] -eq $who } | Select-Object -Last 1
    if ($l) { [datetime]::Parse(($l -split ' \| ')[2]).ToUniversalTime() }
}

# Activity timestamps are control inputs, not labels. Both participants read the same repository host
# clock, so any future value is a conflict rather than fresh evidence. Check every timestamp-bearing
# surface: a future STAMP or a future rounds.md mtime suppresses suspension exactly as a future ALIVE does.
function ActivityState {
    foreach ($line in @(Records)) {
        $x = $line -split ' \| '
        if ($line -match $script:stampRe) { $kind = 'STAMP'; $raw = $x[3] }
        elseif ($line -match $script:aliveRe) { $kind = 'ALIVE'; $raw = $x[2] }
        else { continue }
        try { $at = [datetime]::Parse($raw).ToUniversalTime() }
        catch { return "Blocked invalid $kind timestamp $raw" }
        # Sample now per value, not once before the read: a record that legitimately lands during this
        # pass would otherwise compare against an older instant and read as future.
        if ($at -gt [datetime]::UtcNow) { return "Blocked future $kind timestamp $($at.ToString('yyyy-MM-ddTHH:mm:ssZ'))" }
    }
    if ((BlindPhasesComplete) -and (Test-Path -LiteralPath $script:r)) {
        $marker = Get-Content -LiteralPath $script:r -Encoding utf8 | Where-Object { $_ -match $script:markRe } | Select-Object -Last 1
        $roundTime = (Get-Item -LiteralPath $script:r).LastWriteTimeUtc
        if ($marker -and $roundTime -gt [datetime]::UtcNow) {
            return "Blocked future rounds.md modification time $($roundTime.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        }
    }
    return 'Credible'
}

function RoundReady {
    param($product)
    if (-not (BlindPhasesComplete) -or -not (Test-Path -LiteralPath $script:r)) { return $false }
    $lines = @(Get-Content -LiteralPath $script:r -Encoding utf8)
    if (@($lines | Where-Object { $_ -match $script:outcomeRe }).Count -eq 1) { return $true }
    $marker = $lines | Where-Object { $_ -match $script:markRe } | Select-Object -Last 1
    if (-not $marker) { return $false }
    (($marker -split 'next: ')[1] -eq $product)
}

# Only a Valid history can release anything; the loop establishes that before calling this.
function Accepted {
    param($phase, $product)
    if ($phase -eq 'round') { return (RoundReady $product) }
    @(Records | Where-Object { $_ -match "^STAMP \| $phase \| $([regex]::Escape($product)) \| " }).Count -eq 1
}

# Sleep no further than this fire's end. The interval is a wall-clock bound, so per-pass work - file
# reads, validation, a heartbeat append - is absorbed by the sleep rather than added to the fire. A
# loop that instead counts the sleeps it requested returns late by the total work it did, and the
# procedure's offsets are absolute positions from the wait's start, so that error accumulates across
# fires. It also pushes a nominal 600-second fire past the single-call ceiling that tier was sized to.
function Nap {
    $ms = [int][Math]::Ceiling(($script:end - [datetime]::UtcNow).TotalMilliseconds)
    if ($ms -gt 0) { Start-Sleep -Milliseconds ([Math]::Min(($script:poll * 1000), $ms)) }
}

$end = [datetime]::UtcNow.AddSeconds($Interval)
$fireEnded = $false
while ([datetime]::UtcNow -lt $end) {
    $now = [datetime]::UtcNow

    $state = HistoryState
    if ($state -like 'Blocked*') { $state; $fireEnded = $true; break }   # stop and report; never repair
    if ($state -eq 'InFlight') { Nap; continue }

    $activityState = ActivityState
    if ($activityState -like 'Blocked*') { $activityState; $fireEnded = $true; break }

    $acceptedFor = if ($Await -eq 'round') { $me } else { $peer }
    if (Accepted $Await $acceptedFor) { 'FOUND'; $fireEnded = $true; break }

    if (Eligible $me) {
        $mine = LastAlive $me
        $since = if ($mine) { $mine } else { $WaitStarted }
        if (($now - $since).TotalSeconds -ge $heartbeat) {
            # Re-verify eligibility and validity in the same breath as the append.
            if ((Eligible $me) -and ((HistoryState) -eq 'Valid')) {
                $line = "ALIVE | $me | $($now.ToString('yyyy-MM-ddTHH:mm:ssZ')) | END"
                $enc = New-Object System.Text.UTF8Encoding($false)
                $sw = [Diagnostics.Stopwatch]::StartNew()
                $wrote = $false
                # AppendAllText denies write to any peer holding the file, and that exclusion is the
                # point: a shared append mode lets a concurrent write land at a stale position and
                # overwrite a peer's line while both writers report success. Bound the retry by
                # elapsed time rather than a count of sleeps.
                while (-not $wrote -and $sw.ElapsedMilliseconds -lt 1000) {
                    try { [IO.File]::AppendAllText($f, $line + "`n", $enc); $wrote = $true }
                    catch { Start-Sleep -Milliseconds 10 }
                }
                if (-not $wrote) { 'Blocked heartbeat could not be published'; $fireEnded = $true; break }
                if (@(Records | Where-Object { $_ -eq $line }).Count -ne 1) {
                    'Blocked ambiguous heartbeat publication'; $fireEnded = $true; break
                }
            }
        }
    }

    # The participant owing the next completion or round owns liveness; before any completion, A does.
    $t = LatestTurn
    $owed = if ($t) { if ($t.Author -eq $A) { $B } else { $A } } else { $A }
    $anchor = LastAlive $owed
    if ($t -and (-not $anchor -or $t.Time -gt $anchor)) { $anchor = $t.Time }
    if (-not $anchor -or $WaitStarted -gt $anchor) { $anchor = $WaitStarted }
    if (($now - $anchor).TotalSeconds -ge $stale) {
        "SUSPENDED - no activity from $owed since $($anchor.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        $fireEnded = $true; break
    }

    Nap
}
if (-not $fireEnded) { 'fire complete' }
