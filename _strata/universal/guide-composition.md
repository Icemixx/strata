# Composing the Guide

Use this procedure when writing or refreshing `_strata/project_guide.md`, the composition source the Guide
is rendered from.

`context.ps1` never writes that file. It reads it, and branches: with a composition source, that file is
the document and the authorities are what it cites; without one, it renders every authority record in
full. **The fallback is valid output and it is not a manual** — one project's authorities rendered whole
came to 113,063 words of which 724 were explanation, 0.6%. Composing is an agent's job, done deliberately.

## Status: derived, never an authority

The Guide is written from the code and the authorities. It is never promoted to an authority, and nothing
is true only because the Guide says it. It repeats no record, owns no fact, and is safe to rewrite because
everything in it is recoverable from what it cites.

Write it for someone who has to understand the program. Sections follow the subject, not the authority
layout — a reader wants *how a statement becomes a tax figure*, never *everything in `state/software/`*.

## What must not happen

- **Do not mirror the authority hierarchy.** Agents read the authorities as Markdown already; a page that
  reproduces them has explained nothing.
- **Do not render ticket lists, dated history, or decision records.** Where a decision explains current
  behaviour, state the behaviour and its reason in the reader's terms. A status changes between refreshes,
  so a manual that copied one is wrong the moment it is read.
- **Do not reimplement logic in the page.** A guide that re-encodes a rule now owns a second copy of it,
  and copies diverge silently.
- **Nothing may be a second encoding of the software.** Text and tables describe it and can name their
  source. Diagrams and widgets re-encode it and cannot: a table of payment states carries
  `[code: domain/payment_status.py:classify_payment]`; an SVG of the same states carries nothing, cannot be
  diffed, and cannot be refused when its source moves. Uncheckable by construction is the one thing this
  design exists to prevent.

**Structural affordances are allowed anywhere** — collapsible groups, folded reference blocks, search,
anchors, a contents list. They encode the shape of the *document*, never a claim about the software, so
they cannot drift from it. The test for anything new: does it assert something about the software? Then it
is content — write it as text and cite it. Does it only help a reader move around? Then it is an affordance.

## Structure

Two levels, and the navigation shows both: **groups** and the **sections** inside them. Six groups over
eighteen sections is a worked example, not a quota — the count follows the product.

Sections are named for **what the application does**, never for the authority that described them.

### Section anatomy

1. `h2` — the subject.
2. A one-line lede saying what the section covers.
3. An opening paragraph explaining the thing in plain language, before any detail.
4. `h3` subsections for the parts, each opening with prose, then specifics.
5. Tables where the data is genuinely tabular — states, columns, layers, mappings, troubleshooting.
6. Notes carrying the reasoning a reader needs in order not to misread the design.
7. A folded `Files` table last: file, role, one row per implementing file.

Prose stays open; reference detail most readers skip is folded, and every word is retained. **A heading
level is not automatically a fold** — hiding a whole subject behind one control removes it from the
reading path.

### Density is the measure

This is the rule that gets missed, because everything else can pass while it fails. Aim for roughly **350
words per subsection**, and let them be uneven — one subject needs 600 and another needs 150, because that
is what each needs. Padding a thin section to match a thick one is not depth.

**Beating the target on word count, table count and subsection count while writing 86-word passages
produces a reference card, not an explanation anybody reads through.** Breadth and depth are both
required; neither substitutes for the other. A section with one paragraph and a file list is not finished.

Where a guide already exists — an older manual, a retired document, a predecessor generation — **measure
against it per section, not in total.** A total hides which sections collapsed.

### Detail to include

The difference between a thin section and a real one is these six kinds of content, not length:

- **Exact identifiers.** The folder, the share name, the flag, the registry value, the symbol. Name the
  thing, not the category of thing.
- **A reason attached to each specific.** *Users are granted Modify so a later un-elevated publish can
  write to it.* A specific without its reason reads as arbitrary and gets "cleaned up" by the next person.
- **Edge and failure paths**, with their real messages.
- **What is preserved, enumerated.** A reader needs the list, not the reassurance.
- **Dated behaviour changes.** When behaviour changed, say when.
- **Cross-references.** Say where a subject is covered rather than repeating it.

Also: sequences in order where order matters, states and conditions as tables, constraints and what
enforces them, and limitations stated plainly rather than omitted.

**Explanation carries its reasons.** The normal sentence shape is *what happens → why it happens that way
→ what consequence that has*. That is composition guidance, not a visible template: never emit repetitive
Why labels, and never invent a justification to satisfy the structure. Prefer product philosophy over
implementation mechanics — historical snapshots rather than silent rewrites, curated identities rather
than near-duplicate spellings, one atomic save rather than partial records. Exact method order and
repository internals belong in folded reference unless a reader needs them to understand a boundary.

## Deciding the sections

A repository does not announce what its sections are. Derive candidates from three mechanical sources —
**entry points** (what a person can actually do: screens, routes, commands), **domain modules** (subjects
the product has, not files it happens to contain), and **the authorities** (State tickets cluster by
subject; Rationale records name what was decided about).

**Grouping is judgement, not derivation.** No directory tree yields it. Propose the grouping and commit
to it.

**Sections need stable identity.** Record each section's id, title, group and owned paths, and let
regeneration read that record rather than re-deriving it. Renaming a section between versions breaks every
anchor and cross-reference, and per-section staleness cannot tell a rename from a rewrite. A section may
be added, split, merged or retired — but as a change to the record, never as a silent difference between
two generations.

