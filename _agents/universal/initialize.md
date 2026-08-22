# Initialize — set up `_agents/` in a repository

Part of the universal agent set — see `_agents/universal_agent_instructions.md` (the always-loaded core; this folder holds startup harness adapters and on-demand procedures). Identical across all repositories; never edit per-project. On loading this file, announce it with one visible line: `loaded: _agents/universal/initialize.md`. Load when asked to initialize, bootstrap, or set up the agent system in a repository, or when asked why the folder is laid out this way.

## Why `_agents/`

The instruction files live in the **`_agents/`** folder (together with the five project authorities) to keep the repo root uncluttered. The folder name deliberately avoids the `.`-prefix namespace that harnesses claim for themselves (`.github/`, `.claude/`, `.codex/`, `.agents/`, ...) and avoids a leading `-` (shells parse it as a flag), so no tool ever regenerates or overwrites it; the harness entry files are BARE routers that point here.

## Step 0 — look before you write

Never create a file that already exists in some form. Before writing anything, check for and READ: `_agents/` (any part of it), `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.github/instructions/`, `.github/skills/`, `.claude/` (rules, skills, agents, settings), `.agents/skills/`, `.codex/`, and any `PLAN.md` / `ROADMAP.md` / `TODO.md` / `DECISIONS.md` / `NOTES.md` the repo already keeps.

Then, per file found: **fold** genuine project rules into `project_instructions.md`; route current behavior and technical workflows to the Guide, current status to State, settled decisions to Rationale, and dated evidence to Build Log; **replace** a harness-owned router with the bare template below. For an established repository, stop after inventory and read `_agents/universal/project-guide.md` before adopting or retiring any documentation; do not blindly move, overwrite, or delete handwritten material. Report anything ambiguous and ask.

Never migrate, and never copy into the repository: credentials or tokens, personal/local settings (`.claude/settings.local.json` and equivalents), transcripts, generated memory, caches, logs, or administrator-managed policy. Report them if they matter; otherwise ignore them.

## Step 1 — drop in the universal set

Copy `_agents/universal_agent_instructions.md` plus the whole `_agents/universal/` folder from the canonical repository named in the core banner. Use a scratch clone outside the project, copy the complete unit, and never edit it per project.

## Step 2 — create what is missing

1. **`_agents/project_instructions.md`** — this project's mandatory agent conduct, protocol parameters, enforcement rules, and pointers. Derive the initial enforcement boundaries from the codebase and the user's answers; open it with one line pointing back to the core file. Declare `REFERENCE_PLAN = _agents/project_state.md, _agents/project_rationale.md, _agents/project_build_log.md` and `TECHNICAL_GUIDE = _agents/project_guide.html`, plus the other protocol parameters listed in the core. Put the stable suite location and default invocation here. Enforce technical boundaries by linking to the Guide; do not duplicate its architecture or workflow material.
2. **`_agents/project_guide.html`** — create the single self-contained offline Technical Guide. It owns current software architecture, behavior, operator/developer technical workflows, technical conventions, and intrinsic limitations. Follow `_agents/universal/project-guide.md` for its required structure and validation.
3. **The three `REFERENCE_PLAN` files:** `_agents/project_state.md` (open with a Current Reality block, active work, and planned acceptance checks; a long-running repository may later delegate closed-item detail to `_agents/project_state_archive.md`, which is a subordinate appendix never read at session start — see `_agents/universal/consolidation.md`), `_agents/project_rationale.md` (open with its settled-decision format), and `_agents/project_build_log.md` (open with a dated initialization entry recording exact observed setup evidence).
4. **Three BARE routers at their harness-required locations** — templates below, used verbatim.

## Step 3 — establish the two conventions

Set these up front so each repository does not invent its own location. Both are on-demand: create the file only when there is real content for it, but name the convention in `project_instructions.md` immediately.

- **Project skills** live at **`_agents/skills/<skill-name>/SKILL.md`** — ONE copy, read by every harness through the routers, invoked by **trigger phrase** ("run the X procedure"), never by copying into `.claude/skills/`, `.agents/skills/`, or `.github/skills/`. Use the Agent Skills format (`name` + `description` frontmatter, then ordered steps, inputs/outputs, failure handling, verification) so a skill can later be registered natively for `/slash` invocation by copying the directory, with no rewrite. `project_instructions.md` carries a **trigger map** table (trigger → skill file). Announce each load with `loaded: _agents/skills/<name>/SKILL.md`. All three harnesses read the same skill format; only their folders differ, which is exactly why one routed copy beats several native ones.
- **The audit addendum** lives at **`_agents/audit_addendum.md`**, and `AUDIT_ADDENDUM` in `project_instructions.md` points there. It holds the stack-specific checklist for the Seasonal Full-App Audit; the universal procedure stays in `_agents/universal/seasonal-audit.md`. Keeping it as its own on-demand file means an audit checklist that is needed twice a year does not sit in every session's context.

## Router templates

`.github/copilot-instructions.md` (GitHub Copilot — no delegation mechanism, so no harness-file pointer):

```markdown
# Agent Instructions Router

Before starting any work in this repository, read and follow, in order:

1. `_agents/universal_agent_instructions.md` — the universal working protocol.
2. `_agents/project_instructions.md` — this project's rules and protocol parameters.

Precedence on conflict: project file > universal file. This router carries no rules of its own.
```

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

Note: routers stay BARE — pointers only, never rules or content. A supported delegating harness loads the core, the project file, and only its own harness adapter at chat start. It never loads another harness's adapter. On-demand procedures remain in the core's trigger map and are not imported by routers. The Copilot router has no harness adapter because this kit defines no Copilot delegation adapter.

## Verify before initialization is complete

- Every router is bare and matches its template.
- `project_instructions.md` defines all protocol parameters named in the core file, including distinct `REFERENCE_PLAN` and `TECHNICAL_GUIDE`, plus both conventions from Step 3.
- All five project authorities exist, the Guide is one self-contained offline HTML file, and the Build Log carries a dated initialization entry.
- Nothing personal, generated, or secret was copied into the repository.
- The complete universal set is content-identical to a fresh canonical clone after normalizing line endings (hash every relative path).
