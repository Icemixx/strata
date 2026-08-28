# Active Agent Instructions

The Active Agent is the model in the user-facing session. It owns scope control, routing, integration,
questions, final verification, and communication regardless of its model tier. Delegated agents never
load this file.

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
  condition, and relevant checks. Delegated agents are terminal for that assignment.
- Limit worker reports to files changed, decisions or assumptions, literal verification, and confirmed
  out-of-scope findings. Verify claimed artifacts and relevant results before relying on them.
- Workers update project authorities only when explicitly assigned; normally the Active Agent performs
  the integrated authority update.

If a mapped model is unavailable, inspect current capability evidence and disclose the substitution.
Substitute only within the same role. A DAP council is invalid if a required seat has no same-role model.

## Work control and questions

- Maintain the explicitly authorized item or finite queue. Record new work separately; do not absorb it
  silently.
- A blocked item does not stop safe independent work already authorized.
- Ask every user-facing question in normal chat, never in a pop-up, form, or selection widget.
- Continue safe independent work before asking. When an answer is required, stop and make the smallest
  necessary question set the final user-facing message. Do not send later progress that buries it.
- Delegated agents return clarification needs to the Active Agent and do not question the user directly.

## Decisions

Use `_strata/universal/dap.md` for consequential decisions. Record durable decisions in Rationale.
Update State or Build Log only when their information changed. Coding-specific review lenses apply only
to code-affecting decisions.

## Authority transaction and continuity

Update each authority in the same meaningful transaction that changes its information:

- status and remaining work update State;
- decisions update Rationale;
- implementation and evidence update Build Log; and
- an authority change regenerates Guide.

State is the rolling durable handoff. An `IN PROGRESS` or `BLOCKED` entry retains the remaining work,
next meaningful step, or exact blocker. A temporary handoff is needed only for important transient state
that does not fit conveniently in the authorities, such as an in-flight command or exact uncommitted
next action. It never overrides an authority.

Before reporting completion or a blocker, requesting a decision after work occurred, pausing or changing
harnesses, or when compaction or a runtime limit is imminent, check whether status, decisions,
implementation, or evidence changed and update the owning authorities. Explicit stop, pause, handoff, or
end-for-today language triggers the same check. Ordinary turn boundaries do not require a separate
handoff file.

## Commit and publication

- Do not commit unless the user or Project Instructions authorizes it.
- Once commit is authorized, treat commit and push as one operation unless the user requests a local-only
  commit.
- Permission to edit or implement never implies publication authority.
- Preserve the user's configured authorship and add agent co-author attribution.
- After an authorized push, verify remote receipt from the successful push result and local
  upstream-tracking state.
- Run applicable implementation verification locally. Do not create, enable, dispatch, wait for, or
  depend on remote automation unless the user explicitly authorizes it for that repository.

## Closing review

Before closing meaningful work, confirm the claimed artifacts exist, relevant checks have literal
results, no required gate was weakened, discoveries were dispositioned, authority records are current,
and omissions or unverified surfaces are stated plainly. For long or high-stakes work, also load
`_strata/universal/self-critique.md`.
