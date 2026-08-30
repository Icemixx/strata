# Shared-kit editing and synchronization

Use this procedure when changing the canonical Strata payload or synchronizing a consuming repository.

## Boundary

The shared payload is exactly `_strata/universal_agent_instructions.md` plus every regular file under
`_strata/universal/`. It remains project-, product-, stack-, and repository-agnostic. Generalize a
project discovery before proposing it for the shared kit; keep project-specific realization in Project
Instructions or project records.

The canonical repository is the source. Consuming repositories hold copies identified by
`_strata/.kit-source` and `_strata/.kit-version`. Never edit a consuming copy incidentally during
project work. A canonical change or a consuming-repository sync requires deliberate authorization for
that scope.

Each `harness-<product>.md` is owned by an agent running that product. **Do not write a claim about
another harness's runtime into its dossier.** How it identifies its model, where its sessions live, what
its delegation and permission mechanisms do - only an agent running it can test any of that. When another
harness's dossier needs a runtime claim added or corrected, write the prompt and give it to the user, who
carries it to that agent.

You may still read any dossier, correct a path or format the kit itself changed, and record that a claim
is unverified or disputed. Flagging a claim is not asserting one, and a dossier nobody can currently reach
should carry the doubt rather than keep the error silently.

## Canonical change

Audit source files and inbound references before relocation or removal. Update one normative owner per
rule, run checks relevant to the shared payload, and distinguish a local edit from an authorized commit
or publication.

Before accepting a new or changed contract, ask where two competent agents following the same text would
produce different results, and pin every such point. Name the file, the format, and the location rather
than the intent.

Then stop imagining the other agent and run it. **A contract another harness must execute is not accepted
until that harness has executed it.** The test costs one round-trip through the user: pay it for anything
a second harness must execute; a change only your own harness runs does not need it.

After a canonical payload change, tell the user which consuming repositories still require a separate
sync. Do not retrofit them as part of the canonical transaction.

## The payload is copied, never described

Updating the kit is a pull and overwrite, every time and in every repository. A consuming repository must
never require an edit because the canonical payload gained, lost, or renamed a file.

A project check may require by name the few payload files its routers depend on, and may compare the
installed payload against a canonical checkout. It must not declare the payload inventory, enumerate the
on-demand procedures, or hardcode a procedure filename in a rule or test fixture. Derive the inventory
from the payload directory and let the canonical comparison own set equality: a declared list is a stale
copy of the directory it claims to describe, so it fails on the next release instead of on a real defect.

Express router rules as what a router may import - the shared core and project-owned files - rather than
as a list of payload files it may not.

## Consuming-copy sync

Verify the configured source and target revision. Replace only the complete shared payload; preserve all
project-owned instructions, authorities, provenance markers, routers, and other files. Compare relative
file inventory and normalized content against the canonical source, then update `.kit-version` only to
the exact revision actually copied. Report changed, added, removed, and mismatched payload files.
