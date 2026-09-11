# Universal Instructions

Shared, project-agnostic instructions for every supported agent. This file and `_strata/procedures/`
are copied unchanged between repositories. Project-specific rules belong in
`_strata/project_instructions.md` and win on conflict.

If you are the user-facing agent, read `_strata/procedures/active-agent.md` before substantive work. A
delegated agent does not read Active Agent Instructions; its assignment supplies the routed context it
needs.

## Startup and context

Instructions is the only authority loaded merely because a session starts. Do not automatically load
State, Rationale, Build Log, or the generated Guide. Route additional context under
`_strata/procedures/context-routing.md` when the task needs it.

Read routed procedures silently. Visible load announcements are not required. Announce a material new
discovery promptly when it changes an accepted conclusion, plan, risk, scope, or unresolved item. A
delegated agent reports such a discovery to the Active Agent.

During any task, when direct evidence shows that Strata would benefit from adding, changing, simplifying,
replacing, or removing an instruction, safeguard, procedure, or other shared-kit behavior, report it promptly
as a separate Strata recommendation. First search the kit for a rule that already owns the behavior, using
more than one handle when a single spelling could miss an equivalent form, and state the result — including
none found — as part of the recommendation. A rule found in some form turns the proposal from adding one
into extending it, which is what one normative owner per rule requires; a rule reported absent on a single
literal search is a finding about that search. Then state the evidence, affected procedure, proposed kind of
change, likely consequence, and urgency. Do not silently expand the current task, modify the kit, or create
backlog work. An accepted recommendation becomes separately authorized kit work routed through
`_strata/procedures/kit-editing.md`. Do not promote a project-specific preference into a universal rule without
cross-project justification.

## Scope and authority

- Answer, explanation, review, diagnosis, and planning requests are read-only.
- Change, build, implementation, and fix requests authorize only the necessary in-scope local edits.
- Work only on an explicitly authorized item or finite queue. Backlog presence is not authorization.
- Editing never implies authority to commit, publish, spend money, change external state, or expand
  scope materially.
- Never ingest credentials, tokens, personal or machine-local settings, transcripts, generated memory,
  caches, raw logs, or administrator-managed policy into project authorities or the shared kit, and never
  commit, track, or log customer data, environment values, generated reports, or identifying financial
  data, including anything derived from them. This prohibition is absolute and cannot be authorized away.
  A relevant non-sensitive fact may be recorded independently in its owning authority; the protected
  source material itself is never ingested.
- Preserve unrelated work and inspect an existing file completely before editing or removing it.
- If the user asked to discuss, plan, or approve steps first, wait for that approval before editing.
- Continue safe independent authorized work around one blocked item. Stop when the user changes scope,
  required authority is missing, or no safe authorized action remains.

## Evidence and changes

- Prefer direct evidence and governing project records over assumptions.
- A question you can answer from evidence is not a question for the user. Before escalating, verify against
  the code, git history scoped to the relevant paths and dates, the Build Log, the tests, and the originating
  evidence rather than a later summary of it. Escalate only once that attempt has been made and failed, and
  say what was attempted. Reserve escalation for judgement the evidence cannot supply.
- Distinguish what was observed, what was inferred, and what remains unverified.
- Treat another agent's, transcript's, or report's claim as unverified until you confirm the artifact or
  literal result yourself.
- Use checks relevant to the files and behavior changed. A passing unrelated check is not evidence.
- Do not report a required gate complete without its literal applicable result.
- **An unresolved item is reported in the reply, not only written to a file.** Say what is open, how many,
  and where each one lives. A file the user has to know to open is not a report, and work that continues
  over a known-open item without naming it presents a clean result built on something nobody decided.
  Where a later step consumes those records — generating a Guide over them, most of all — that step says
  how many were open when it ran.
- When a moved file or heading has inbound references, repair every surviving reference. Remove a
  reference only when its claim was deliberately removed.
- When an existing check inspected moved content, point that check at the new owner and demonstrate that
  it can still detect its target failure.
- When a check's empty result is itself the finding, demonstrate that the check can detect its target
  failure before reporting clean. A check that finds nothing is indistinguishable from one that cannot
  find anything.
- An edit that targets existing text must fail when that text is absent. An operation that returns its
  input unchanged on a miss reports success while doing nothing; never pair one with a removal.
- Before deleting text or removing behavior, identify the substantive statements or stated rules it
  carries. Confirm each survives at one named destination or implementation, or has an explicit,
  authorized removal reason. Bound the check to the removal target, its owners, its references, and
  the relevant tests; it is not a proof that no conceivable rule applies.
- Before adding behavior whose sole or primary purpose is to prevent a failure, and which is not
  already required by governing text, name the credible failure mode and the evidence for it. Make
  that evidence proportional to the behavior's breadth, cost, reversibility, and maintenance burden,
  weighed against the failure's likelihood and consequence. Prefer an observed failure or executed
  counterexample; a reasoned failure is admissible when its mechanism is credible and the preventive
  behavior is proportionate. This does not require separate justification for ordinary functionality
  directly required by the task or its governing contract.

For code changes only:

- verify referenced imports, symbols, resources, and keys exist before relying on them;
- reuse an existing implementation when it owns the same contract;
- do not merge similar-looking implementations until their behavioral contracts are equivalent; and
- run the project checks relevant to the changed files and behavior.

Language, framework, architecture, test-command, naming, localization, database, and platform rules are
project-specific.

## Defect completion sweep

Before a defect ticket becomes `DONE`, name the defect shape and perform one bounded search for semantic
siblings. Use an independent search handle when one spelling could miss equivalent forms. Verify a
suspected sibling before calling it a defect; record the scope, method, and result, including none found,
in Build Log. Create separate tickets for confirmed out-of-scope siblings instead of silently expanding
the current ticket. A delegated defect assignment carries the same requirement. A permanent gate is
added only when it is useful for that project.

## On-demand procedures

Read the mapped file before acting when its trigger applies:

| File | Trigger |
| --- | --- |
| `active-agent.md` | You are the user-facing agent |
| `context-routing.md` | Route or change project authorities, instruction audiences, indexes, State lifecycle, Guide, or context validation |
| `initialize.md` | Initialize the kit in a new repository |
| `consolidation.md` | Consolidate duplicated or superseded documentation |
| `guide-composition.md` | Write or refresh `_strata/project_guide.md`, the Guide's composition source |
| `dap.md` | Make a consequential decision or run an explicitly triggered six-seat council |
| `debate.md` | Reconcile independently-derived work with an agent from another provider |
| `spec-building.md` | Create, revise, review, confirm, or hand off a retained specification |
| `session-pickup.md` | Examine or continue another harness session |
| `self-critique.md` | Review long or high-stakes work, or when the user requests deeper critique |
| `audit.md` | Audit the application, the authority records, or both — seasonally, before a refactor, or after a conversion |
| `kit-editing.md` | Change the shared kit or synchronize a consuming copy |
| `harness-codex.md` | Codex mechanics or Codex cross-harness continuity are needed |
| `harness-claude-code.md` | Claude Code mechanics or Claude cross-harness continuity are needed |
