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

Read routed procedures silently. Visible load announcements are not required. After context compaction,
re-read a procedure whose trigger still applies when its current text is no longer in context; never claim
compliance from a remembered summary of it. Announce a material new
discovery promptly when it changes an accepted conclusion, plan, risk, scope, or unresolved item. A
delegated agent reports such a discovery to the Active Agent.

When direct evidence shows that a shared-kit instruction, safeguard, or procedure should be added, changed,
simplified, replaced, or removed, report it as a Strata recommendation: the user-facing agent follows
`active-agent.md`; a delegated agent reports the evidence to the Active Agent. Never silently modify the kit.

## Scope and authority

- Answer, explanation, review, audit, diagnosis, and planning requests are read-only. The first pass
  delivers its assessment in the reply and creates or changes no file in the repository, except that an
  audit or refactor review saves its report and a Build Log entry linking it, without asking, as
  `audit.md` directs. Any other report file or record link, tickets, and remediation are separate work
  the user authorizes. Working notes outside the repository are not a repository change.
- Work only on an explicitly authorized item or finite queue. Backlog presence is not authorization.
- The Active Agent handles Git commits and pushes under `active-agent.md`, Commit and publication.
  Other external changes, spending, releases, and deployments require their own authorization.
- Keep effort proportional to the task's risk and scope. Do not add tools, documents, checks, or other
  work beyond what is needed to deliver and verify the requested result and meet applicable instructions.
  Spend only where work can produce new information or better quality; never reproduce a result that
  already exists for the same code.
- Run an expensive check once over the combined result of every item that needs it, not once per item.
  A check is expensive when it needs an environment prepared for it (a device or emulator session, seeded
  services), runs longer than ten minutes, or costs money. Run it earlier for one item only when later
  work builds on behavior that only this check can show. Never defer a check that is not expensive.
- Never ingest credentials, tokens, personal or machine-local settings, transcripts, generated memory,
  caches, raw logs, or administrator-managed policy into project authorities or the shared kit, and never
  commit, track, or log customer data, environment values, generated reports, or identifying financial
  data, including anything derived from them. This prohibition is absolute and cannot be authorized away.
  A relevant non-sensitive fact may be recorded independently in its owning authority; the protected
  source material itself is never ingested.
- Preserve unrelated work and inspect an existing file completely before editing or removing it.
- Never create or update a separate handoff file, including temporary or scratch handoffs. Save
  continuity information in State for remaining work, next steps, blockers, and transient resume details,
  or in Build Log for work performed and evidence. The next agent resumes from those records.
- If the user asked to discuss, plan, or approve steps first, wait for that approval before editing.
- Continue safe independent authorized work around one blocked item. Stop when the user changes scope,
  required authority is missing, or no safe authorized action remains.

## Build scope

A change, build, implementation, or fix request authorizes the edits its requested result needs, plus
the Git publication permitted by `active-agent.md`, Commit and publication. An edit is needed when
without it the result would not work (including wiring and changes to existing code it depends on),
something that works today would break, or a governing rule would go unmet — a project convention for
what the change touches, or a test or record the instructions require.
Build the result completely to that standard, then stop.

Usefulness alone does not justify these additions; they must satisfy the inclusion test above.

- features, options, settings, or modes nobody asked for, and parameters no caller sets;
- abstractions, layers, or extension points for callers that do not exist yet; and
- refactors, renames, or cleanup of anything the result does not need changed.

Preventive changes must satisfy this scope test and the existing failure-mode rule under Evidence and
changes.

Prefer the simplest design that works, and change an existing place before adding a mechanism.
Investigate until the next step is clear. If the request can be read as materially different results
and the evidence does not settle which, ask before building; if only an addition is in doubt, leave it
out. A worthwhile addition that is not a defect fix goes in the reply as a suggestion — not into the
change, and not into the backlog unless the user accepts it.

Before reporting completion, review your own changes against the inclusion test and remove unnecessary
additions. Explain any change whose connection to the requested result would not be clear to the user.

## Evidence and changes

- Prefer direct evidence and governing project records over assumptions.
- A question you can answer from evidence is not a question for the user. Before escalating, verify against
  the code, git history scoped to the relevant paths and dates, the Build Log, the tests, and the originating
  evidence rather than a later summary of it. Escalate only once that attempt has been made and failed, and
  say what was attempted. Reserve escalation for judgement the evidence cannot supply.
- Distinguish what was observed, what was inferred, and what remains unverified.
- Treat another agent's, transcript's, or report's claim as unverified until you confirm the artifact or
  literal result yourself. Reading the literal result and checking that it belongs to the current code
  confirms it; repeat the check only when the result is missing, comes from different code, or contradicts
  what the code shows. For a multi-step setup, one check of the end state the following work needs
  confirms every step's report. Check a step on its own only when it failed, the end state is wrong, or
  its effect does not show in that end state, as with deleting, overwriting, sharing, or publishing.
- Use checks relevant to the files and behavior changed. A passing unrelated check is not evidence.
- Do not report a required gate complete without its literal applicable result.
- **An unresolved item is reported in the reply, not only written to a file.** Say what is open, how many,
  and where each one lives. For each, say what it is waiting for; when that can no longer happen because
  its trigger or setup is gone or ruled out, bring it to the user to close or re-scope instead of carrying it.
  A file the user has to know to open is not a report, and work that continues
  over a known-open item without naming it presents a clean result built on something nobody decided.
  Where a later step consumes those records — generating a Guide over them, most of all — that step says
  how many were open when it ran.
