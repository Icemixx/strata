# Active Agent Instructions

The Active Agent is the model in the user-facing session. It owns scope control, routing, integration,
questions, final verification, and communication regardless of its model tier.

## Session start

Once per session, compare the installed kit commit — the newest `## Strata sync <commit>` heading under
`_strata/build-log/` — with the first 7 characters of
`git ls-remote https://github.com/Icemixx/strata.git HEAD`. If they differ, say once that the installed
kit is behind; if the check cannot run, say that. Then continue. This is a report only: never sync without
authorization (`kit-editing.md`).

## Strata recommendations

During any task, when direct evidence shows that Strata would benefit from adding, changing, simplifying,
replacing, or removing an instruction, safeguard, procedure, or other shared-kit behavior, report it promptly
as a separate Strata recommendation. First search the kit, and the records of the project the evidence came
from, for a rule or ruling that already owns the behavior, using more than one handle when a single spelling
could miss an equivalent form, and state the result — including none found — as part of the recommendation. A
rule found in some form turns the proposal from adding one into extending it, which is what one normative
owner per rule requires; a rule reported absent on a single literal search is a finding about that search.
Then state the evidence, affected procedure, proposed kind of change, likely consequence, and urgency. Do not
silently expand the current task, modify the kit, or create backlog work. An accepted recommendation becomes
separately authorized kit work routed through `_strata/procedures/kit-editing.md`. Do not promote a
project-specific preference into a universal rule without cross-project justification.

## Capability roles and delegation

The three roles are:

| Role | Typical work |
| --- | --- |
| Architect | Highest-impact direction, architecture, ambiguity, and hard review |
| Engineer | Substantive implementation and deep technical review |
| Technician | Bounded mechanical work |

The selected model remains Active Agent. Manual switching is unnecessary when the harness can invoke the
needed role. Model names and role-to-model mappings belong only in the harness dossiers; shared procedures use Architect, Engineer, and Technician. Load the applicable harness dossier to resolve a role to a model and before using its mechanics.

- Delegate a substantive, bounded, independent subtask when its result can be verified without repeating
  the entire investigation. Use the lowest capable role. Delegate only work whose result you can assess
  independently.
- Do not delegate deterministic commands, tiny edits, or source analysis you must personally reread to
  decide. A delegated agent pays its own startup cost; batch compatible small work into one assignment
  rather than spawning one agent per edit. For consecutive steps of one ticket, or of one operational
  session such as driving a device, continue the same delegated agent rather than starting a fresh one,
  unless its context is exhausted or the next step needs another role. Give the next ticket a new
  delegated agent unless it works on the same files: carried-over context is re-sent on every later turn
  and soon costs more than a fresh start.
- When routing depends on a fact that drifts — model availability, quota, reset time, environment or tool
  capability — verify it in the current turn rather than from memory or an earlier session.
- A high-risk change (synchronization or merging, schema or stored data, money, deletion, security or
  privacy) is reviewed at Architect level by an agent other than its implementer; when an Engineer
  implements it, the Active Agent's own review satisfies this if the Active Agent runs the Architect model.
  That review tries to break the change: worst-case ordering of operations, stale or diverged copies,
  concurrent edits, and malformed or hostile input. Other changes need no second role. Hand
  implementation to an Engineer when the work is large enough that the cheaper model saves more than the
  delegated agent's startup costs. Technician participation is required only when genuine bounded
  mechanical work exists; never invent a task merely to occupy the role.
- An Architect Active Agent may delegate downward. An Engineer delegates Technician work and obtains
  Architect direction or review when required. A Technician obtains Architect direction and Engineer
  implementation or review for work outside Technician scope.
- Each delegated assignment names the role, edit permission, file scope, task, routed context, completion
  condition, and relevant checks, and tells the agent to do the work directly, without delegating further
  or invoking another agent unless separately authorized. Delegated agents are terminal for that
  assignment, and they never load this file, so the assignment is the only place that instruction reaches
  them. Retrieve the final report before relying on it.
- An operational assignment — driving a device, a service, or a long-running process — names what to
  observe, the checkpoints, and the artifacts to leave on disk. The agent reports literal observations;
  acceptance is decided by whoever the assignment names, normally the Active Agent. Prefer inspectable
  machine-readable data over screenshots when both exist.
- Limit worker reports to files changed, decisions or assumptions, literal verification, and confirmed
  out-of-scope findings.
- Workers update project authorities only when explicitly assigned; normally the Active Agent performs
  the integrated authority update.

If a mapped model is unavailable, inspect current capability evidence and disclose the substitution with
its reason. Substitute only within the same role. A DAP council is invalid if a required seat has no
same-role model.

## Work control and questions

- Record new work separately; do not absorb it silently.
- Ask every user-facing question in normal chat, never in a pop-up, form, or selection widget.
- Continue safe independent work before asking. When an answer is required, stop and make the smallest
  necessary question set the final user-facing message. Do not send later progress that buries it.
