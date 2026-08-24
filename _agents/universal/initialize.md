# Initialize — set up `_agents/` in a repository

Part of the universal agent set — see `_agents/universal_agent_instructions.md` (the always-loaded core; this folder holds startup harness adapters and on-demand procedures). Identical across all repositories; never edit per-project. On loading this file, announce it with one visible line: `loaded: _agents/universal/initialize.md`. Load when asked to initialize, bootstrap, or set up the agent system in a repository, or when asked why the folder is laid out this way.

Read `_agents/universal/instruction-topology.md` with this file. It defines the mandatory project
supervisor surface, `AGENT_SYSTEM_CHECK`, worker-chain budgets, canonical certification, and retrofit
transaction; this file owns creation and inventory rather than duplicating those contracts.

## Why `_agents/`

The instruction files live in the **`_agents/`** folder (together with the five project authorities) to keep the repo root uncluttered. The folder name deliberately avoids the `.`-prefix namespace that harnesses claim for themselves (`.github/`, `.claude/`, `.codex/`, `.agents/`, ...) and avoids a leading `-` (shells parse it as a flag), so no tool ever regenerates or overwrites it; the harness entry files are BARE routers that point here.

## Step 0 — classify the repository, then take ONE path

**"Initialize" is one verb with two jobs.** Do not ask the user which situation this is — read the repository and decide, then say which path you took and why. Getting this wrong in either direction is expensive: bootstrapping over an established repo destroys handwritten material, and treating an established repo as merely "already set up" leaves it paying costs a new one never incurs.

Classify from evidence, not from the phrasing of the request:

| Signal | EMPTY / NEW | ESTABLISHED |
| --- | --- | --- |
| `_agents/` exists in any form | no | **yes** |
| Handwritten docs (`AGENTS.md`, `CLAUDE.md`, `PLAN.md`, `ROADMAP.md`, `DECISIONS.md`, …) | none | **any** |
| Git history | little or none | substantial |
| Existing State / Rationale / Build Log with real content | no | **yes** |

**Any single ESTABLISHED signal makes it established.** The classification is deliberately asymmetric, because the cost of the two mistakes is not symmetric.

- **EMPTY → Steps 1 to 4, in order, done.** Create the standard set and stop.
- **ESTABLISHED → Step 1, then Step 0b below, then Steps 2 to 4 for whatever is genuinely missing.** Nothing is overwritten and nothing is discarded.

## Step 0b — the established-repository path (retrofit, losing nothing)

Run this in order. It is the same work a new repository gets for free, done after the fact.

1. **Inventory before writing anything.** Read every file listed in "look before you write" below. Produce the inventory as a visible list, and do not create a file that already exists in some form.
2. **Route existing content by authority, do not delete it.** Genuine project rules fold into `project_instructions.md`; current behavior and technical workflows to the Guide; current status to State; settled decisions to Rationale; dated evidence to Build Log. A harness-owned instruction file is **replaced** by a bare router only after its content has been routed. **When in doubt, keep it and report it** — an unrouted paragraph costs a line; a deleted one costs the reason a rule exists.
3. **Create only what is missing**, per Step 3. A repository already on an older copy of this kit usually needs the supervisor file, archives, version marker, checker parameter, and any newly added files.
4. **Retrofit the bounded-file shape,** which is the part an established repository is silently paying for: if State is dominated by closed items, or the instructions file is thick with inline narrative, run the bounding procedure in `_agents/universal/consolidation.md`. Create **both** `_agents/project_state_archive.md` and `_agents/project_instructions_archive.md` if they do not exist, and actually move the material — an established repository is where this pays most, and where the trigger has most often been read and ignored because there was no destination file to move into. **This is not optional cleanup** — a long-running repository has been paying that cost on every session, and it grows. Measure: report before/after byte counts for each file, never an estimate.

   **Then check what the move did to every mechanical check that reads those files, and fix it in the same pass.** A check that scans for *identifiers* keeps working, and fails loudly if one is dropped. A check that scans an item's *body* is the dangerous one: once the bodies move it finds nothing to object to and **keeps passing while no longer checking anything.** Point such a check at the archive as well, and **prove it can still fail** by reintroducing the defect it exists to catch. A gate that has gone silent is worse than one never written, because its green result is read as evidence.
5. **Re-point and RUN every mechanical check** the repository has. Verify by running them, not by reading them.
6. **Report** what was moved, what was created, what was left alone, and anything ambiguous enough to need the user. Never report a retrofit as complete without the before/after sizes from step 4.

