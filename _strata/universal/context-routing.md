# Context routing

Part of the universal agent set. Load this procedure when creating or changing authority structure,
instruction audiences, routed indexes, State lifecycle storage, Guide generation, or context validation.
Loading is silent.

## Authority model

Instructions governs conduct and routing. Project information has three authorities:

- **State** owns WHAT is current, including work status.
- **Rationale** owns WHY decisions were made.
- **Build Log** owns HOW work was performed and the evidence observed.

`_strata/project_guide.html` is not an authority. It is a generated user-facing wrapper over those three
sources. Agents read the Markdown authorities, not Guide.

## Project layout

```text
_strata/
|-- project_instructions.md
|-- project_instructions_active_agent.md   # optional
|-- state/
|   |-- index.md
|   |-- current.md
|   `-- completed/
|       `-- index.md
|-- rationale/
|   `-- index.md
|-- build-log/
|   `-- index.md
`-- project_guide.html
```

State, Rationale, and Build Log roots and their `index.md` files always exist. Deeper branches are
project-defined. The shared canonical payload remains `_strata/universal_agent_instructions.md` plus
`_strata/universal/`.

## Instruction audiences

Every agent loads common Universal Instructions and common Project Instructions. The user-facing Active
Agent additionally loads `_strata/universal/active-agent.md` and, when present,
`_strata/project_instructions_active_agent.md`. Delegated agents do not load either Active Agent file;
their relevant context arrives through the delegation brief.

Keep current rules in exactly one instruction audience. A rule needed by every agent belongs in common
Instructions. Active-Agent-only integration and routing rules belong in Active Agent Instructions.
Historical instruction reasoning belongs in Rationale.

Root harness routers remain thin: they load common Universal and Project Instructions only. Common
Instructions route the user-facing session to Active Agent Instructions. Harness adapters load on demand
when their mechanics or cross-harness interoperability information is needed; they are not startup
imports.

## Index contract

Every routed directory contains `index.md`. Every routed record and child index is reachable from its
authority root and has exactly one owning index.

Each index contains `## Contents`. Its direct-child entries use a Markdown link followed by a short
description sufficient to judge relevance:

```markdown
## Contents

- [Drive synchronization](drive-sync/index.md) — Decisions about sharing, merging, and failures.
- [R125](drive-sync/R125.md) — Why failed refreshes preserve settled status.
```

Only links in `## Contents` define routed children and Guide order. Other links are ordinary references.
An additional reference never creates another routing owner. Links use stable paths and may use stable
heading anchors; never use literal line numbers. Leaf filenames and tree depth are project-defined.

When adding or moving a record, first reuse an existing branch whose index description clearly covers
it. Before the automatic ceiling, create a new branch only when the user explicitly directs it or an
applicable project taxonomy already defines it.

Inspect the touched parent index for related siblings whenever an indexed record is added or moved. If
ten or more direct, related, ungrouped leaf files exist, automatically create a cohesive branch. This
ceiling applies to Rationale, Build Log, and completed-State leaf files, not ticket entries inside
`state/current.md`. Follow the project's directory naming convention; if none exists, use a short
lowercase hyphenated subject name such as `drive-sync/`.

Create the branch and its index, add the parent entry, move the records, repair inbound links and affected
checks, validate routing, and regenerate Guide as one authority transaction. Then notify the user that
the ten-record ceiling was reached, naming the branch and moved records. The notice is informational, not
an approval request.

There is no other universal byte, line, entry, or depth ceiling. Split based on cohesion and scanability.

## Loading routed context

Instructions is the only general startup authority. State loads for repository planning, implementation,
continuation, status, and completion work. It does not load for unrelated questions or narrow,
status-independent explanations. Loading State does not load Rationale or Build Log automatically.

Normally begin with the authority root index. An already-loaded stable link may route directly to a
deeper record. Read every activated index completely without implicitly loading its children. Follow only
links relevant to the task.

