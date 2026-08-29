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

## Canonical change

Preserve unrelated work. Audit source files and inbound references before relocation or removal. Update
one normative owner per rule, run checks relevant to the shared payload, and distinguish a local edit
from an authorized commit or publication. Publication is never implied by kit editing.

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