**Refuse to guess on one thing only:** if routing a piece of handwritten material would change its meaning, stop and ask about that piece. Continue with everything else rather than blocking the whole retrofit on one paragraph.

## Step 1 — look before you write

Never create a file that already exists in some form. Before writing anything, check for and READ: `_agents/` (any part of it), `AGENTS.md`, `CLAUDE.md`, `.claude/` (rules, skills, agents, settings), `.agents/skills/`, `.codex/`, and any `PLAN.md` / `ROADMAP.md` / `TODO.md` / `DECISIONS.md` / `NOTES.md` the repo already keeps.

Then, per file found: **fold** genuine project rules into `project_instructions.md`; route current behavior and technical workflows to the Guide, current status to State, settled decisions to Rationale, and dated evidence to Build Log; **replace** a harness-owned router with the bare template below. For an **established** repository, stop after this inventory and read `_agents/universal/project-guide.md` before adopting or retiring any documentation; do not blindly move, overwrite, or delete handwritten material, and report anything ambiguous. The inventory then feeds **Step 0b**, which owns the routing and the retrofit.

Never migrate, and never copy into the repository: credentials or tokens, personal/local settings (`.claude/settings.local.json` and equivalents), transcripts, generated memory, caches, logs, or administrator-managed policy. Report them if they matter; otherwise ignore them.

## Step 2 — drop in the universal set

Copy `_agents/universal_agent_instructions.md` plus the whole `_agents/universal/` folder from the canonical repository named in the core banner. Use a scratch clone outside the project, copy the complete unit, and never edit it per project.

## Step 3 — create what is missing

1. **`_agents/project_instructions.md`** — this project's mandatory worker-facing conduct, protocol parameters, enforcement rules, and pointers. Derive the initial enforcement boundaries from the codebase and the user's answers; open it with one line pointing back to the core file and the conditional top-level trigger required by `instruction-topology.md`. Declare `REFERENCE_PLAN = _agents/project_state.md, _agents/project_rationale.md, _agents/project_build_log.md`, `TECHNICAL_GUIDE = _agents/project_guide.html`, and `AGENT_SYSTEM_CHECK = <one repository-native command>`, plus the other protocol parameters listed in the supervisor layer. Put the stable suite location and default invocation here. Enforce technical boundaries by linking to the Guide; do not duplicate its architecture or workflow material.
2. **`_agents/project_instructions_supervisor.md`** — mandatory project-specific top-level supervision, integration, and certification rules. Open it with an audience warning: top-level only; delegated workers must not read it. Keep every worker imperative in `project_instructions.md`; never duplicate shared rules here.
3. **`_agents/project_guide.html`** — create the single self-contained offline Technical Guide. It owns current software architecture, behavior, operator/developer technical workflows, technical conventions, and intrinsic limitations. Follow `_agents/universal/project-guide.md` for its required structure and validation.
4. **The three `REFERENCE_PLAN` files:** `_agents/project_state.md` (open with a Current Reality block, active work, and planned acceptance checks), `_agents/project_rationale.md` (open with its settled-decision format), and `_agents/project_build_log.md` (open with a dated initialization entry recording exact observed setup evidence).
5. **The project-owned kit provenance markers** — `_agents/.kit-source` holds the canonical remote used for this copy and `_agents/.kit-version` holds its exact commit SHA, one line each. Both stay deliberately **outside** `_agents/universal/`, because that folder is copied wholesale and source identity is project configuration, not universal payload content. Together they make the session-start freshness check possible; if either is missing, freshness is unavailable rather than silently assumed.
6. **`_agents/project_state_archive.md`** — State's closed-item archive, created **now, empty**, not when it is first needed. State is the one record the supervisor requires to be read **through EOF** every session, so its finished-ticket history becomes a permanent tax on every future session; a repository that waits until that hurts pays the retrofit as well as the tax. Open it with a header stating that it is a **subordinate appendix of State, not current truth, and loses to State on any conflict**, and that it is **never read at session start** — only when a specific closed item is in question. **Do NOT list it in `REFERENCE_PLAN`**: those three files are read at startup and this one exists precisely so it is not. Name it in `project_instructions.md`'s authority table as State's appendix, and state the exclusion in that file's own startup-read rule.
7. **`_agents/project_instructions_archive.md`** — the instructions file's narrative archive, created **now, empty**, for the same reason as State's and a stronger one. The instructions file is loaded by the router into **every session AND every spawned agent**, so inline incident narrative is a heavier permanent tax than State's, which is read once. Give it the same header contract: a **subordinate appendix of the Instructions authority, not current truth, losing to the current instruction files on any conflict**, and **never read at session start** — only when someone wants the reason behind a specific rule. **Do NOT list it in `REFERENCE_PLAN`.** Name it in `project_instructions.md`'s authority table and state the exclusion in that file's own startup-read rule.

   **Keep the rule, move the story.** Each rule keeps its imperative inline plus a bare pointer to the archive entry holding its evidence. **Do not move a passage that IS the rule** — a quoted user ruling is the authority itself, and removing it leaves a weaker rule, not a shorter one.

