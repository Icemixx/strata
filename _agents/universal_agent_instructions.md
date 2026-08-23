# Universal Agent Instructions

Harness-agnostic working protocol for AI coding agents (Claude Code, Codex, Copilot, or any other). The verbatim drop-in unit is **this file plus the `_agents/universal/` folder — identical across all repositories, never edited per-project.** This core stays always-loaded and minimal; procedures needed only on specific triggers live in `_agents/universal/` and are loaded on demand via the **On-demand file map** at the end (restructured 2026-07-26 for context economy — the always-loaded set is deliberately the smallest set of high-signal rules). Repository setup and the rationale for the `_agents/` location: `_agents/universal/initialize.md`.

> ## ⚠️ STOP — editing THIS file or `_agents/universal/*` changes EVERY repository
>
> **This file and everything in `_agents/universal/` are a shared, verbatim, cross-repo unit. The copy you
> are editing is one of many. Git will only ever carry the change into the repo you are standing in —
> every other repo keeps the old text and silently drifts.**
>
> ### The canonical home is its own repository
>
> **`https://github.com/Icemixx/universal_agent_kit`** holds the master copy (added 2026-07-29). Its
> layout mirrors a consuming repo: `_agents/universal_agent_instructions.md` + `_agents/universal/*`.
> Every project repository holds a COPY. That canonical repository is the source of truth.
>
> **That repository is PUBLIC and its history is permanent.** Commit to it with a GitHub `users.noreply`
> author address, never a personal one, and keep the message about the RULE and the SHAPE of the failure
> — never the private repository it was found in, its ticket ids, its internal tool names, or the user's
> words. The incident that motivates a kit rule is by construction a private-repo incident; say what the
> rule prevents, not where it was learned.
>
> **On ANY change to the kit, in ANY repo, that repository MUST be updated in the SAME turn.** Do not
> leave it for later and do not leave it to the user to mirror by hand: an edit that lands only in the
> project repo you happen to be standing in is exactly the silent drift this banner exists to prevent.
> The agent PUSHES the change to the canonical repo, then TELLS the user which repos now need to pull.
>
> ### Syncing a project repo FROM the canonical repo
>
> Trigger: "sync the universal kit", "update the agent files", or equivalent. Project repos hold
> **copies**, not submodules or remotes — there is no `git pull` relationship with the canonical repo, so
> "pull" here means copy-and-commit:
>
> 1. `git clone --depth 1 https://github.com/Icemixx/universal_agent_kit` into a scratch/temp directory
>    — never inside the project repo.
> 2. Copy its `_agents/universal_agent_instructions.md` and the ENTIRE `_agents/universal/` folder over
>    the project's copies. **Never touch `_agents/project_*.md`** — those are project-owned and are not
>    part of the kit.
> 3. Hash-compare the copies to confirm (normalise `\r\n` → `\n` first), then commit in the project repo,
>    naming the canonical commit you synced from. Report which files actually changed.
>
> Line endings are handled by the canonical repo's `.gitattributes` (`* text=auto eol=lf`), so the kit
> normalises identically on every machine and in every repo. Compare CONTENT, not bytes: a project repo
> may legitimately check the copies out with different endings, which is why step 3 normalises first.
>
> Therefore, whenever you modify this file or ANY file in `_agents/universal/`, you **MUST**:
>
> 1. **Push the identical change to `universal_agent_kit` in the same turn**, then **tell the user
>    explicitly, in your final message of that turn**, that the shared kit changed and which repositories
>    now need to pull. Not only in a commit message, and never buried in a list of project changes.
> 2. **Name the exact files changed and quote the before/after of each edit**, so the change can be
>    reviewed without re-deriving anything or diffing by hand.
> 3. **Never make such an edit as an incidental side effect** of project work. If a project task seems to
>    require changing the shared kit, say so and get the user's go-ahead first — a project-specific need
>    almost always belongs in `project_instructions.md` instead (which wins on conflict anyway).
> 4. **Verify sync rather than assuming it.** Checking is seconds:
>    `git clone --depth 1 https://github.com/Icemixx/universal_agent_kit` into a scratch dir and
>    hash-compare each file against the local copy. Normalise line endings (`\r\n` → `\n`) before
>    hashing, or a CRLF checkout difference reads as a false mismatch. Note `gh` may not be installed;
>    plain `git` is enough.
>
> Rationale, and why this warning exists at the top where it is re-read every session: on 2026-07-28 a
> session corrected a genuine self-contradiction in this file (two file descriptions still said
> "append-only" after that rule had been repealed) and reported it as one bullet inside a large
> project-cleanup summary. The fix was right; the silence was not. The user only found out by asking. A
> shared file changed in one repo and nowhere else is worse than the contradiction it fixed, because
> nothing will ever surface the divergence.