A narrow read-only request may use a targeted section or small leaf. Read the complete target file before
editing it, changing status, resolving a conflict, or making a consequential decision. If in doubt, read
the rest of the file.

Search the complete relevant authority tree before concluding information is absent when routing is
ambiguous, expected information is missing, records conflict, or the task is cross-cutting.

## State contract

State supports exactly `OPEN`, `IN PROGRESS`, `BLOCKED`, and `DONE`. `DONE` means every ticket-owned
requirement and acceptance gate is complete. Remaining implementation, validation, or device evidence is
`IN PROGRESS`. An agent may not move an unfinished owned gate into another ticket to manufacture `DONE`;
that requires an explicit user-approved scope redefinition.

Every State ticket has a globally unique ID, one status, and a short contextual description:

```markdown
- BUG-110 — IN PROGRESS — Retry behavior is implemented; device verification remains.
  - Why: [R125](../rationale/drive-sync/R125.md)
  - How: [Device implementation](../build-log/drive-sync/BUG-110.md)
```

The first line is required. `Why:` and `How:` links are optional, may contain multiple targets, and are
the only machine-readable associations Guide uses to combine Rationale and Build Log with a State ticket.
Those target records require no backlinks or ticket metadata. Dependencies and blocker details are
optional.

`state/current.md` contains `OPEN`, `IN PROGRESS`, and `BLOCKED` tickets. When every owned gate is
complete, move the entry atomically to an appropriate indexed location under `state/completed/`, preserve
its ID, description, and links, and ensure it appears exactly once. Completed storage is cold and loads
only for historical need. Reopened work moves back to current storage.

## Guide and `context.ps1`

The kit ships one dependency-free Windows PowerShell tool at `_strata/universal/context.ps1`. It resolves
project paths relative to itself and requires exactly one explicit mode:

```powershell
context.ps1 -Check -Paths <changed paths>
context.ps1 -CheckAll
context.ps1 -GenerateGuide
```

No arguments displays help and changes nothing. `-Check` and `-CheckAll` are read-only. Only
`-GenerateGuide` may write `_strata/project_guide.html`; it validates the complete graph first and
atomically replaces Guide only after success.

Discovery begins at the three authority root indexes and follows `## Contents` in declared order.
Filesystem records absent from that graph are validation findings, not implicitly included content.

Guide is a committed, visibly generated, self-contained HTML snapshot with no server, network resource,
or manually maintained unique content. It mirrors authority hierarchy, gives State tickets stable
ID-derived anchors, combines their typed WHY and HOW targets, and embeds offline search. Empty Rationale
or Build Log sections display `No records yet`.

Guide embeds a deterministic digest of routed source content and generator version. Authority records use
ordinary Markdown. A bundled dependency-free GitHub-style renderer disables raw HTML; unexpected
HTML-like text is displayed rather than executed.

## Validation and authority updates

Mechanical validation covers required roots and indexes, valid links, reachability, exactly-one routing
ownership, unique State IDs, exactly-one current/completed placement, approved statuses, required
instruction-audience files, and thin-router edges. It does not validate semantic accuracy, context
budgets, commit-provenance grammar, project gates, or harness certification. A structurally valid graph
and fresh Guide do not prove that human-authored claims are correct.

Use the smallest check relevant to touched paths. Run full validation for topology, shared validation or
generation logic, migration, or an explicit full audit.

When moving a file or stable heading, search inbound references and repoint every surviving link. Remove
a reference only when its underlying claim was deliberately deleted. If an existing check inspected the
old location, update only the affected check and demonstrate that it can still detect its target failure.

Update only authorities that gained information: status changes update State; decisions update Rationale;
implementation and evidence update Build Log; completion finalizes and moves the State entry. Add typed
State links when corresponding records exist. Regenerate Guide after any authority change.

This format applies directly to new repositories. An established repository requires a separately
authorized, project-specific migration. Preserve its legacy material until reconciliation is verified
and ask the user about conflicting claims; no legacy source wins automatically.