8. **The repository-native agent-system checker and permanent watched-red tests** — implement the command declared by `AGENT_SYSTEM_CHECK` and its `<AGENT_SYSTEM_CHECK> --self-test` interface against the exact contract in `instruction-topology.md`. The checker is part of initialization, not optional later hardening.
9. **Two BARE routers at their harness-required locations** — templates below, used verbatim.

## Step 4 — establish the two conventions

Set these up front so each repository does not invent its own location. Both are on-demand: create the file only when there is real content for it, but name the convention in `project_instructions.md` immediately.

- **Project skills** live at **`_agents/skills/<skill-name>/SKILL.md`** — ONE copy, read by every supported harness through the routers, invoked by **trigger phrase** ("run the X procedure"), never by copying into `.claude/skills/` or `.agents/skills/`. Use the Agent Skills format (`name` + `description` frontmatter, then ordered steps, inputs/outputs, failure handling, verification) so a skill can later be registered natively for `/slash` invocation by copying the directory, with no rewrite. `project_instructions.md` carries a **trigger map** table (trigger → skill file). Announce each load with `loaded: _agents/skills/<name>/SKILL.md`. Both supported harnesses read the same skill format; only their folders differ, which is exactly why one routed copy beats several native ones.
- **The audit addendum** lives at **`_agents/audit_addendum.md`**, and `AUDIT_ADDENDUM` in `project_instructions.md` points there. It holds the stack-specific checklist for the Seasonal Full-App Audit; the universal procedure stays in `_agents/universal/seasonal-audit.md`. Keeping it as its own on-demand file means an audit checklist that is needed twice a year does not sit in every session's context.

## Router templates

`AGENTS.md` (repo root — Codex and the AGENTS.md ecosystem) — same, plus a pointer to its OWN harness file:

```markdown
# Agent Instructions Router

Before starting any work in this repository, read and follow, in order:

1. `_agents/universal_agent_instructions.md` — the universal working protocol.
2. `_agents/project_instructions.md` — this project's rules and protocol parameters.
3. `_agents/universal/harness-codex.md` — Codex's harness adapter.

Precedence on conflict: project file > universal file (the universal set includes `_agents/universal/`). This router carries no rules of its own.
```

`CLAUDE.md` (repo root — Claude Code; `@` imports auto-load all three files, including its OWN harness file):

```markdown
# Agent Instructions Router

Read and follow all three (project file wins on conflict; this router carries no rules of its own):

@_agents/universal_agent_instructions.md

@_agents/project_instructions.md

@_agents/universal/harness-claude-code.md
```

Note: routers stay BARE — pointers only, never rules or content. A supported delegating harness loads the core, the worker-facing project file, and only its own harness adapter at chat start. It never loads another harness's adapter, the project supervisor file, or either archive. The sole project-supervisor activation edge is the conditional instruction at the top of `project_instructions.md`. On-demand procedures remain in the supervisor layer's trigger map and are not imported by routers. A future harness is unsupported until the canonical kit explicitly adds its router or adapter contract and completes canonical route-contract plus empirical certification.

## Verify before initialization is complete

- Every router is bare and matches its template.
- `project_instructions.md` defines all protocol parameters, including distinct `REFERENCE_PLAN` and `TECHNICAL_GUIDE`, the literal `AGENT_SYSTEM_CHECK` command, and both conventions from Step 4.
- The project supervisor and archives have their required audience headers; no router imports them.
- All five project authorities exist, the Guide is one self-contained offline HTML file, and the Build Log carries a dated initialization entry.
- Nothing personal, generated, or secret was copied into the repository.
- The complete universal set is content-identical to a fresh canonical clone after normalizing line endings (hash every relative path).
- `_agents/.kit-source` names that canonical remote and `_agents/.kit-version` names the exact copied commit; the canonical root certification record supports every declared harness route.
- `AGENT_SYSTEM_CHECK` and `<AGENT_SYSTEM_CHECK> --self-test` pass with every supported route at or below the effective budget.
- Project initialization is complete when its deterministic source checks pass. Harness-product empirical certification belongs to the canonical repository and is not repeated in each consuming project.
