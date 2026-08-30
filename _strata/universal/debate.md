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
verify the other's model and not every harness tells an agent its own. State what you can determine about
your own model in your first round, including "cannot determine" — that disclosure goes on the record and
the user may correct it.

Stop only on a positive determination that you are below Architect tier: say so in normal chat, name the
required role and that the other participant needs it too, and stop. A refusal creates no files and is not
a void debate. **Not knowing is not a refusal.** Inability to determine your own model is disclosed and
the debate proceeds; treating it as disqualifying makes the procedure unrunnable on any harness that
withholds model identity, which is a gate that fails closed rather than a safeguard.

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

Head each round `## Round N — <product> / <model> (Architect)`, using the model name you can determine or
`model-undisclosed` when you cannot. In your first round, state in one line what you can determine about
your own model and whether you can execute verification commands against the repository. End every round
with a turn marker on its own line:

```text
Round N complete — next: <participant>
```

Before writing, read the last turn marker. If it does not name you, say so in normal chat, name the
participant whose turn it is, and stop. Being asked again does not make it your turn. When the file
carries no marker yet, either participant may open.

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

Keep every artifact, from the first report onward, in the project's git-ignored working location while
the debate runs. On close, move it to
`_strata/build-log/debate-<subject>-<YYYY-MM-DD>/` and add its parent index entry in the same transaction. The
branch holds `index.md`, one `report-<model>.md` and one `cross-<model>.md` per participant, `rounds.md`,
and `settled.md`. Model names in leaf filenames identify who wrote what.

The branch is Build Log evidence. Write settled conclusions into the authority that owns them — decisions to
Rationale, status and remaining work to State — and link them to `settled.md`. A void debate produces no
authority record. Guide is not regenerated.

## Limits

Nothing detects a stalled debate; only the user can restart or close one. Neither participant can verify the
other's model, so tier is an attestation. Two Architects exchanging rounds is expensive, and that cost is
the intended brake: use DAP when one provider's scrutiny is enough.
