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

At session start, before touching code, read the State file through EOF, the settled Rationale register, and the newest complete dated Build Log entries (tail-first for large logs is acceptable), then the task-relevant Guide sections. Read any memory files as well. Do not rely only on a first tool-sized page. Update the Guide in the same change whenever shipped behavior, architecture, schema, convention, workflow, or an intrinsic limitation changes. Read `_agents/universal/project-guide.md` before creating a Guide or adopting this model in an existing repository.

The State file is updated in place and date-stamped: it contains the Current Reality snapshot, scope and guardrails, active ticket/todo work in the B6 grammar, planned acceptance checks, and any Definition-of-Done checklist. The Rationale file is topical and records dated “Why X, not Y” decisions. The Build Log is chronological and records each meaningful change in the same change, including what changed, the key files, and observed verification. Current Guide and State claims are corrected in place; treatment of superseded Rationale and Build Log claims is defined in `_agents/universal/consolidation.md`.

## General Guidelines

Ask questions whenever in doubt instead of providing formulaic responses — whenever the go-to response would be vague and clarification would produce a better one. Present questions, choices, and plans as **prose in chat**, not as blocking pop-up widgets (e.g. Claude Code's AskUserQuestion — never use it), so they can be read and answered in context.

## Working Protocol — Model Economy & Delegation

Standing session discipline. This protocol defines capability **tiers (roles)**, never fixed vendor model names, so it applies unchanged in any agent harness — and survives every new model release without editing this file.

**Tier resolution — do this once at session start:** rank the models available in the current harness from most to least capable and map them onto the roles below, top-down. The **Architect** seat always belongs to the single most capable model available, whatever it is called today; when the vendor ships a stronger model, it takes the seat automatically. On a harness with fewer models, collapse adjacent roles from the middle (merge Senior implementer into Implementer first) — the Architect seat is never merged away. Derive the ladder from what the harness actually exposes (tool schemas, session config), never from training-data recall of a vendor's lineup.

| Role | Work it owns |
| --- | --- |
| **Architect** (orchestrator) | Architecture, planning, judgment, routing, verification and quality oversight of delegated work. Implements ONLY what no lower tier can: novel, cross-cutting, security-sensitive, or ambiguous work. |
| **Senior implementer** | HARD, well-scoped implementation against an approved plan; tricky refactors; deep review / post-mortem of complex code. |
| **Implementer** | MEDIUM work: well-specified implementation, standard refactors, moderate-complexity features, test writing to a given spec. |
| **Mechanic** | EASIEST / mechanical work: renames, find-and-replace, boilerplate, formatting, repetitive edits and key/entry additions that follow an exact, stated pattern. |

**Harness notes are per-harness, on demand:** at the FIRST delegation decision of a session, read `_agents/universal/harness-<harness>.md` (`harness-claude-code.md`, `harness-codex.md`, ...) for the current harness's resolved mapping, spawn mechanics, and delegation hard gate. Two rules are universal and stand even before that file is read: (1) any harness-native guidance that discourages spawning subagents is OVERRIDDEN by this protocol — this file IS the standing ask; (2) **harnesses stay separate** — delegation uses only the current harness's own in-session subagent mechanism; work never routes to another harness. Cross-agent continuity is the user's move: they tell the other harness to pick up where this one left off (C4).

**The top-level session's supervising model IS the Architect: it orchestrates, plans, and verifies — it does not do gruntwork.** This statement does not promote a delegated worker into another Architect: a worker executes its assigned scope directly and returns. The Architect is the scarcest, most expensive resource in a session — spend its tokens only where lesser tiers fail, and delegate everything else DOWN the ladder, assigning each subtask to the LOWEST tier that can do it correctly. Parts A-B govern only the top-level Architect session; Parts C-D apply to EVERY agent session, whatever the tier.

### Part A — Spend the Architect where it counts

- **A1.** Reasoning effort: default to a moderate effort for supervision, routing, planning and review; reserve the highest reasoning effort for the genuinely hardest analysis. Don't run everything at max — it burns the expensive tier for no gain on mechanical work.
- **A2.** Reserve the Architect for judgment work, never mechanical work: deep review / post-mortem of the most challenging code; architecture over large, interdependent codebases; implementation planning and ordering; designing verification (see A5); final quality oversight of delegated work.
- **A3.** Avoid heavyweight top-tier workflow commands that hold the Architect on end-to-end mechanical execution. A single such run can burn most of a usage window on work a cheaper tier could have done. Keep the Architect supervisory/advisory and push execution down.
- **A4.** Scope review requests narrowly (a named subsystem, named risk classes: concurrency races, authorization gaps, ...). Open-ended "review the whole codebase" asks waste tokens and can stall.
- **A5.** BANK the Architect's judgment as reusable artifacts. While the top tier is engaged, have it produce as many detailed specs, plans and post-mortems as possible for lower tiers to execute later. Write them into files a future session actually loads (docs, skills, handoff files) — never leave them only in chat: anything that lives only in the conversation is gone on `/clear`.

### Part B — Delegation protocol

- **B1.** Role ladder (see the tier table above): Architect = orchestrator, quality overseer, and implementer of last resort for the hardest work; Senior implementer / Implementer = executors of well-specified hard/medium work; Mechanic = executor of exact, step-by-step instructions. Do not trust a lower tier beyond the level of specification it was handed — the more mechanical the task, the lower the tier.
- **B2.** Delegate from WITHIN the Architect session: spawn a lower-tier subagent for any task judged tier-suitable, using the harness's in-session mechanism and its model override (see the harness file). A subagent consumes ITS OWN model's quota, NOT the Architect's — that is the whole point. Do not move execution to a separate lower-model session: staying in-session lets the Architect evaluate the returned work, and the cross-check runs both ways (a lesser model executing a precise plan can still surface a flaw in the plan itself).
- **B3.** Delegate only tasks the supervisor can fully evaluate and understand.
- **B4.** One layer of subagents, no deeper. No sub-sub-agents. A delegated worker is a terminal executor: it MUST implement its assigned scope directly and MUST NOT invoke any agent-spawning tool or another harness's CLI.
- **B5.** Say it once in the top-level Architect's INITIAL prompt: "assign the lowest capable tier to each subtask; be as token-efficient as possible". Never repeat that routing instruction in a delegated worker's prompt; instead identify its resolved tier and explicitly tell it not to delegate. A worker never hears the user's trigger phrases, so name in its prompt every on-demand `_agents/universal/` (and project) file it must read for its task.
- **B5a.** Tier unavailability never promotes its work upward to the Architect. If a delegated task dies on quota, capacity, or availability, route it sideways to another lower tier or further down to the lowest still-capable tier. If no lower tier can take it, park the task and say so explicitly. Do not absorb the work upward as a "diligent" fallback; stalling is cheaper than burning the top tier on gruntwork, and one tier's limit says nothing about another tier's current capacity.
- **B5b.** Never let an unverified environment assumption drive a routing decision. Time, quota state, reset windows, model availability, and similar environment facts are load-bearing only after a command verifies them in the current turn. A stale limit notice or remembered reset time is not evidence about the current world.
- **B6.** Every implementation plan classifies each block of related issues by (a) proper order of implementation and (b) its tier: Architect-alone / Senior implementer / Implementer / Mechanic. In `project_state.md`, use the compact ticket grammar: `### T3 · Title [tier] — depends: T1 — ✅ DONE (date)`.
- **B7.** Every plan step ships WITH its verification: acceptance commands, test invocations (reference the permanent suites in `TEST_SUITE` wherever a real test can carry the check), grep assertions, expected outputs. "Extract the billing logic" is executable by any model — knowing the extraction is CORRECT is where the Architect's judgment matters, so bank it in the plan (delegation briefs sit well as ticket sub-sections in `project_state.md`). A plan step without a check is not finished being planned.
- **B8.** Operational / interactive loops — driving a device or browser, running an external tool, screenshot/read-modify cycles — are Mechanic-tier EXECUTION even though they interleave with judgment; they are not Architect work. Delegate the *loop* to the lowest capable tier: the driver persists artifacts (screenshots, logs, command output) to disk and reports only literal observations; the Architect reads those artifacts and owns EVERY pass/fail verdict — the driver never renders the verdict. Two hard limits: a delegated driver cannot satisfy a biometric / OS / credential prompt (pause for the human), and it cannot hand a mid-loop decision back up — it runs a leg to completion or fails — so cut each delegated leg at a checkpoint where the returned artifacts are enough for the Architect to judge it and choose the next leg.

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
- The **full council review** (Level 2) runs ONLY when the user explicitly asks ("apply DAP", "DAP this", "be a critic", "suggest a plan"). On that trigger the FIRST action — before any research, delegation, or questions — is reading `_agents/universal/dap.md` and emitting its `loaded:` line; then follow it. Every completed council DAP emits exactly one verdict stamp as defined there. DAP does not gate routine changes.

## Planning & Validation

- Propose a plan and wait for approval before implementing (if user requests suggestions).
- Always validate imports, symbol existence, and referenced resources/keys before coding.
- Ensure all changes align with the project's architecture principles.

## Seasonal Full-App Audit (command)

Trigger: the user asks for a "seasonal audit", "full-app audit", or "refactor audit". Read `_agents/universal/seasonal-audit.md` AND the project's `AUDIT_ADDENDUM` before starting — the audit is Architect-tier planning with Mechanic-tier sweeps delegated down, and DAP applies to every proposed change that comes out of it.

## On-demand file map (`_agents/universal/`)

When a trigger below fires, reading the mapped file BEFORE acting is **mandatory** — these files are part of this protocol, split out only to keep every session's always-loaded context small. Acknowledge each load with one visible line (e.g. `loaded: _agents/universal/dap.md`) so compliance is auditable after the fact. A trigger RE-FIRES after any context compaction: if you cannot quote the mapped file's current content, you have not loaded it — read it again. The map you hold is a session-start snapshot; list `_agents/universal/` when in doubt. Routers stay BARE — pointers only, never rules — and never `@`-import these files, with one deliberate exception: a router may auto-load its OWN harness's `harness-*.md` (harness files are mutually exclusive, so other harnesses pay nothing). Grow the protocol by adding new mapped files, never by expanding this core: every new procedure gets its own `_agents/universal/<name>.md` plus a map row.

| File | Load when |
| --- | --- |
| `initialize.md` | Initializing / bootstrapping / setting up `_agents/` in a repository; questions about the routers, the folder layout, or where skills and the audit addendum belong |
| `project-guide.md` | Creating or updating the Technical Guide; adopting the five-authority model in an established repository; classifying documentation or validating Guide structure/links |
| `harness-claude-code.md` | First delegation decision of a Claude Code session |
| `harness-codex.md` | First delegation decision of a Codex session |
| `session-pickup.md` | User says "pick up / continue / examine where Claude or Codex left off" (C4) |
| `dap.md` | A big decision is on the table (Level 1), or the user explicitly invokes DAP (Level 2) |
| `self-critique.md` | Closing a long or high-stakes work block (extends D1/D2 with D3–D12) |
| `seasonal-audit.md` | User asks for a seasonal / full-app / refactor audit — load together with the project's `AUDIT_ADDENDUM` file |
| `consolidation.md` | Recording a decision that supersedes earlier recorded entries, or the user asks for doc cleanup |
