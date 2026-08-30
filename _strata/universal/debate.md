# Debate

Use this procedure to reconcile independently-derived work with an Architect from a different provider.
A DAP council's seats share one provider and therefore one prior: it scrutinizes reasoning well and shared
blind spots poorly. Debate breaks that correlation. Two participants from the same provider are a council,
not a debate.

## Preconditions

Both participants are Architect. `active-agent.md` and the harness dossiers own the role-to-model mapping;
this procedure does not restate it. Substitution follows the DAP rule: same role only, disclosed, and no
same-role model means the procedure cannot run.

Seating Architect-tier participants on both sides is the user's responsibility, because no agent can
verify the other's model and not every harness tells an agent its own.

**Gate on entry.** Determine your model from the live source your dossier names before anything else. If
it maps below Architect, name the model the user must switch to - Opus for Claude Code, Sol for Codex -
say the other participant needs Architect too, and stop. A refusal creates nothing and is not a void
debate.

Reading this file and your own harness dossier is part of that determination rather than work performed
under it; the brief, repository files, searches and commands wait until the gate has passed. An earlier
wording forbade opening any file at all, which the check itself cannot satisfy: both participants had to
break its letter to perform it, and each then drew its own line about what else it could read on the way.
One read three files unrelated to the brief.

**Then check again at the start of every prompt, for the whole debate.** Not once on entry and not once
per round. A prompt is the boundary because the live source is restated with each one: the check costs no
tool call and lands exactly where the model can have changed. A round spans many prompts and the user
switches between them, so a gate that runs once certifies only the work already done.

An earlier version demanded a check before each search, file read, command and edit. There is no moment
between tool calls where an agent naturally re-reads anything, so that rule was followed by nobody and
quietly licensed the assumption that entry was enough. A procedure that asks for what cannot be executed
buys less than one that asks for what can.

**Re-read this file at the start of every round.** A debate spans hours and many turns, and the copy in
your context is a memory of the procedure rather than the procedure. Read it from disk before each round,
for the same reason you re-check the model: the contract is the file, not your recollection of it. This
has already happened - a participant continued under a branch that had been removed from the file it named
as its authority, having read that file before the change.

Whoever is editing the procedure stops while a debate is running. A contract revised mid-execution leaves
the two participants following different texts, and neither can see that it happened.

**On drift, stop where you are.** Do not complete the action in hand. If it dropped below Architect, take
no further action, leave no partial round, and say in normal chat what you determined and where you
stopped; the user decides whether to reseat or end. If it changed but remains Architect, disclose the
change and continue - same role, disclosed, which is the DAP substitution rule.

**Report the stop from what you did, not from what a stop usually looks like.** Name the files you opened
and the work you finished before the gate fired, by checking rather than by recalling. A stop statement
describes this turn and is as falsifiable as the model citation, so it is written the same way: a
participant reused the wording of an earlier clean refusal and reported opening no files, having just
opened five.

Evidence gathered below Architect does not enter the debate. Disclose it so the user can see what
happened, then leave it for an Architect to gather again - a finding produced by a Technician and quoted
into a round is laundered through the chat rather than earned.

**If you cannot determine it, ask the user; never certify yourself.** Not knowing is not a refusal of the
debate, and it is not permission to act as an Architect either. Say what you tried and what it returned,
and ask the user to confirm the tier. Their answer is the attestation, recorded in the round heading as
`Architect (user-attested)`, and seating participants was always their responsibility. Keep checking in
case the source becomes available.

Self-certifying on an unverified claim is the fail-open twin of refusing when the answer is merely
unavailable. Both end the same way - a round written by a model nobody established was Architect - so
neither an agent's inability nor its assurance may open the gate on its own. This clause has been abused
once already: a session that had determined its exact model minutes earlier reported that it could not,
and proceeded.

Do not spawn an Architect to take a round. A participant is the session itself; switch the session or do
not debate.

The user carries every exchange between providers. No agent invokes, polls, or notifies the other. This is
load-bearing rather than a limitation: it is what keeps each participant's framing its own.

## Phases

1. **Reports.** Both participants receive the same brief and work independently. Neither sees the other's
   output until both are finished. Skip this phase when the artifacts already exist.
2. **Cross-analysis.** Each participant reads both reports and writes its own comparison without seeing
   the other's comparison. This blindness is mandatory. Without it the first writer frames the comparison and
   the second answers that framing instead of the evidence.
3. **Rounds.** Each participant reads everything, verifies contested claims against the repository, and
   appends one round. Never edit an earlier round, including your own; correct it by writing a new entry
   that names what it corrects.

## Rounds

Head each round `## Round N — <product> / <model> (<tier>)`. Both fields record what you determined this
round, never what the procedure requires. Write the model id you determined, or `model-undisclosed` when
you could not and the user attested the tier instead. Write `Architect` when the id maps to it, or
`Architect (user-attested)` when you could not determine the model and the user confirmed the tier -
stamping a bare `Architect` on a round whose participant could not confirm its model asserts the one thing
that was not established. In your first round, also state in one line whether you can execute
verification commands against the repository.

