# Strata

Strata is a small, project-agnostic instruction and context-routing kit for repository-based Codex and
Claude Code work. It separates always-loaded conduct from project knowledge that agents route only when
the task needs it.

## Context model

- **Instructions** govern conduct and routing. They are the only general startup context.
- **State** records WHAT is current, using compact ticket entries and routed completed history.
- **Rationale** records WHY decisions were made.
- **Build Log** records HOW work was performed and the evidence observed.
- **Guide** is a self-contained HTML explanation of the software, written by an agent from the code and
  those records when the user asks for it. It is not an authority, because the code is what makes a
  technical claim true. Nothing reads it as context; it is written for people.
- **`_sediment/`** holds project material that is not an authority: deliberation at its root, retained
  specifications under `specs/`, stable domain material under `reference/`. It is not routed, and every
  file a record still needs is named by that record.

Each authority is a recursively indexed Markdown tree. Every routed directory has an `index.md`, and
only described links inside `## Contents` define ownership and traversal.

## Shared payload

Copy exactly this, and copy it by the directory rather than by the list below:

```text
_strata/
|-- core.md
`-- procedures/           # every regular file in it, whatever they are today
```

**The payload is whatever `_strata/procedures/` contains**, plus
`_strata/core.md`. This README used to enumerate it, and by the time anyone
noticed, the list had drifted two files behind the directory — omitting `guide-composition.md` and
`spec-building.md`, so "copy exactly" would have installed a kit whose routers point at procedures that
are not there. `kit-editing.md` states the rule this violated: *a declared list is a stale copy of the
directory it claims to describe, so it fails on the next release instead of on a real defect.* It applied
to the README all along.

The payload is copied unchanged. Project rules and authorities remain project-owned. A consuming
repository records the canonical source and synced revision in `_strata/.kit-source` and
`_strata/.kit-version`.

## Initialize a new repository

Read `_strata/procedures/initialize.md`. It creates thin root routers, Project Instructions, and the State,
Rationale, and Build Log roots and indexes. **It does not generate a Guide.** A new repository's
authorities are empty, and a Guide over them explains nothing while looking finished; having no Guide is
the correct state until there are records and the user asks.

Established repositories do not use the empty-repository procedure. They require a separately authorized,
project-specific archive-seeded migration that preserves and reconciles their legacy material before
cutover.

## Guide

`_strata/project_guide.html` is written by an agent from the code and the records, only when the user asks,
under `_strata/procedures/guide-generation.md`. Ordinary code and authority changes do not regenerate it.

## Validation

The kit is Markdown only. It ships no scripts, validator, or test suite. The agent that changes a record
keeps the authority graph valid; `_strata/procedures/context-routing.md` lists what that covers.

## What this repository holds

The kit and nothing else: the payload, this README, the two routers, the licence and the git control
files. Project work lives in each consuming repository, in its own records.

Working material — plans, audits, trials and evidence — used to live in a nested `workbench/` repository
here. Both it and its remote were deleted on 2026-09-20, once the Guide capability it was carrying had
reached the kit and the remaining work had been filed as tickets in the consuming repositories. What it
concluded survives in this kit and in those repositories' records; the working material itself does not.

## Canonical editing

Read `_strata/procedures/kit-editing.md` before changing or synchronizing the shared payload. Canonical
editing, consuming-repository synchronization, and commit are separate authorization boundaries. Push is
not a fourth: Active Agent Instructions own that rule, and they say an authorized commit carries its push
unless the user asks for a local-only one.