## Project instructions file

Every repository has its own **`_agents/project_instructions.md`** (an older repo may still keep it elsewhere — the router names it). **Read it before starting work.** It holds mandatory agent conduct, protocol parameters, enforcement rules, and pointers. It may enforce a technical boundary, but links to the Guide rather than becoming a competing architecture or workflow manual. Where it conflicts with this file or any `_agents/universal/` file, the project file wins.

The project file also defines the **protocol parameters** referenced below. If one is missing, ask — or fall back to an evident repo convention:

- `REFERENCE_PLAN` — the project's three reference records (defaults: `_agents/project_state.md`, `_agents/project_rationale.md`, `_agents/project_build_log.md`; see Five project authorities).
- `TECHNICAL_GUIDE` — the mandatory current technical Guide (default: `_agents/project_guide.html`).
- `HANDOFF_FILE` — git-ignored scratch location for session handoffs (never committed).
- `TEST_SUITE` — permanent test location and how to run it.
- `DAP_EXTRA_LENSES` — additional project-specific DAP review lenses.
- `AUDIT_ADDENDUM` — the project's stack-specific checklist for the Seasonal Full-App Audit.

## Five project authorities

Every repository keeps five separate authorities. `REFERENCE_PLAN` is exactly the three Markdown memory records — State, Rationale, and Build Log — and must never include or substitute for `TECHNICAL_GUIDE`.

| Authority | Owns |
| --- | --- |
| Guide | Current software architecture, behavior, operator/developer technical workflows, technical conventions, and intrinsic limitations. |
| State | Current reality, scope, active backlog, priorities, approvals, unresolved defects or limitations needing work, and acceptance gates. |
| Rationale | Settled why, rejected alternatives, and explicit reopening conditions. An unresolved decision remains State until settled. |
| Build Log | Dated actions, commands actually run, and exact observed results/evidence. |
| Instructions | Mandatory agent conduct, protocol parameters, enforcement rules, and pointers to the Guide. |

At session start, before touching code, read the State file through EOF — its archive, if one exists, is deliberately NOT part of that read (see below) — the settled Rationale register, and the newest complete dated Build Log entries (tail-first for large logs is acceptable), then the task-relevant Guide sections. Read any memory files as well. Do not rely only on a first tool-sized page. Update the Guide in the same change whenever shipped behavior, architecture, schema, convention, workflow, or an intrinsic limitation changes. Read `_agents/universal/project-guide.md` before creating a Guide or adopting this model in an existing repository.

The State file is updated in place and date-stamped: it contains the Current Reality snapshot, scope and guardrails, active ticket/todo work in the B6 grammar, planned acceptance checks, and any Definition-of-Done checklist. **State delegates closed-item detail to its archive, `_agents/project_state_archive.md`, from the start** — the file is created at initialization rather than retrofitted, because retrofitting is the expensive part. The archive is a subordinate appendix, not a sixth authority, and is deliberately NOT part of `REFERENCE_PLAN`: State keeps one compact line per closed item — identifier, title, status, date, the commit that shipped it, and where its evidence lives — and the archive holds only the moved detail. **It is never read at session start**, only when a specific closed item is actually in question, and State wins on any conflict. **Check what the move does to every mechanical check that reads State, and note that the two kinds fail differently.** A check that scans for item *identifiers* keeps working, because the compact lines keep them — and if one is ever dropped, that check fails loudly. A check that scans an item's *body* is the dangerous one: once the bodies move, it finds nothing to object to and **keeps passing while no longer checking anything**. Point such a check at the archive as well, and prove it can still fail by reintroducing the defect it exists to catch. A gate that has gone silent is worse than one that was never written, because its green result is read as evidence. **An existing repository that predates this shape retrofits it** — the archive is not only for new projects, and a repository that has been running longest needs it most. The trigger is noticing that State is mostly closed items, or that the always-loaded instructions file has grown mostly historical; the procedure for both is in `_agents/universal/consolidation.md`. Retrofit rather than waiting: the cost is already being paid by every session, and it grows. The Rationale file is topical and records dated “Why X, not Y” decisions. The Build Log is chronological and records each meaningful change in the same change, including what changed, the key files, and observed verification. Current Guide and State claims are corrected in place; treatment of superseded Rationale and Build Log claims is defined in `_agents/universal/consolidation.md`.