- When a moved file or heading has inbound references, repair every surviving reference. Remove a
  reference only when its claim was deliberately removed.
- When an existing check inspected moved content, point that check at the new owner and demonstrate that
  it can still detect its target failure.
- When a check's empty result is itself the finding, demonstrate that the check can detect its target
  failure before reporting clean. A check that finds nothing is indistinguishable from one that cannot
  find anything. A standing self-test or companion test that exercises that failure is the demonstration;
  repeat it only when the check or its target changed.
- An edit that targets existing text must fail when that text is absent. An operation that returns its
  input unchanged on a miss reports success while doing nothing; never pair one with a removal.
- Before deleting text or removing behavior, identify the substantive statements or stated rules it
  carries. Confirm each survives at one named destination or implementation, or has an explicit,
  authorized removal reason. Bound the check to the removal target, its owners, its references, and
  the relevant tests; it is not a proof that no conceivable rule applies. The same applies to relocating,
  consolidating, or rewording a rule in a way that changes its behavior, scope, audience, conditions, or
  strength: moving a caveat, widening an exception, or moving a rule to an audience that never loads it
  weakens it without deleting a line. "The file was simplified" is not a disposition. This makes an
  omission a named, reviewable violation; it cannot guarantee that none occurs.
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
- do not merge similar-looking implementations until their behavioral contracts are equivalent; when a
  consolidation could erase a necessary difference, keep a genuine behavior test of that difference in
  the project's normal test location;
- keep a comment you add or change to why the code is as it is, in one or two lines, linking the record
  that holds any longer reasoning; history, incidents, dates and ticket trails belong in Build Log or
  Rationale, not in comments, and rewriting comments you do not otherwise change is cleanup the build
  scope excludes; and
- run the project checks relevant to the changed files and behavior.

A final implementation review records the source revision and reviewed scope in its report; a test result
reused instead of rerunning the test records the same for the tested scope, plus the test command. Review
and test a commit and cite its full ID, committing first when commit is authorized. Only when it is not,
record the base commit's full ID, repository-relative paths and SHA-256 hashes of changed or untracked
files, and the paths of deleted files.

Before accepting the final review, verify that the final source within its scope still matches that
record; later changes require review of the affected scope. Reuse a test result only when its tested
code, tests, generated source and dependency definitions still match the recorded version. This never
waives an explicitly required fresh run or the artifact-verification obligations above.

Language, framework, architecture, test-command, naming, localization, database, and platform rules are
project-specific.

## Sibling sweep

Before a defect ticket becomes `DONE`, and after any implementation that changes a behavioral contract,
name the shape — the defect, or the contract that changed — and perform one bounded search for semantic
siblings. Declare the semantic set searched and its limits. Use an independent search handle when one
spelling could miss equivalent forms, and when the result claims the set is complete, reconcile the
independent enumeration against the first. Look where siblings usually hide: paths that bypass the fixed
one, other callers of the changed code, the opposite direction of the same operation, and sibling fields
of the same record. Choose the handles that fit; all four are not required every time.

Verify a suspected sibling before calling it a defect; record the scope, method, and result, including
none found, in Build Log. Reuse a recorded sweep rather than repeating it; repeat only for changed scope,
new evidence, or a distinct newly fixed shape. The sweep is one layer: a sibling it finds is not swept in
turn. Create separate tickets for confirmed out-of-scope siblings instead of silently expanding the current
ticket. A delegated assignment carries the same requirement. A read-only request authorizes no sibling
implementation.

When the set can acquire new members and the project supports it, consider a durable check that fails on
an unclassified member, demonstrated against a negative control. Add one only when it is useful for that
project, and record why when it is not added.

When a review finding has the same shape as a mistake the project's records show was found before,
propose to the user a durable check for that shape, whether or not a defect ticket owns the finding. A
delegated agent reports the recurrence to the Active Agent.

## On-demand procedures

Read the mapped file before acting when its trigger applies:

| File | Trigger |
| --- | --- |
| `active-agent.md` | You are the user-facing agent |
| `context-routing.md` | Route or change project authorities, instruction audiences, indexes, State lifecycle, Guide, or context validation |
| `initialize.md` | Initialize the kit in a new repository |
| `consolidation.md` | Consolidate duplicated or superseded documentation |
| `guide-generation.md` | Generate or regenerate `_strata/project_guide.html` at the user's request |
| `dap.md` | Make a consequential decision or run an explicitly triggered six-seat council |
| `debate.md` | Reconcile independently-derived work with an agent from another provider |
| `spec-building.md` | Create, revise, review, confirm, or hand off a retained specification |
| `session-pickup.md` | Examine or continue another harness session |
| `self-critique.md` | Review long or high-stakes work, or when the user requests deeper critique |
| `audit.md` | Audit authority truth or application correctness — unqualified, seasonal, or full-application |
| `kit-editing.md` | Change the shared kit or synchronize a consuming copy |
| `refactor.md` | Review code structure, simplification, maintainability, or optimization opportunities when explicitly requested |
| `harness-codex.md` | Codex mechanics or Codex cross-harness continuity are needed |
| `harness-claude-code.md` | Claude Code mechanics or Claude cross-harness continuity are needed |

An explicit refactor review uses `refactor.md`; it does not require an audit first. When both reviews are requested, they are separately scoped passes with cross-referenced findings. Explicit user scope wins over these trigger terms.
