# Instruction topology — bounded startup context and verifiable authorities

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file,
announce it with one visible line: `loaded: _agents/universal/instruction-topology.md`. Load while
initializing or retrofitting the instruction system, changing a router or instruction audience, or
implementing `AGENT_SYSTEM_CHECK`.

## The topology

One logical **Instructions authority** has two current, disjoint audiences and one historical appendix:

| File | Audience | Contract |
| --- | --- | --- |
| `_agents/project_instructions.md` | every session and delegated worker | Worker-imperative project rules, protocol parameters, and the sole conditional trigger that tells a top-level session to load the supervisor file. |
| `_agents/project_instructions_supervisor.md` | top-level session only | Project-specific supervision, routing, integration, and certification rules that a terminal worker cannot use. |
| `_agents/project_instructions_archive.md` | on demand only | Historical incident narrative. It is never current authority, loses to the two current files, and is never loaded at startup. |

These are not three competing authorities. A rule has exactly one current home according to audience.
If both audiences need it, it belongs in `project_instructions.md`; the supervisor file may point to it
but must not restate it. Keep the imperative current and move only spent narrative to the archive.

The top of `project_instructions.md` must say, in substance:

```markdown
If you are the top-level session, read `_agents/project_instructions_supervisor.md` after this file.
A delegated worker must not read that file or `_agents/project_instructions_archive.md`.
```

Routers remain bare. They load the universal core, `project_instructions.md`, and—where the kit defines
one—only their own universal harness adapter. A router must never import either project supervisor file
or either archive. The conditional line above is the only project-supervisor activation edge.

## Required project-native checker

Every consuming repository declares this protocol parameter in `project_instructions.md`:

```text
AGENT_SYSTEM_CHECK = <one repository-native command>
```

The same executable exposes its permanent negative-contract suite as
`<AGENT_SYSTEM_CHECK> --self-test`; do not create an unnamed second invocation. Self-test uses only
disposable fixture trees, applies one mutation at a time, asserts the expected diagnostic and exit,
and restores or discards the fixture before returning.

The command is deterministic and non-interactive. Its stable result contract is:

- exit `0`: every deterministic source check passed;
- exit `1`: one or more source contracts failed;
- exit `2`: the checker could not perform a required measurement because an input or required local
  capability was unavailable. This is not a pass.

Output names each check and ends with one of `SOURCE_PASS`, `SOURCE_FAIL`, or `SOURCE_UNAVAILABLE`.
Diagnostics use stable codes so tests and humans can identify the violated contract without matching
explanatory prose. The checker must cover, at minimum:

1. bare routers and their actual import edges;
2. `.kit-source`, `.kit-version`, canonical file inventory, and normalized-content agreement when a
   canonical tree is supplied for comparison;
3. required project authorities, supervisor files, and archive headers/audience exclusions;
4. unique ticket identifiers across State and its archive;
5. compact closed-ticket grammar, strict status/gate consistency, and archive-body contracts;
6. local resolution of every `COMMIT:<oid>` provenance citation and the complete evidence target for
   every allowed evidence-only citation;
7. Guide structure and any project-specific contracts declared by the project;
8. every supported worker startup chain and its context budget.

The repository keeps permanent tests for this checker. Important invariants need one watched-red fixture
each: mutate one condition, observe the expected diagnostic and nonzero exit, then restore it. Include
missing files, router drift, archive/header drift, duplicate ticket IDs, a full body left in State after
closure, `DONE` with an outstanding owned gate, unresolved or foreign commit citations, malformed
evidence-only provenance, a body-sensitive violation after its body moved to the archive, CRLF
equivalence, every supported route, and context-headroom failure. A checker and a test that merely share
the same hard-coded import list can drift green together; derive declared chains from one project-owned
manifest and verify that manifest against the routers' actual syntax.

## Context-budget measurement

Declare every supported worker route explicitly. This kit supports Codex and Claude Code. A router or
integration for another harness does not make that harness supported and must not create a source or
empirical certification gate; support begins only when the kit explicitly adds its router or adapter
contract and the canonical repository completes route-contract plus empirical certification. Measure each supported route
independently from the files its real startup behavior loads. The standard routes are:

- Codex: `AGENTS.md` + universal core + project worker instructions + Codex harness adapter;
- Claude Code: `CLAUDE.md` + universal core + project worker instructions + Claude adapter.

Do not infer one route from another. Before counting, decode text as UTF-8 (an optional UTF-8 BOM is not
content), reject invalid encoding or lone carriage returns, normalize CRLF to LF, and then count UTF-8
bytes. Detect duplicate imports rather than counting a file twice silently. Report every component,
excluded file with reason, route total, maximum route, ceiling, and remaining headroom.

The default ceiling is `22,000` normalized bytes and the mandatory safety reserve is `500` bytes, so a
route passes only at `21,500` bytes or below. The maximum route governs. A project override must name
the affected route, new ceiling, owner, reason, approval date, and review/removal condition; changing a
constant or reducing the reserve is not an override.

## Project source verification and canonical harness certification are different scopes

`AGENT_SYSTEM_CHECK` proves each consuming repository's deterministic source topology: its copied kit,
project-owned routers, manifest, authorities, and route budgets. Every project runs that check and its
self-test. It does **not** re-certify Claude Code or Codex as products.

Harness compatibility is certified once in the canonical repository's root `CERTIFICATION.md`, which is
not part of the copied payload. A supported route enters or remains in the kit only when that canonical
record has `CANONICAL_EMPIRICAL_PASS(<route>)`. Repeat the empirical probe only when the route's router
template, harness adapter, startup-chain contract, or relevant harness behavior changes—not for every
initialized repository.

Canonical recertification uses a disposable neutral fixture initialized from the kit. A fresh top-level
session starts one terminal worker with a zero-tool prompt asking only which startup instruction files it
received. The supervisor records the literal prompt and structural result. Before publication, normalize
fixture and user-local roots to placeholders and remove person, machine, consuming-repository, private
ticket, agent-id, and model-build identifiers. Disclose harness-injected files outside the repository,
but do not count their environment-specific size as portable kit-budget evidence.

Project completion therefore uses `SOURCE_PASS`; canonical route admission uses
`CANONICAL_EMPIRICAL_PASS(<route>)`. A same-session spawn or working chat is diagnostic only and cannot
be used for canonical admission evidence.

## Adoption transaction

1. Publish and verify a project-agnostic canonical-kit commit under the hard boundary in
   `kit-editing.md`. Never place consuming-project names, paths, ticket IDs, incident text, private
   tools, user wording, stack-native commands, or project implementation choices in the public kit.
2. In the consuming repository, record the pre-migration project commit, canonical remote, and canonical
   SHA; sync the complete universal set, write the remote to `_agents/.kit-source`, and write the SHA to
   `_agents/.kit-version`.
3. Create the project supervisor and archives; split current instructions by audience; move historical
   material verbatim; repair every body-sensitive check.
4. Implement the project-native checker and watched-red tests before bulk compaction, so the migration
   can test itself.
5. Apply the closure transaction from `work-batch.md` to closed State items. Reclassify contradictory
   `DONE` entries before moving them.
6. Confirm the canonical root certification record supports every declared route. Run the source
   checker, `<AGENT_SYSTEM_CHECK> --self-test`, and project test suite, then commit and push the source
   migration. Do not create a project ticket to repeat canonical harness certification.

Rollback uses `git revert`, never destructive reset. Preserve archives and the pre-migration commit so
all moved text remains recoverable. Build Log and Rationale are not split: their tail-first and
register-based startup reads are already bounded.
