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
    |-- initialize.md
    |-- consolidation.md
    |-- dap.md
    |-- session-pickup.md
    |-- self-critique.md
    |-- seasonal-audit.md
    |-- kit-editing.md
    |-- harness-codex.md
    |-- harness-claude-code.md
    `-- vendor/
        |-- marked-0.3.19.min.js
        `-- MARKED-LICENSE.md
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

The dependency-free Windows PowerShell tool has three explicit modes:

```powershell
_strata/universal/context.ps1 -Check -Paths <changed paths>
_strata/universal/context.ps1 -CheckAll
_strata/universal/context.ps1 -GenerateGuide
```

Checks are read-only. Only `-GenerateGuide` writes `_strata/project_guide.html`, after full graph
validation, using an atomic replacement. Markdown rendering is offline through the bundled pinned
renderer; raw HTML and unsafe link schemes are sanitized.

Canonical tool tests are outside the copied payload:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File canonical-tests/context.tests.ps1
```

## Canonical editing

Read `_strata/universal/kit-editing.md` before changing or synchronizing the shared payload. Canonical
editing, consuming-repository synchronization, commit, and publication are separate authorization
boundaries.
