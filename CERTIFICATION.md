# Supported harness certification

This canonical-repository record is not part of the copied universal payload. It records compatibility
of the kit's route contracts with the supported harnesses. Consuming repositories verify their own
installed source topology and budgets; they do not repeat harness-product certification.

## Current status

| Harness | Route | Status |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` | `CANONICAL_EMPIRICAL_PASS(claude-code)` |
| Codex | `AGENTS.md` | `CANONICAL_EMPIRICAL_PASS(codex)` |

Certified 2026-08-24 against the current two-route topology.

## Probe contract

A fresh top-level session in each harness spawned one terminal worker with no inherited conversation.
The worker received this literal zero-tool prompt:

```text
You are a terminal worker. Which startup instruction files did you receive? Do not call any tools. Reply only with the file paths, one per line.
```

The evidence below is normalized deliberately: consuming-repository roots become `<fixture-root>` and
user-local roots become `<user-local-root>`. No person, machine, consuming repository, private ticket,
agent identifier, model build, or absolute path belongs in canonical evidence.

### Codex

Normalized reported repository files, in order:

```text
<fixture-root>/AGENTS.md
<fixture-root>/_agents/universal_agent_instructions.md
<fixture-root>/_agents/project_instructions.md
<fixture-root>/_agents/universal/harness-codex.md
```

Verdict: the complete declared Codex chain was present and no project-supervisor or archive file was
reported.

### Claude Code

Normalized reported repository files, in order:

```text
<fixture-root>/CLAUDE.md
<fixture-root>/_agents/universal_agent_instructions.md
<fixture-root>/_agents/project_instructions.md
<fixture-root>/_agents/universal/harness-claude-code.md
```

The harness also reported one user-local memory index outside the repository:

```text
<user-local-root>/memory/MEMORY.md
```

Verdict: the complete declared Claude Code chain was present and no project-supervisor or archive file
was reported. A harness-injected user-local file is not a repository route edge. It must be disclosed by
a certification probe, but its environment-specific size is not portable kit-budget evidence.

## Recertification rule

Recertify a route only when its canonical router template, harness adapter, startup-chain contract, or
relevant harness behavior changes. Run future probes in a disposable neutral fixture initialized from
the canonical kit. Publish only normalized structural evidence here; keep raw environment-specific
artifacts outside the public kit.
