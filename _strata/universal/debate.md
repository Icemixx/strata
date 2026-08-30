# Debate

## Check your model first

1. Read your own harness dossier, at this exact path in the repository you were pointed at:
   - Codex: `_strata/universal/harness-codex.md`
   - Claude Code: `_strata/universal/harness-claude-code.md`

   That path, directly. Do not search for the file, do not look for it at the workspace root, and do not
   consult `active-agent.md`, memory, or the debate branch to find out who you are.
2. Determine your model the way it says, and map the id to a role.
3. If it is not Architect, tell the user which model to switch to - **Opus** for Claude Code, **Sol** for
   Codex - add that the other participant needs Architect too, and stop. Create nothing. Stopping is not a
   void debate.

Do this again at the start of every prompt, for the whole debate. Those two files are the check itself,
not work performed under it; the brief, repository files, searches and commands wait until it has passed.

If it drops below Architect later, stop where you are: no further action, no partial round, and say in
normal chat what you determined and where you stopped. If it changed but is still Architect, disclose it
and carry on. If you cannot determine it at all, say what you tried and what it returned and ask the user
to confirm the tier - never certify yourself, and never read an unconfirmed model as an Architect.

Say what you actually did when you stop, checked rather than recalled, and leave anything you gathered
below Architect out of the debate: disclose it, then let an Architect gather it again.

## Purpose

Use this procedure to reconcile independently-derived work with an Architect from a different provider.
Two participants from the same provider are a council, not a debate; use `dap.md` for those.

## Preconditions

Both participants are Architect, and seating them is the user's responsibility: no agent can verify the
other's model. Substitution follows the DAP rule - same role only, disclosed, and no same-role model means
the procedure cannot run.

Re-read this file from disk at the start of every round; do not work from the copy in your context.
Whoever is editing it stops while a debate is running.

Do not spawn an Architect to take a round. A participant is the session itself; switch the session or do
not debate.

The user carries every exchange between providers. No agent invokes, polls, or notifies the other.

## The brief

A brief says which phase, the subject, the question, and nothing about tier. Do not open a brief with an
instruction to read a file.

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

Use the source your dossier names as live: it reports the model executing the prompt you are in. A record
written as a turn ends is not that source; it reports the previous turn. Where your dossier also names a
durable record, cite it as evidence after the fact, never as the determination.

**Cite the determination so it can be falsified.** Under the heading, give the source you read and the
exact value it returned. Where a durable record also exists, add the figure that lets a reader confirm you
read the right one - its path and record count - alongside the live value:

```text
Model: <id> - live source: <what you read>
History: <path> (<n> records) - <first> -> <last>
```

The record count is not optional. It is what lets a reader confirm the session cited is the session that
ran.

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
collapsing them wastes rounds. Concede only what the evidence requires.

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
never by model. A participant may change model mid-debate while remaining Architect, and a filename that
moves is one the other side cannot find.

On close, move the branch to `_strata/build-log/debate-<subject>-<YYYY-MM-DD>/` and add its parent index
entry in the same transaction.

The branch is Build Log evidence. Write settled conclusions into the authority that owns them - decisions
to Rationale, status and remaining work to State - and link them to `settled.md`. A void debate produces
no authority record. Guide is not regenerated.

## Limits

A model change inside a single prompt is not detected. Capacity fallback can serve part of one response
from a lower tier, and no live check sits between an agent's own tool calls. The transcript catches this
after the fact, recording the model per assistant message. Cite both sources.

Nothing detects a stalled debate; only the user can restart or close one. Neither participant can verify
the other's model, so tier is an attestation. Two Architects exchanging rounds is expensive, and that
cost is the intended brake: use DAP when one provider's scrutiny is enough.
