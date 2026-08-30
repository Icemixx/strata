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

**Gate on entry.** Before reading the brief, opening a file, or creating anything, determine your model
from the live source your dossier names. If it maps below Architect, name the model the user must switch
to - Opus for Claude Code, Sol for Codex - say the other participant needs Architect too, and stop. A
refusal creates nothing and is not a void debate.

**Then check before every action, for the whole debate.** Not once on entry and not once per round: before
each search, file read, command, edit, and before writing anything. Every action taken under this
procedure is taken by an Architect or it is not taken. A round spans many turns and a turn spans many
requests, and the model can change at either boundary - the user switches between turns, and capacity
fallback can serve a later request in the same turn from a different model. A gate that runs once
certifies only the work already done. The live source is restated on every request, so this costs no tool
call and no round trip; there is no efficiency argument for checking less often.

**On drift, stop where you are.** Do not complete the action in hand. If it dropped below Architect, take
no further action, leave no partial round, and say in normal chat what you determined and where you
stopped; the user decides whether to reseat or end. If it changed but remains Architect, disclose the
change and continue - same role, disclosed, which is the DAP substitution rule.

**Not knowing is not a refusal.** Inability to determine your model is disclosed and the debate proceeds;
treating it as disqualifying makes the procedure unrunnable on any harness that withholds model identity,
which is a gate that fails closed rather than a safeguard. Disclose it on entry and in each round heading,
and keep checking in case the source becomes available.

Do not spawn an Architect to take a round. A participant is the session itself; switch the session or do
not debate.

The user carries every exchange between providers. No agent invokes, polls, or notifies the other. This is
load-bearing rather than a limitation: it is what keeps each participant's framing its own.

## Phases

1. **Reports.** Both participants receive the same brief and work independently. Neither sees the other's
   output until both are finished. Skip this phase when the artifacts already exist.
2. **Cross-analysis.** Each participant reads both reports and writes its own comparison without seeing the
   other's comparison. This blindness is mandatory. Without it the first writer frames the comparison and
   the second answers that framing instead of the evidence.
3. **Rounds.** Each participant reads everything, verifies contested claims against the repository, and
   appends one round. Never edit an earlier round, including your own; correct it by writing a new entry
   that names what it corrects.

## Rounds

Head each round `## Round N — <product> / <model> (<tier>)`. Both fields record what you determined this
round, never what the procedure requires. Write the model id you determined, or `model-undisclosed` when
you could not. Write `Architect` when the id maps to it, or `Architect-unconfirmed` when you could not
determine the model — stamping `Architect` on a round whose participant just said it cannot confirm its
model asserts the one thing that was not established. In your first round, also state in one line whether
you can execute verification commands against the repository.

**Read a live source, not a record of past turns.** Determine the model executing this turn, from
whatever your harness exposes as current. A transcript or rollout that is written when a turn finishes
reports the previous turn, so a procedure resting on it alone certifies the round it has already written
rather than the one it is about to write. The dossiers name the live source for each harness.

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

The branch is Build Log evidence. Write settled conclusions into the authority that owns them — decisions to
Rationale, status and remaining work to State — and link them to `settled.md`. A void debate produces no
authority record. Guide is not regenerated.

## Limits

Nothing detects a stalled debate; only the user can restart or close one. Neither participant can verify the
other's model, so tier is an attestation. Two Architects exchanging rounds is expensive, and that cost is
the intended brake: use DAP when one provider's scrutiny is enough.
