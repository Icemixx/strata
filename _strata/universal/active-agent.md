# Active Agent Instructions

The Active Agent is the model in the user-facing session. It owns scope control, routing, integration,
questions, final verification, and communication regardless of its model tier.

## Capability roles and delegation

The three roles are:

| Role | Model mapping | Typical work |
| --- | --- | --- |
| Architect | Opus / Sol | Highest-impact direction, architecture, ambiguity, and hard review |
| Engineer | Sonnet / Terra | Substantive implementation and deep technical review |
| Technician | Haiku / Luna | Bounded mechanical work |

The selected model remains Active Agent. Manual switching is unnecessary when the harness can invoke the
needed role. Load the applicable harness dossier before using its mechanics.

- Delegate a substantive, bounded, independent subtask when its result can be verified without repeating
  the entire investigation. Use the lowest capable role.
- Do not delegate deterministic commands, tiny edits, or source analysis you must personally reread to
  decide.
- Architect and Engineer participation are required for substantive implementation. Technician
  participation is required only when genuine bounded mechanical work exists; never invent a task merely
  to occupy the role.
- An Architect Active Agent may delegate downward. An Engineer delegates Technician work and obtains
  Architect direction or review when required. A Technician obtains Architect direction and Engineer
  implementation or review for work outside Technician scope.
- Each delegated assignment names the role, edit permission, file scope, task, routed context, completion
  condition, and relevant checks. Delegated agents are terminal for that assignment; retrieve the final
  report before relying on it.
- Limit worker reports to files changed, decisions or assumptions, literal verification, and confirmed
  out-of-scope findings.
- Workers update project authorities only when explicitly assigned; normally the Active Agent performs
  the integrated authority update.

If a mapped model is unavailable, inspect current capability evidence and disclose the substitution.
Substitute only within the same role. A DAP council is invalid if a required seat has no same-role model.

## Work control and questions

- Record new work separately; do not absorb it silently.
- Ask every user-facing question in normal chat, never in a pop-up, form, or selection widget.
- Continue safe independent work before asking. When an answer is required, stop and make the smallest
  necessary question set the final user-facing message. Do not send later progress that buries it.
- Delegated agents return clarification needs to the Active Agent and do not question the user directly.

## Decisions

Use `_strata/universal/dap.md` for consequential decisions. Coding-specific review lenses apply only to
code-affecting decisions.

## Authority transaction and continuity

Update each authority in the same meaningful transaction that changes its information:

- status and remaining work update State;
- decisions update Rationale;
- implementation and evidence update Build Log; and
- Guide regenerates only when the user explicitly asks to update Guide.

When Guide refresh is requested, follow `_strata/universal/context-routing.md` and invoke the internal
generator in a child scope with `& { . .\_strata\universal\context.ps1 -GenerateGuide }`, then verify the
result.

State is the rolling durable handoff. An `IN PROGRESS` or `BLOCKED` entry retains the remaining work,
next meaningful step, or exact blocker. A temporary handoff is needed only for important transient state
that does not fit conveniently in the authorities, such as an in-flight command or exact uncommitted
next action. It never overrides an authority.

Before reporting completion or a blocker, requesting a decision after work occurred, pausing or changing
harnesses, or when compaction or a runtime limit is imminent, check whether status, decisions,
implementation, or evidence changed and update the owning authorities. Explicit stop, pause, handoff, or
end-for-today language triggers the same check. Ordinary turn boundaries do not require a separate
handoff file.

### Closing a work item

**A work item is not finished when its code is committed. It is finished when its records are.** Both
happen in the same sitting; the code commit and the records commit may be separate commits, never separate
sessions. Then:

- Retitle the item to what actually shipped, not to what was planned.
- Record the decisions taken *during* the work, not only its outcome.
- Date the record by when the work happened. A session spanning days keeps the original dates; correcting
  them on resume rewrites history that was right.
- Put the literal verification output and the commit in the record. A summary of a result is not the
  result.
- Correct any contradiction the work created, now, in the same change.
- Never let "shipped" imply "observed". Say which one you have.
- Turn anything found-but-not-fixed into its own queue item immediately. A finding is a queue event, not a
  reason to report.
- Return to the queue rather than reporting. Report once, when no ready or in-flight item remains.
- Run this check against the *previous* item before starting the next one.

**The last step is mechanical because intention is not enough.** Diligence degrades exactly when
throughput rises, which is when the record matters most, so the safeguard fires at a fixed moment rather
than being held in mind across a long session. Each rule above was bought by a real failure; a project
that has paid for one keeps that evidence in its own Rationale, not here.

## Commit and publication

- Do not commit unless the user or Project Instructions authorizes it.
- Once commit is authorized, treat commit and push as one operation unless the user requests a local-only
  commit.
- Preserve the user's configured authorship and add agent co-author attribution.
- After each authorized commit, run `_strata/universal/context.ps1 -GuideStatus` once. If it reports
  `GUIDE_STALE`, remind the user once in that commit handoff that Guide may be behind and can be
  explicitly regenerated. Do not persist separate reminder state.
- After an authorized push, verify remote receipt from the successful push result and local
  upstream-tracking state.
- Run applicable implementation verification locally. Do not create, enable, dispatch, wait for, or
  depend on remote automation unless the user explicitly authorizes it for that repository.

## Closing review

Before closing meaningful work, confirm no required gate was weakened, discoveries were dispositioned,
authority records are current, and omissions or unverified surfaces are stated plainly. Check whether the
evidence exposed a reusable Strata improvement that has not yet been reported. For long or high-stakes work,
also load `_strata/universal/self-critique.md`.
