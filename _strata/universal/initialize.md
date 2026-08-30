# Initialize a repository

Use this procedure to install Strata in a new repository. Established repositories require a separate,
project-specific archive-seeded migration; do not retrofit them with this procedure.

## Preflight

Inspect the repository before writing. If it already contains project history, substantial handwritten
documentation, an agent namespace, or populated project records, treat it as established and stop this
procedure without overwriting anything.

Never copy or embed credentials, tokens, personal or machine-local settings, transcripts, generated
memory, caches, raw logs, or administrator-managed policy in project authorities or the shared kit. This
prohibition is absolute and cannot be authorized away. A relevant non-sensitive fact may be recorded
independently in its owning authority, but the protected source material itself is never ingested.

## Create the topology

1. Copy the complete shared payload: `_strata/universal_agent_instructions.md` and every file under
   `_strata/universal/`.
2. Create `_strata/project_instructions.md` with only project-specific conduct, constraints, and routes.
   Create `_strata/project_instructions_active_agent.md` only for genuinely Active-Agent-only rules.
3. Create these mandatory authority roots and indexes:

   ```text
   _strata/
   |-- state/
   |   |-- index.md
   |   |-- current.md
   |   `-- completed/
   |       `-- index.md
   |-- rationale/
   |   `-- index.md
   `-- build-log/
       `-- index.md
   ```

   Every index has `## Contents`. Each routed entry includes a concise human-language description that
   helps a reader judge relevance without inventing project facts. Empty indexes keep that heading with
   no invented records.
4. Do not create `_sediment/` empty. Create it when the repository first has material for it — a
   discussion, plan or open question at its root, or an evidence ledger, external specification or source
   data file under `_sediment/reference/`. In an established repository, existing deliberation and
   reference material moves there during migration rather than into `_strata/`.
5. Run `_strata/universal/context.ps1 -CheckAll`, then perform the agent-internal Guide generation to
   create the initial `_strata/project_guide.html`. Do not instruct the user to invoke the internal
   generation mode.
6. Record the canonical source and exact copied revision as one line each in `_strata/.kit-source` and
   `_strata/.kit-version`.

Project-owned or harness-native procedures may be routed from Project Instructions. Do not create a
universal project-skill directory, trigger-map format, or audit addendum merely to satisfy Strata.

## Thin harness routers

Root routers contain imports only; they carry no conduct rules and do not import harness dossiers or
Active Agent instruction files.

`AGENTS.md`:

```markdown
# Agent Instructions Router

Read and follow:

1. `_strata/universal_agent_instructions.md`
2. `_strata/project_instructions.md`

Project Instructions win on conflict. This file is only a router.
```

`CLAUDE.md`:

```markdown
# Agent Instructions Router

@_strata/universal_agent_instructions.md

@_strata/project_instructions.md
```

Before reporting initialization complete, verify the shared payload, required files, router edges,
authority graph, source/version markers, and generated Guide. Report literal check results and anything
intentionally left empty.
