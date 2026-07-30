## What this is

This repository contains a drop-in set of living protocols for Claude Code and Codex agents working in repository-based Visual Studio Code (VS Code) harnesses. The shared protocol is harness-agnostic between them; dedicated adapter files handle their different startup and delegation mechanics. It provides a consistent, reviewable workflow for planning, delegation, audits, handoffs, and on-demand procedures. It is documentation, not runnable application code.

## The five project authorities

Each consuming repository owns five separate authorities:

| Authority | Default path | Owns |
| --- | --- | --- |
| Technical Guide | `_agents/project_guide.html` | Current software architecture, behavior, operator/developer technical workflows, technical conventions, and intrinsic limitations |
| State | `_agents/project_state.md` | Current reality, scope, active backlog, priorities, approvals, unresolved work, and acceptance gates |
| Rationale | `_agents/project_rationale.md` | Settled why, rejected alternatives, and reopening conditions |
| Build Log | `_agents/project_build_log.md` | Dated actions, commands actually run, and exact observed evidence |
| Instructions | `_agents/project_instructions.md` | Mandatory agent conduct, protocol parameters, enforcement rules, and pointers to the Guide |

`REFERENCE_PLAN` names only State, Rationale, and Build Log. `TECHNICAL_GUIDE` names the Guide. The Guide never substitutes for State. See `_agents/universal/project-guide.md` for the routing, adoption, and self-contained HTML requirements.

## What is copied

The shared kit is only `_agents/universal_agent_instructions.md` and the entire `_agents/universal/` folder. Do not copy this root `README.md`; it is canonical-repository documentation, not a project authority or kit payload.

```
README.md                           ← canonical-repository entry and redirect; not copied
LICENSE                             ← license text
_agents/
  universal_agent_instructions.md   ← always-loaded core; copied
  universal/                        ← on-demand procedures; copied in full
    initialize.md                   ← initialization and bare routers
    project-guide.md                ← Guide creation, adoption, and validation
    consolidation.md                ← authority-specific history handling
    dap.md                          ← Decisions & Devil's Advocate Policy
    harness-claude-code.md          ← Claude Code adapter
    harness-codex.md                ← Codex adapter
    session-pickup.md               ← session-resumption procedure
    self-critique.md                ← end-of-session review
    seasonal-audit.md               ← full-app audit procedure
```

## Install in a repository

1. Copy only `_agents/universal_agent_instructions.md` and the complete `_agents/universal/` folder into the target repository. Do not copy the canonical root README.
2. Before creating or changing project-owned files, follow `_agents/universal/initialize.md`. In an established repository, inventory first and then follow `_agents/universal/project-guide.md`; do not blindly move legacy documents.
3. Create the five project authorities. In `project_instructions.md`, declare distinct `REFERENCE_PLAN` and `TECHNICAL_GUIDE` values. Create `_agents/project_guide.html` as one offline self-contained HTML file.
4. Add bare router files only from the templates in `initialize.md`, then validate the Guide and authority boundaries through `project-guide.md`.

Project-owned files override the universal core on conflict. The core describes when to load each on-demand procedure.
