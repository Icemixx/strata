# Debate

Use this procedure to reconcile independently-derived work with an Architect from a different provider.
A DAP council's seats share one provider and therefore one prior: it scrutinizes reasoning well and shared
blind spots poorly. Debate breaks that correlation. Two participants from the same provider are a council,
not a debate.

## Preconditions

Both participants are Architect. `active-agent.md` and the harness dossiers own the role-to-model mapping;
this procedure does not restate it. Substitution follows the DAP rule: same role only, disclosed, and no
same-role model means the procedure cannot run.

Check your own model before anything else. If you are not Architect, or cannot determine your model, say so
in normal chat, name the required role and that the other participant needs it too, and stop. A refusal
creates no files and is not a void debate.

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

Head each round `## Round N — <product> / <model> (Architect)`. In your first round, state in one line
whether you can execute verification commands against the repository.

Tag every position `CONCEDE`, `HOLD`, `NEW`, or `QUESTION`. A HOLD carries evidence, not restatement, and is
dropped when repeated without new evidence. Verify a contested claim yourself instead of accepting another
participant's measurement, including your own from an earlier round. Distinguish a factual conflict from a
severity, scope, or coverage difference; collapsing them wastes rounds. Concede only what the evidence
requires, because an unearned concession corrupts the settled record as much as a wrong claim.

A claim left uncontested for two consecutive rounds is settled and is not reopened. A claim raised and
expressly accepted within one round settles at the end of that round. Stop at five rounds.

## Outcomes

- **Converged** — no unresolved HOLD and no open QUESTION remain. The next round is the settled list.
- **Dissent** — a HOLD survives three exchanges without new evidence on either side. Record both positions;
  neither wins; the item becomes an open question for the user.
- **Terminated** — the user declares a participant unreachable. Settled items stand and remain usable; open
  items return to the user.
- **Void** — the premise failed: one provider on both sides, role drift, or no shared verifiable ground.
  Nothing produced is usable.

Either participant may call void on role drift, provider identity, or absent verifiable ground. Only the
user can call a false attestation or declare a participant unreachable; no agent can see another provider's
runtime.

Close the file with exactly one stamp:

- `DEBATE: converged — [count] settled — [models] — [subject]`
- `DEBATE: dissent on [topics] — [count] settled, [count] dissenting — [models] — [subject]`
- `DEBATE: terminated — [participant] unreachable — [count] settled, [count] open — [models] — [subject]`
- `DEBATE: void — [reason] — [models] — [subject]`

## Recording

Keep the debate in the project's git-ignored working location while it runs. On close, move it to
`_strata/build-log/debate-<subject>-<date>/` and add its parent index entry in the same transaction. The
branch holds `index.md`, one `report-<model>.md` and one `cross-<model>.md` per participant, `rounds.md`,
and `settled.md`. Model names in leaf filenames identify who wrote what.

The branch is Build Log evidence. Write settled conclusions into the authority that owns them — decisions to
Rationale, status and remaining work to State — and link them to `settled.md`. A void debate produces no
authority record. Guide is not regenerated.

## Limits

Nothing detects a stalled debate; only the user can restart or close one. Neither participant can verify the
other's model, so tier is an attestation. Five rounds of two Architects is expensive, and that cost is the
intended brake: use DAP when one provider's scrutiny is enough.
