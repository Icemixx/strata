# Universal Instructions

Shared, project-agnostic instructions for every supported agent. This file and `_strata/universal/`
are copied unchanged between repositories. Project-specific rules belong in
`_strata/project_instructions.md` and win on conflict.

If you are the user-facing agent, read `_strata/universal/active-agent.md` before substantive work. A
delegated agent does not read Active Agent Instructions; its assignment supplies the routed context it
needs.

## Startup and context

Instructions is the only authority loaded merely because a session starts. Do not automatically load
State, Rationale, Build Log, or the generated Guide. Route additional context under
`_strata/universal/context-routing.md` when the task needs it.

Read routed procedures silently. Visible load announcements are not required. Announce a material new
discovery promptly when it changes an accepted conclusion, plan, risk, scope, or unresolved item. A
delegated agent reports such a discovery to the Active Agent.

## Scope and authority

- Answer, explanation, review, diagnosis, and planning requests are read-only.
- Change, build, implementation, and fix requests authorize only the necessary in-scope local edits.
- Work only on an explicitly authorized item or finite queue. Backlog presence is not authorization.
- Editing never implies authority to commit, publish, spend money, change external state, or expand
  scope materially.
- Preserve unrelated work and inspect an existing file completely before editing or removing it.
- If the user asked to discuss, plan, or approve steps first, wait for that approval before editing.
- Continue safe independent authorized work around one blocked item. Stop when the user changes scope,
  required authority is missing, or no safe authorized action remains.

## Evidence and changes

- Prefer direct evidence and governing project records over assumptions.
- Distinguish what was observed, what was inferred, and what remains unverified.
- Treat another agent's, transcript's, or report's claim as unverified until you confirm the artifact or
  literal result yourself.
- Use checks relevant to the files and behavior changed. A passing unrelated check is not evidence.
- Do not report a required gate complete without its literal applicable result.
- When a moved file or heading has inbound references, repair every surviving reference. Remove a
  reference only when its claim was deliberately removed.
- When an existing check inspected moved content, point that check at the new owner and demonstrate that
  it can still detect its target failure.

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
| `dap.md` | Make a consequential decision or run an explicitly triggered six-seat council |
| `debate.md` | Reconcile independently-derived work with an Architect from another provider |
| `session-pickup.md` | Examine or continue another harness session |
| `self-critique.md` | Review long or high-stakes work, or when the user requests deeper critique |
| `seasonal-audit.md` | Perform a seasonal, full-application, or refactor audit |
| `kit-editing.md` | Change the shared kit or synchronize a consuming copy |
| `harness-codex.md` | Codex mechanics or Codex cross-harness continuity are needed |
| `harness-claude-code.md` | Claude Code mechanics or Claude cross-harness continuity are needed |