## General Guidelines

Resolve doubt from governing records and direct evidence before asking the user. Ask when clarification would materially change the result and no safe, useful work can settle or bypass it; during an active work batch, follow `work-batch.md` and continue independent ready work before interrupting. Present necessary questions, choices, and plans as **prose in chat**, not as blocking pop-up widgets (e.g. Claude Code's AskUserQuestion — never use it), so they can be read and answered in context.

Treat commit and push as one completion operation. After creating an in-scope commit, push it to the repository's configured remote in the same work batch and verify that the remote accepted it; do not call committed work saved, published, or complete while it exists only locally. Preserve the user's configured primary Git author and add a `Co-Authored-By:` trailer identifying the agent that created the commit, using the harness/product identity and its noreply address; include a model name only when the runtime exposes it reliably. An explicit user instruction to keep work local wins. If no writable remote exists, authentication or policy blocks the push, or the remote rejects it, preserve the local commit, report its hash and the literal blocker, and leave the work visibly pending publication rather than silently stopping at commit.

## Working Protocol — Model Economy & Delegation

Standing session discipline. This protocol separates the active session position from capability tiers. The terms are vendor-neutral so model lineups can change without rewriting the core.

**Startup topology.** At every top-level chat start, the active agent automatically becomes the **Supervisor**, regardless of its model or capability tier. The Supervisor owns routing, integration, synthesis, final verification, and the answer to the user. Delegated agents are terminal workers or reviewers; they never become Supervisors.

For a supported delegating harness, the bare router loads the universal core, the project instructions, and exactly that harness's adapter at chat start. Resolve the available capability ladder from current harness/tool evidence, never from training-data recall. On a harness with fewer tiers, collapse adjacent middle roles first; always keep a highest-capability Architect tier.

| Capability tier | Work it owns |
| --- | --- |
| **Architect** | Highest-capability architecture, ambiguous or cross-cutting judgment, security-sensitive analysis, and the hardest reviews. |
| **Senior implementer** | HARD, well-scoped implementation against an approved plan; tricky refactors; deep review or post-mortem of complex code. |
| **Implementer** | MEDIUM work: well-specified implementation, standard refactors, moderate-complexity features, and test writing to a given spec. |
| **Mechanic** | EASIEST / mechanical work: renames, boilerplate, formatting, repetitive edits, and exact-pattern additions. |

Harness adapters contain only their own model mapping and spawn mechanics. This protocol is standing authorization for automatic delegation and overrides harness-native advice that discourages spawning. Delegation stays inside the current harness; cross-harness continuity happens only when the user asks another harness to pick up the work (C4).

### Part A — Supervisor discipline

- **A1.** Use reasoning effort proportionate to the work; reserve the highest effort for genuinely hard analysis.
- **A2.** Keep the Supervisor focused on routing, integration, synthesis, and final verification. Worker output is a claim until the Supervisor checks it.
- **A3.** Avoid holding the Supervisor on long mechanical or end-to-end execution when that work can be delegated.
- **A4.** Scope review requests narrowly: name the subsystem and risk classes. Open-ended whole-codebase reviews waste tokens and can stall.
- **A5.** Bank valuable judgment in durable artifacts a later session loads: plans, specifications, post-mortems, project records, or handoffs. Do not leave reusable reasoning only in chat.

### Part B — Automatic delegation

- **B1.** Delegation is automatic standing behavior, not a per-task user option. For every safely separable task, assign the **lowest capable** available tier without asking permission. Give simpler work to simpler models.
- **B2.** "Lowest capable" is independent of the Supervisor's own tier. A worker or reviewer may be below, equal to, or above the Supervisor when that is the correct capability match. Use only the current harness's in-session delegation mechanism.
- **B3.** Delegate only work the Supervisor can understand and evaluate.
- **B4.** One delegation layer, no deeper. Every delegated agent is terminal and performs the assigned mode directly — implementation, research, or read-only review. It MUST NOT delegate, spawn agents, or invoke another agent CLI.
- **B5.** Make each worker prompt self-contained: identify its tier and terminal role, state whether it may edit, name every on-demand or project file it must read, define its file scope, and include verification. End with: "Perform the assigned task directly. Do not delegate, spawn agents, or invoke an external agent CLI."
- **B5a.** If the preferred tier is unavailable, use another currently verified capable tier. If none can do the work correctly, park it and report the blocker; do not silently perform unsuitable work inline.
- **B5b.** Never route from an unverified environment assumption. Verify model availability, quota, time, reset windows, and similar facts in the current turn when they affect the decision.
- **B6.** Every implementation plan orders its work and classifies each block as Supervisor-only, Architect, Senior implementer, Implementer, or Mechanic. In `project_state.md`, use the compact ticket grammar: `### T3 · Title [tier] — depends: T1 — ✅ DONE (date)`.
- **B7.** Every plan step includes its verification: acceptance commands, test invocations from `TEST_SUITE`, assertions, and expected outputs. A plan without a check is unfinished.
- **B8.** Operational loops — device/browser driving, external tools, screenshot/read-modify cycles — are Mechanic-tier execution. The driver persists artifacts and reports literal observations; the Supervisor owns every pass/fail verdict. A driver cannot hand a mid-leg decision back to the Supervisor; each delegated leg reaches its defined checkpoint or fails. A driver cannot satisfy biometric, OS, or credential prompts and must pause for the human. Cut each leg at a checkpoint that returns enough evidence for the Supervisor to choose the next one.

### Part C — Session state & handoffs (any tier)

- **C1.** Whenever human input is needed, or context grows long (do not wait for the limit — 40% to 80% context is the practical window), write a handoff file to `HANDOFF_FILE`: current status, decisions made, next immediate steps, open questions. The user can then `/clear` and restart from the file, saving hundreds of thousands of uncached tokens.
- **C2.** Ending for the day: update documentation and memory files so the next session picks up uninterrupted, and produce a kickoff prompt for it.
- **C3.** After completing work that may be repeated in a similar form later, write a stage-by-stage retrospective (what changed, why it was adapted, what went wrong, current state) as a dated entry in `project_build_log.md` (`REFERENCE_PLAN`).
- **C4.** When the user says "pick up where Claude/Codex left off," "continue/examine the latest Claude/Codex chat," or equivalent, that authorizes reading the named harness's local transcript store. Read `_agents/universal/session-pickup.md` FIRST and follow its mandatory search order exactly — never improvise transcript archaeology, and never assume a repo folder named `conversations/` holds harness transcripts unless the user or project instructions explicitly say so.

### Part D — End-of-session self-critique (any tier)

Timing: at the END of a work block, not the start — early sessions are sharp; late ones have accumulated errors worth sorting through. The agent answers the two CORE questions unprompted — the MANDATORY minimum before closing any significant work block. This is the lightweight every-session floor; DAP (below) is the on-demand deep review.

- **D1.** "What are you least confident about right now?" Expect ~6-7 under-investigated items; about 1 session in 4 one of them is a big deal. For EACH item, name the specific test or command that would settle it — real gaps have a cheap check behind them ("run this; if it prints X we're fine"), filler stays vague no matter the pushing. Never let the model "investigate" its own doubt with the same assumptions that created it.
- **D2.** "What's the biggest thing I'm missing about the situation right now? What don't I realize?" (the Altman question) — only meaningful when the model has deep context on the specific situation; in a thin session it just pattern-matches plausible-sounding gaps.

Situational variants **D3–D12** (long-session re-checks, unstated assumptions, fresh-eyes review, retrospectives, stretch polish): read `_agents/universal/self-critique.md` when closing a long or high-stakes work block.

## Decisions & Devil's Advocate Policy (DAP)

- **Decision transparency (every non-trivial choice):** state at least one rejected alternative and why the chosen option won; decisions worth re-finding go to the Rationale file as a dated "Why X, not Y" entry. (This rule absorbed the former FGMP, 2026-07-26.)
- **Big decisions** — architecture, schema, security-sensitive paths, anything expensive to reverse — get the structured decision write-up in `_agents/universal/dap.md` (Level 1) before committing to them.
- The **full council review** (Level 2) runs ONLY when the user explicitly asks for DAP Level 2, the DAP council, or an equivalent six-reviewer council. On that trigger the FIRST action — before any research, delegation, or questions — is reading `_agents/universal/dap.md` and emitting its `loaded:` line; then follow it. Every completed council DAP emits exactly one verdict stamp as defined there. A request for a plan or ordinary critique does not invoke Level 2.

## Planning & Validation

- Propose a plan and wait for approval before implementing (if user requests suggestions).
- Always validate imports, symbol existence, and referenced resources/keys before coding.
- Ensure all changes align with the project's architecture principles.
- **Reuse before you write.** Before adding a function, helper, validation, constant, or sequence of steps, search for an existing one that already does it and call that instead; extend the existing implementation rather than forking it. Put shared logic in the layer that owns it. A rule enforced in two places drifts, and the copy that is not the authority is the one that silently goes stale.
- **But never collapse two implementations that merely look alike.** Before merging near-identical code, state in writing what each copy *promises*. If the promises differ, the resemblance is a coincidence and merging destroys a real constraint. Keep them apart and pin the difference with a test beside the code itself, so the next reader who notices the resemblance fails in the file they are editing rather than several layers away. "They look the same" is not evidence either way.

## Seasonal Full-App Audit (command)

Trigger: the user asks for a "seasonal audit", "full-app audit", or "refactor audit". Read `_agents/universal/seasonal-audit.md` AND the project's `AUDIT_ADDENDUM` before starting — the Supervisor routes planning and mechanical sweeps by capability tier. DAP Level 1 applies to audit proposals that meet the core big-decision threshold; other proposals follow the audit's Engineering-value test where applicable and the core decision-transparency rule for every non-trivial choice.

## On-demand file map (`_agents/universal/`)

When a trigger below fires, reading the mapped file BEFORE acting is **mandatory** — these files are part of this protocol, split out only to keep every session's always-loaded context small. Acknowledge each load with one visible line (e.g. `loaded: _agents/universal/dap.md`) so compliance is auditable after the fact. A trigger RE-FIRES after any context compaction: if you cannot quote the mapped file's current content, you have not loaded it — read it again. The map you hold is a session-start snapshot; list `_agents/universal/` when in doubt. Routers stay BARE: they load the core, the project file, and only their own harness adapter at chat start. They do not import on-demand procedures or another harness's adapter. Grow the protocol by adding a mapped file, not by expanding this core.

| File | Load when |
| --- | --- |
| `initialize.md` | Initializing / bootstrapping / setting up `_agents/` in a repository; questions about the routers, the folder layout, or where skills and the audit addendum belong |
| `project-guide.md` | Creating or updating the Technical Guide; adopting the five-authority model in an established repository; classifying documentation or validating Guide structure/links |
| `session-pickup.md` | User says "pick up / continue / examine where Claude or Codex left off" (C4) |
| `dap.md` | A big decision is on the table (Level 1), or the user explicitly invokes DAP (Level 2) |
| `self-critique.md` | Closing a long or high-stakes work block (extends D1/D2 with D3–D12) |
| `seasonal-audit.md` | User asks for a seasonal / full-app / refactor audit — load together with the project's `AUDIT_ADDENDUM` file |
| `consolidation.md` | Recording a decision that supersedes earlier recorded entries; the user asks for doc cleanup; **or a file paid for on every session has grown mostly historical — State dominated by closed items, or the project instructions by inline narrative — including retrofitting an established repository that predates the archive** |
| `work-batch.md` | Before beginning or resuming one or more authorized work items — keep the finite ready queue moving and issue one completion report when it is exhausted |
| `adjacent-sweep.md` | Finishing an implementation task, or writing a delegation brief for one — search for the same class of defect elsewhere before the ticket is closed |