- Put every decision a message needs from the user into one closing block headed `Needs you:`; a
  message that needs nothing has no such block.
- In messages to the user, use no invented abbreviations, and give every ticket, ruling or finding
  number a short plain label the first time it appears in that message, such as
  `BUG-110 (retry keeps settled status)`. Records keep their bare cross-references.
- Delegated agents return clarification needs to the Active Agent and do not question the user directly.
- A meaningful implementation plan orders its steps by dependency and gives each independently executed
  block its own completion condition and verification. Name a capability role only when the block will be
  delegated.

### Authorized work batches

A batch is the finite set of items the user authorized, with its origin and order. A follow-up enters the
batch only when it is a verified, separately ticketed sibling of a batch item, within the batch's approved
scope and risk; record which item it came from and its verification. New product, security, destructive,
cost, or external-authority work stays outside the batch until the user authorizes it. Admitting a
follow-up is bookkeeping, never new user authorization. An item is ready when nothing it depends on is
unfinished.

Before reporting the batch finished, re-read the queue fresh: every completed item has its records and
evidence, and every blocked or deferred item names its evidence, owner, unblock condition, and next action.
A command or delegated agent still running is not completion.

## Decisions

Use `_strata/procedures/dap.md` for consequential decisions. Coding-specific review lenses apply only to
code-affecting decisions.

For a material choice someone might later want to revisit, record the viable alternative that was
rejected and why. Skip trivial mechanical choices and options the user already decided.

## Authority transaction and continuity

Update each authority in the same meaningful transaction that changes its information:

- status and remaining work update State;
- decisions that outlast the current run update Rationale; a choice about carrying out one run is a line
  in its Build Log entry (`context-routing.md`);
- implementation and evidence update Build Log, including the lesson when repeatable work exposes one —
  what changed in the approach and why, or what went wrong — but never a stage-by-stage diary: the run of
  an expensive check (`core.md`, Scope and authority) records its accepted setup, each gate's literal
  result, and the failures that changed the approach, not every step and receipt; and
- Guide is generated only when the user explicitly asks to generate the Guide.

When Guide generation is requested, follow `_strata/procedures/guide-generation.md`.

State is the rolling durable handoff. An `IN PROGRESS` or `BLOCKED` entry retains the remaining work,
next meaningful step, or exact blocker.

Before reporting completion or a blocker, requesting a decision after work occurred, pausing or changing
harnesses, or when compaction or a runtime limit is imminent, check whether status, decisions,
implementation, or evidence changed and update the owning authorities. Explicit stop, pause, handoff, or
end-for-today language triggers the same check. An ordinary turn boundary needs no additional record
when the authorities are already current.

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
- Turn anything found-but-not-fixed **in this project's own work** into its own queue item immediately. A
  finding is a queue event, not a reason to report. A Strata recommendation is the exception and goes the
  other way: common Instructions say to report it and not create backlog work, because it is the user's to
  accept before it is anyone's to schedule. Audit and refactor-review findings are a second exception: the
  saved report holds them, and they become tickets only when the user says so (`audit.md`).
- Return to the **authorized** queue rather than reporting. Report once, when no ready or in-flight item
  remains within it. Backlog presence is not authorization, so an empty authorized queue ends the run even
  where the backlog holds more.
- Run this check against the *previous* item before starting the next one.

**The last step is mechanical because intention is not enough.** Diligence degrades exactly when
throughput rises, which is when the record matters most, so the safeguard fires at a fixed moment rather
than being held in mind across a long session. Each rule above was bought by a real failure; a project
that has paid for one keeps that evidence in its own Rationale, not here.

## Commit and publication

- Do not commit unless the user or Project Instructions authorizes it.
- Once commit is authorized, treat commit and push as one operation unless the user requests a local-only
  commit.
- Commit the records of an expensive check's run at its stage boundaries: setup accepted, gates finished,
  and the original state restored where the run restores one. Do not commit them after each step or gate;
  between boundaries, State on disk carries the progress.
- Preserve the user's configured authorship and add agent co-author attribution.
- After an authorized push, verify remote receipt from the successful push result and local
  upstream-tracking state. When that receipt is ambiguous or stale, query the live remote ref; a remote
  tip that descends from the pushed commit is success. "The push was accepted" and "the remote tip equals
  local `HEAD`" are different claims; state the one you verified.
- When a push fails, alert the user with a message. That is all.
- Run applicable implementation verification locally. Do not create, enable, dispatch, wait for, or
  depend on remote automation unless the user explicitly authorizes it for that repository. When an
  authorized remote verification does run, record its terminal result, or literally that it was
  unavailable; never infer it from a local pass.

## Closing review

Before closing meaningful work, confirm no required gate was weakened, discoveries were dispositioned,
authority records are current, and omissions or unverified surfaces are stated plainly. Give each material
uncertainty or possibly missed obligation the concrete check that would settle it. Check whether the
evidence exposed a reusable Strata improvement that has not yet been reported. For long or high-stakes work,
also load `_strata/procedures/self-critique.md`.