**The test is what the value describes, not where it is stored.** Use whatever reports the model
executing the prompt you are in. A record qualifies when it is written as a turn begins - Codex's
`turn_context` is such a record and is its authoritative source. A record does not qualify as the live
value when it is written as a turn ends, because its newest entry is then the previous turn and the one in
flight is absent; Claude Code's `message.model` is that shape, which is why its dossier sends you to the
environment context. That transcript still does something the live source cannot - recording the model per
assistant message, it is where a mid-prompt fallback becomes visible - but that is evidence after the
fact, not the determination. Your dossier names your source: if it names one, you have one.

**Cite the determination so it can be falsified.** Under the heading, give the source you read and the
exact value it returned. Where a durable record also exists, add the figure that lets a reader confirm you
read the right one - its path and record count - alongside the live value:

```text
Model: <id> - live source: <what you read>
History: <path> (<n> records) - <first> -> <last>
```

Nothing can mechanically stop a participant writing a heading it did not earn, and no agent can read
another provider's runtime. A citation does not close that gap; it changes what a false claim costs. An
unsupported assertion is invisible, while a cited one is checkable by the user, who holds both sides, and
by anyone with the file. The count matters: an agent that read a 10-record sidechain instead of its own
1,793-record session was caught by that number alone.

End every round with a turn marker on its own line:

```text
Round N complete — next: <participant>
```

`<participant>` is the product - `Claude Code` or `Codex` - never a model or a person. The model can
change mid-debate while the participant does not, so a marker naming a model stops addressing anyone the
moment a legitimate Architect-to-Architect switch happens.

Number rounds sequentially across the whole file, not per participant: read the highest N present and
write N+1. The file is shared, so two participants numbering their own sequences produce two Round 2s that
append-only forbids correcting.

Before writing, read the last turn marker. If it does not name you, say so in normal chat, name the
participant whose turn it is, and stop. Being asked again does not make it your turn. When the file
carries no marker yet, the participant asked first opens; if both were asked, the one whose report is
alphabetically first by product opens, so neither waits for the other.

Tag every position `CONCEDE`, `HOLD`, `NEW`, or `QUESTION`. A HOLD carries evidence, not restatement.
Verify a contested claim yourself instead of accepting another participant's measurement, including your
own from an earlier round. Distinguish a factual conflict from a severity, scope, or coverage difference;
collapsing them wastes rounds. Concede only what the evidence requires, because an unearned concession
corrupts the settled record as much as a wrong claim.

A claim is settled only when the other participant expressly accepts it; silence settles nothing. An
acceptance given in the same round the claim was raised settles it at the end of that round. A settled
claim is not reopened.

## Outcomes

- **Converged** — no unresolved HOLD and no open QUESTION remain. The next round is the settled list,
  which is recorded as `settled.md`.
- **Terminated** — the user declares the debate over. Settled items stand and remain usable. Every
  unresolved HOLD and open QUESTION returns to the user with both positions preserved and neither winning.
- **Void** — the premise failed: one provider on both sides, role drift, or no shared verifiable ground.
  Nothing produced is usable.

A debate ends only by convergence or by the user declaring it terminated. No count of rounds or exchanges
closes it, and no disagreement resolves itself by lasting.

Either participant may call void on role drift, provider identity, or absent verifiable ground. Only the
user can call a false attestation or declare a debate terminated; no agent can see another provider's
runtime.

Close `rounds.md` with exactly one stamp:

- `DEBATE: converged — [count] settled — [models] — [subject]`
- `DEBATE: terminated — [reason] — [count] settled, [count] open — [models] — [subject]`
- `DEBATE: void — [reason] — [models] — [subject]`

## Recording

While the debate runs, every artifact lives in `_sediment/debate-<subject>/` at the repository root. Both
participants read and write that exact path: a rendezvous both sides must find is a path, not a
description, and two participants who each pick their own scratch location run two monologues that never
meet. An unfinished debate is deliberation, which is what `_sediment/` is for.

The branch holds `index.md`, one `report-<product>.md` and one `cross-<product>.md` per participant,
`rounds.md`, and `settled.md`. Name leaf files by product - `report-codex.md`, `report-claude-code.md` -
never by model: a participant may legitimately change model mid-debate while remaining Architect, and a
filename that moves is a filename the other side cannot find.

On close, move the branch to `_strata/build-log/debate-<subject>-<YYYY-MM-DD>/` and add its parent index
entry in the same transaction.

The branch is Build Log evidence. Write settled conclusions into the authority that owns them - decisions
to Rationale, status and remaining work to State - and link them to `settled.md`. A void debate produces
no authority record. Guide is not regenerated.

## Limits

A model change inside a single prompt is not detected. Capacity fallback can serve part of one response
from a lower tier, and no live check sits between an agent's own tool calls: an Opus session doing Phase 1
work was served its final write by Sonnet as it hit a session limit, and nothing fired. The transcript is
what catches this, because it records the model per assistant message after the fact - live checking
covers the boundary between prompts, the durable record covers what happens inside one. Cite both.

Nothing detects a stalled debate; only the user can restart or close one. Neither participant can verify
the other's model, so tier is an attestation. Two Architects exchanging rounds is expensive, and that
cost is the intended brake: use DAP when one provider's scrutiny is enough.
