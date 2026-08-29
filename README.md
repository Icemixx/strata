# Strata

Strata is a small, project-agnostic instruction and context-routing kit for repository-based Codex and
Claude Code work. It separates always-loaded conduct from project knowledge that agents route only when
the task needs it.

## Context model

- **Instructions** govern conduct and routing. They are the only general startup context.
- **State** records WHAT is current, using compact ticket entries and routed completed history.
- **Rationale** records WHY decisions were made.
- **Build Log** records HOW work was performed and the evidence observed.
- **Guide** is a generated, self-contained HTML view over those three project authorities. It is not an
  authority and contains no manually maintained unique content.

Each authority is a recursively indexed Markdown tree. Every routed directory has an `index.md`, and
only described links inside `## Contents` define ownership, traversal, and Guide order.

## Shared payload

Copy exactly:

```text
_strata/
|-- universal_agent_instructions.md
`-- universal/
    |-- active-agent.md
    |-- context-routing.md
    |-- context.ps1
    |-- guide-shell.html
    |-- initialize.md
    |-- consolidation.md
    |-- dap.md
    |-- session-pickup.md
    |-- self-critique.md
    |-- seasonal-audit.md
    |-- kit-editing.md
    |-- harness-codex.md
    `-- harness-claude-code.md
```

The payload is copied unchanged. Project rules and authorities remain project-owned. A consuming
repository records the canonical source and synced revision in `_strata/.kit-source` and
`_strata/.kit-version`.

## Initialize a new repository

Read `_strata/universal/initialize.md`. It creates thin root routers, Project Instructions, the State,
Rationale, and Build Log roots and indexes, and the first generated Guide.

Established repositories do not use the empty-repository procedure. They require a separately authorized,
project-specific archive-seeded migration that preserves and reconciles their legacy material before
cutover.

## Validate and generate Guide

The dependency-free Windows PowerShell tool exposes three read-only modes:

```powershell
_strata/universal/context.ps1 -Check -Paths <changed paths>
_strata/universal/context.ps1 -CheckAll
_strata/universal/context.ps1 -GuideStatus
```

All public modes are read-only. Guide generation is agent-internal and direct user invocation is rejected.
It writes `_strata/project_guide.html` only after full graph validation, using an atomic replacement.
Rendering is offline; raw HTML and unsafe link schemes are sanitized. The generated page includes its
source digest and available commit snapshot information so `-GuideStatus` can report whether current
authorities have moved ahead.

Guide refresh is user-triggered. When the user asks to update Guide, the agent reviews concise human-language
descriptions in the owning authority indexes and introductions, then regenerates the snapshot. Ordinary
code and authority changes do not regenerate it, and users do not run the internal generator themselves.
After an authorized commit, the Active Agent checks Guide status once and includes one reminder in the
handoff if the snapshot is stale.

Canonical tool tests are outside the copied payload:

```powershell
.\canonical-tests\context.tests.ps1
```

## Canonical editing

Read `_strata/universal/kit-editing.md` before changing or synchronizing the shared payload. Canonical
editing, consuming-repository synchronization, commit, and publication are separate authorization
boundaries.
