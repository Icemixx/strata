# Debate

## Purpose

Use this procedure to reconcile independently-derived work with an agent from a different provider. Two
participants from the same provider are a council, not a debate; use `dap.md` for those.

## Preconditions

The user seats the two provider sessions.

Re-read this file from disk at the start of every round; do not work from the copy in your context.
Whoever is editing it stops while a debate is running.

A participant is the session itself. Do not spawn an agent to take a round; switch the session or do not
debate.

The user carries every exchange between providers. No agent invokes, polls, or notifies the other. The
participant that creates a debate returns one ready-to-paste opening prompt for the other participant in
normal chat; the user transports that prompt but does not have to reconstruct the handoff. The prompt
names the repository and debate-branch path, phase, exact inputs and output file, and any blindness rule.
It tells the recipient to re-read this procedure from disk. It does not quote or summarize an artifact the
recipient must not yet see. After creation, the shared files and turn marker carry the handoff; a simple
user instruction to proceed is sufficient. Do not provide another transport prompt.

## The brief

A brief says which phase, the subject, and the question.

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

Head each round `## Round N — <product>`. In your first round, also state in one line whether you can
execute verification commands against the repository.

End every round with a turn marker on its own line:

```text
Round N complete — next: <participant>
```

`<participant>` is the product - `Claude Code` or `Codex` - never a person or session detail. That name
stays stable for the whole debate.

Number rounds sequentially across the whole file, not per participant: read the highest N present and
write N+1. The file is shared, so two participants numbering their own sequences produce two Round 2s that
append-only forbids correcting.

Before writing, read the last turn marker. If it does not name you, say so in normal chat, name the
participant whose turn it is, and stop. Being asked again does not make it your turn. When the file
carries no marker yet, the participant asked first opens.

Tag every position `CONCEDE`, `HOLD`, `NEW`, or `QUESTION`. A HOLD carries evidence, not restatement.
Verify a contested claim yourself instead of accepting another participant's measurement, including your
own from an earlier round. Distinguish a factual conflict from a severity, scope, or coverage difference;
collapsing them wastes rounds. Concede only what the evidence requires.

A claim is settled only when the other participant expressly accepts it; silence settles nothing. An
acceptance given in the same round the claim was raised settles it at the end of that round. A settled
claim is not reopened.

## Outcomes

- **Converged** — no unresolved HOLD and no open QUESTION remain. The next round is the settled list,
  recorded as `settled.md`. That list is the input to the close procedure below, which distils it into a
  spec and distributes it; it is not the lasting record.
- **Terminated** — the user declares the debate over. Settled items stand and remain usable. Every
  unresolved HOLD and open QUESTION returns to the user with both positions preserved and neither winning.
- **Void** — the premise failed: one provider on both sides, or no shared verifiable ground. Nothing
  produced is usable.

A debate ends only by convergence or by the user declaring it terminated. No count of rounds or exchanges
closes it, and no disagreement resolves itself by lasting. Either participant may call void on provider
identity or absent verifiable ground.

Close `rounds.md` with exactly one stamp:

- `DEBATE: converged — [count] settled — [subject]`
- `DEBATE: terminated — [reason] — [count] settled, [count] open — [subject]`
- `DEBATE: void — [reason] — [subject]`

## Recording

While the debate runs, every artifact lives in `_sediment/debate-<subject>/` at the repository root. Both
participants read and write that exact path: a rendezvous both sides must find is a path, not a
description, and two participants who each pick their own scratch location run two monologues that never
meet. An unfinished debate is deliberation, which is what `_sediment/` is for.

The branch holds `index.md`, one `report-<product>.md` and one `cross-<product>.md` per participant,
`rounds.md`, and `settled.md`. Name leaf files by product - `report-codex.md`, `report-claude-code.md` -
so their paths remain stable for the whole debate.

## On close

A converged debate is consumed, not archived. Write the spec, place every settled item in the authority
that owns it, then delete the branch.

**Write the spec.** One document at `_sediment/<subject>-spec.md`, written to be implemented by someone
who was not in the debate: what is being built, how, what it deliberately does not do, and the order to
build it in. It carries the reasoning that decided each position and the measurements that settled the
contested ones. It does not carry who held what, who conceded, or in which round - that is process
residue, and a reader implementing the result has no use for it.

**Place every settled item.** Decisions and their reasons go to Rationale. Remaining work goes to State as
tickets. A dated entry goes to Build Log recording that the debate ran, between which products, over how
many rounds, and **what it measured** - counts, verified figures, defects found. Those measurements are
dated evidence and are the part of a debate worth keeping.

**Confirm the spec.** After the spec is written and every settled item is placed, the other participant
reads the spec and states whether it implements the settled items. A settled item whose measurement did not
survive into the spec is not implemented. Where it does not, the author revises and the other participant
re-checks what changed. The loop ends when both participants expressly agree the spec is correct; silence
agrees to nothing, and an author's own reading of its own document is not agreement. Record that agreement
in the spec, because the branch does not survive to carry it. Only then may the close procedure proceed.
Nothing detects a stalled confirmation either; only the user can end one, and a spec closed that way
carries its gaps into the record.

**Then delete the branch**: the reports, the cross-analyses, `rounds.md`, `settled.md` and `index.md`.

**Nothing is deleted until every settled item has a home.** An item with no destination was not settled;
it was agreed and forgotten. Check the placements before removing anything, because the branch is the only
copy.

A void debate produces no spec and no authority record.

## Limits

Nothing detects a stalled debate; only the user can restart or close one. Two capable agents exchanging
rounds is expensive: use DAP when one provider's scrutiny is enough.
