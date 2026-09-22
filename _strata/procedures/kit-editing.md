# Shared-kit editing and synchronization

Use this procedure when changing the canonical Strata payload or synchronizing a consuming repository.

## Boundary

The shared payload is exactly `_strata/core.md` plus every regular file under
`_strata/procedures/`. It remains project-, product-, stack-, and repository-agnostic, and agent-agnostic
apart from the `harness-<product>.md` dossiers, which exist to carry exactly those differences. Generalize a
project discovery before proposing it for the shared kit; keep project-specific realization in Project
Instructions or project records.

The canonical repository, `https://github.com/Icemixx/strata.git`, is the source. Consuming repositories
hold copies, and each records the canonical commit it installed in its own Build Log. Never edit a
consuming copy incidentally during project work. A canonical change or a consuming-repository sync
requires deliberate authorization for that scope.

Each `harness-<product>.md` is owned by an agent running that product. **Do not write a claim about
another harness's runtime into its dossier.** How it identifies its model, where its sessions live, what
its delegation and permission mechanisms do - only an agent running it can test any of that. When another
harness's dossier needs a runtime claim added or corrected, write the prompt and give it to the user, who
carries it to that agent.

**The dossiers stay level.** They carry the same section headings, in the same order, so the two can be
read side by side and a gap in one is visible. Content differs - that is what they are for - but structure
does not. When you record a runtime fact in your own dossier, check whether its counterpart exists in the
other; if it does not, and the fact has an analogue there, route a prompt to that harness rather than
guessing at its behaviour or leaving the gap silent.

You may still read any dossier, correct a path or format the kit itself changed, and record that a claim
is unverified or disputed. Flagging a claim is not asserting one, and a dossier nobody can currently reach
should carry the doubt rather than keep the error silently.

Then stop imagining that agent and ask it. **A claim about another harness's runtime is not accepted until
an agent running that harness has confirmed it**, and the test costs one round-trip through the user. This
is scoped to runtime difference, not to reach: a procedure every harness executes -- composing a Guide,
routing a record, consolidating -- is ordinary shared-kit work and needs no second harness to accept it.

## Canonical change

Audit source files and inbound references before relocation or removal. Update one normative owner per
rule, run checks relevant to the shared payload, and distinguish a local edit from an authorized commit
or publication.

Before accepting a new or changed contract, ask where two competent agents following the same text would
produce different results, and pin every such point. Name the file, the format, and the location rather
than the intent.

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

**Run this in the consuming repository, never in canonical.** It is a pull: the consuming repo overwrites
its own payload from the canonical repository and records the commit it installed in its own Build Log.

**A sync is: compare the installed commit with the live one; if they differ, overwrite the local copy and
record the new commit.** That is the whole operation. Four steps:

1. Read the installed commit: the newest-dated Build Log heading of the form
   `## Strata sync <commit> (<YYYY-MM-DD>)`, anywhere under `_strata/build-log/`. `<commit>` is the
   canonical commit's 7-character short hash, as GitHub shows it.
2. Read the live commit: the first 7 characters of
   `git ls-remote https://github.com/Icemixx/strata.git HEAD`. If it equals the installed commit, stop;
   there is nothing to sync. No such heading at all means sync.
3. Delete exactly `_strata/core.md` and `_strata/procedures/`, then copy both in from canonical at the live
   commit. Delete before copying, or a file canonical removed lingers. Replace nothing else under
   `_strata/` — Project Instructions, the routers, and the authority directories are project-owned, and a
   sync that rewrites one of them has overwritten the project with the kit.
4. Append a Build Log entry headed `## Strata sync <commit> (<YYYY-MM-DD>)` with the live commit and the
   sync date, for example `## Strata sync a3872f6 (2026-09-22)`. The heading is the whole required entry.
   Report `git status`; that is the report.

Two syncs on the same date need no ordering rule. Canonical only moves forward, so reading the older of the
pair costs at most one redundant sync, never a missed one.

**Do not add a verification pass.** Not a drift check before overwriting, because the copy is about to
replace whatever it would find. Not a review of the incoming diff, because canonical reviewed it when it
was committed. Not a search for inbound references to renamed payload headings, because the section above
already guarantees a consuming repository never needs an edit for one. Not a re-comparison after copying,
nor a control demonstrating that such a comparison works.

Deleting before copying is what makes the inventories equal, so nothing has to confirm afterwards that
they are. The evidence rules in `core.md` govern work that *authors* a change; a sync authors nothing, it
installs bytes canonical already reviewed, and `git status` is the literal result. One consuming
repository's sync took thirty-three tool calls for an operation of a few steps, because this section
read as a comparison problem and every clause above was absent.