## Composing in parallel

The seam is that **reading is mechanical and parallelises; writing is not.**

**Extract in parallel.** Divide the active scope into bounded assignments. Each reads every path it needs
and returns **facts, not prose**: exact identifiers, ordering rules and what breaks when the order is
wrong, edge and failure paths with real messages, what is deliberately absent and why, reasons attached to
specific values, and connections to other sections. Every fact carries a candidate citation whose symbol
the extractor verified occurs in the file it names. This is where depth comes from — an agent holding a
whole codebase reads headers; an agent holding one section reads implementations.

**Compose centrally.** One writer holds every extraction and writes the document. Three things fail if
composition is parallelised: cross-references die, because an agent that read one section cannot know
another exists to point at; duplicates diverge, because two agents describe one rule differently and both
citations resolve; and voice fragments, which is the unevenness the density rule exists to prevent.

A contradiction between two extractions is a finding to report, not a wording problem to smooth over.

**Bound the returned output mechanically and check it.** A fact ceiling nobody counts is not a ceiling.
Output ceilings do not bound reading, tool traffic or elapsed work — measure those separately, batch small
sections that share files into one assignment, and divide an oversized section along **end-to-end
workflows** rather than by layer, because a layer split severs the chain the Guide exists to explain.

## Read what implements, not what describes

Compose a section from the module that **implements** the subject. Treat a docstring or comment as a claim
to verify, not a source to quote.

A guide once stated *"there is no in-application updater"*, citing the file whose docstring said exactly
that — while a sibling module implemented auto-update. **The citation resolved and the claim was false.**
That is the declared limit of the mechanism arriving in practice: it cannot establish the correctness of a
source. Where a describing comment and the implementing code disagree, that disagreement is a finding to
report at its owner, never Guide content.

**Extraction findings are not Guide prose.** A stale docstring, a behavioural defect, a fragile safeguard:
persist them as actionable project work with evidence. Never write *"the docstring says X but the code
does Y"* into the Guide — that is a statement about the repository, not about the software. Do not smooth
a defect into an invented philosophy, and do not publish a claim the implementation disproves.

## The grammar

These fail an entire refresh rather than warning, so they are worth knowing before the first attempt.

```text
identity      every level-one and level-two heading carries [[guide:section <id> <kind>]] on the next
              line. A level-three heading carries NONE: it belongs to the nearest identified level-one
              or level-two section, and giving it an identity is an error.
id and kind   the id matches [a-z][a-z0-9]*(?:[.-][a-z0-9]+)* and is unique in the document; the kind is
              exactly one of topic, workflow, architecture, module-family.
watch         a section whose kind is workflow, architecture or module-family declares
              [[guide:watch <glob>]] immediately after its identity line, before its first content
              block, naming the paths whose change makes the section stale. Every pattern must match
              a readable file; * may appear only in the final segment and ** only as the whole final
              segment; the bare ** is refused, because a staleness signal that is always red is one
              nobody reads. A missing watch surface is a warning rather than a failure, which makes
              it the one rule a passing generation will not force you to obey.
citations     every evidence-bearing block ends with a resolving reference -- [authority: <path>] or
              [code: <path>:<symbol>] -- or carries [[guide:exempt framing]] or
              [[guide:exempt illustration]]. Headings, navigation and literal code are not
              evidence-bearing.
list items    a list item's citation belongs on that item's own line.
wrapping      a wrapped continuation line parses as its OWN block, so an item that wraps is an uncited
              block wherever its citation sits. Composition sources want long single lines -- the
              opposite of ordinary practice.
routed only   an [authority:] target must be a record the discovery graph routes to. A file that hangs
              off Instructions rather than State, Rationale or Build Log is not routable and is refused.
tables        a table may declare [[guide:table shared]] followed by its evidence, which its rows
              inherit; a row may add to or override it with [[guide:row override]]. Without a shared
              set, every heterogeneous evidence-bearing row resolves on its own.
```

Cite the authority for what a migrated repository's records establish, and the code for what only the
implementation can establish. A guide with no citations cannot be checked by anyone who does not already
know the codebase; that is the one place a generated Guide must beat the manual it replaces.

## Before offering a version

- headings balanced and the expected section and table counts present;
- **zero externally loaded resources**, so it opens offline;
- no second encoding anywhere — no diagram, widget or simulation;
- **no information loss** — every multi-word source line contiguously present;
- a duplicated subject canonical in one section and cross-linked from the other, never stated twice;
- **per-section density measured against the benchmark**, not totalled.
- **exact identifiers measured against the records the page cites** — every symbol, path, file and
  threshold a cited record names either appears in the page or was deliberately left to that record.
  A composition drifts by turning names into descriptions: *on focus-out or Enter* for
  `editingFinished`, *the old wrapper* for the wrapper's name. Each is readable, none is searchable,
  and no other check notices, because the sentence is still true and still cited.

Generation plumbing is not reader content. Internal source paths, unavailable commit placeholders,
generator commands and staleness instructions stay out of the visible page; machine provenance belongs in
metadata. A closing note about how the Guide was generated is not an application subject.

## What no check can catch

**A citation resolves whether or not the sentence above it is true, or even about this repository.** The
grammar proves a claim is attributed, never that it is right. Read the composed source before generating
it, and read it as a reader rather than as its author.
