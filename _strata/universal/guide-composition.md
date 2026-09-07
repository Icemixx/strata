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
layout — a reader wants *how a statement becomes a tax figure*, never *everything in `state/system/`*.

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

**When there is no code to watch, declare nothing and accept the warnings.** A rehearsal tree, an
authority-only handover, a directory the repository ignores — the expansion set comes from the
repository's own file list, so in all three every pattern matches nothing and refuses the whole
document. The warnings are then the honest state of that tree. **Never silence them by calling a
section `topic` when it is a workflow**: the kind is what tells a later refresh whether the section
tracks code at all, so falsifying it buys a clean run today and blinds the section permanently.

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
2. The identity line, and for a `workflow`, `architecture` or `module-family` section the watch
   surface naming the code it describes. Decide it here, with the subject in front of you, rather
   than leaving it to whatever silences a warning at the end.
3. A one-line lede saying what the section covers.
4. An opening paragraph explaining the thing in plain language, before any detail.
5. `h3` subsections for the parts, each opening with prose, then specifics.
6. Tables where the data is genuinely tabular — states, columns, layers, mappings, troubleshooting.
7. Notes carrying the reasoning a reader needs in order not to misread the design.
8. A `Files` table last: file, role, one row per implementing file.

**Folding is not available to a composed section.** The renderer folds only when it is rendering an
authority record in full, and it encodes markup as text, so a literal `<details>` reaches the page as
visible characters. A composed section is flat by construction. Put reference detail readers usually
skip at the end of the section, where it is out of the reading path without being hidden from it, and
keep every word: length is not the problem a fold would have solved.

### Density is the measure

This is the rule that gets missed, because everything else can pass while it fails, and unlike a threshold
you have to remember, it is a measure you compute from the records themselves.

**A record's sections together tend to run about as long as the record.** Measured on **one** mature
Guide — seventeen sections against the State records they were composed from — the median ratio was 1.01x
and the range 0.82x to 1.06x; a 339-word record became a 339-word section, a 1,057-word record became
1,058 words. The mechanism is plausible: a Guide explains what a record states, and explaining a fact in a
reader's terms costs about what stating it cost.

**One project is not a law, and this number is a diagnostic rather than a target.** Seventeen sections of
one Guide over one codebase cannot establish a ratio every application must hit. Use it to find sections
worth reading — a wide departure in either direction is a question to ask, not a fault to correct — and
never as a length to write to. A section padded or trimmed toward 1.0x explains worse than one left at the
length its subject actually needed, and the generator will hit the number either way.

Measure it against a record's **home** sections — the ones that cite it more than they cite anything
else — and never against the largest record a section happens to mention. Largest-cited is gameable from
both ends: a section scores badly because one sentence cites something big and unrelated, and any section
can look right by citing only small records. Splitting one record across three sections is fine; the
three are measured together.

**Around half the length of its records or below, a section has summarised its source instead of
explaining it.** That is the single most reliable signal that a Guide is a shell, and it needs no
predecessor document to compute: two agents working from this procedure produced 0.12x and 0.51x, against
1.04x for a Guide that reproduces its predecessor. This is the one place the ratio is more than a
diagnostic — not because a number was missed, but because at that length the explanation is absent rather
than short, which reading the section confirms in seconds. Everywhere above it, let the ratios be uneven:
one subject needs 1.3x and another 0.8x. Padding a thin section to reach a number is not depth either;
the fix is always more of what the record actually says.

**Scoring well on word count, table count and subsection count while writing 86-word passages
produces a reference card, not an explanation anybody reads through.** Breadth and depth are both
required; neither substitutes for the other. A section with one paragraph and a file list is not finished.

Where a guide already exists — an older manual, a retired document, a predecessor generation — **also
measure against it per section, not in total.** A total hides which sections collapsed.

**The records govern; a predecessor only adds a second reading.** Both comparisons are useful and they
answer different questions — did this section explain what its records hold, and did it keep what the
last document covered — but only the first is always available, so acceptance rests on it. Say which
comparison a reported number came from. A project with no predecessor is not missing a measurement.

### Detail to include

The difference between a thin section and a real one is these six kinds of content, not length:

- **Exact identifiers.** The folder, the share name, the flag, the registry value, the symbol. Name the
  thing, not the category of thing.
- **A reason attached to each specific.** *Users are granted Modify so a later un-elevated publish can
  write to it.* A specific without its reason reads as arbitrary and gets "cleaned up" by the next person.
- **Edge and failure paths**, with their real messages.
- **What is preserved, enumerated.** A reader needs the list, not the reassurance.
- **Dated behaviour changes.** When behaviour changed, say when — and that is the whole of what a
  date is for here. Keep a date when it tells a reader which builds behave which way; drop every
  ticket identifier, status, count, build id and commit, because those answer *what the project did*
  rather than *what the software does*, and they are wrong at the next refresh rather than merely
  old. "VAT is stored as an amount, not a rate, since 2026-08-03" belongs in the page. "TN-9 closed
  2026-08-03" does not.
- **Cross-references.** Say where a subject is covered rather than repeating it.

Also: sequences in order where order matters, states and conditions as tables, constraints and what
enforces them, and limitations stated plainly rather than omitted.

**Explanation carries its reasons.** The normal sentence shape is *what happens → why it happens that way
→ what consequence that has*. That is composition guidance, not a visible template: never emit repetitive
Why labels, and never invent a justification to satisfy the structure. Prefer product philosophy over
implementation mechanics — historical snapshots rather than silent rewrites, curated identities rather
than near-duplicate spellings, one atomic save rather than partial records. Exact method order and
repository internals belong in the end-of-section reference area unless a reader needs them to understand
a boundary. Not a fold: a composed section cannot fold, as "Section anatomy" says, so detail goes last
where it is out of the reading path without being hidden from it.

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
title         the document's own title is the one heading that carries no identity, and it qualifies
              only when it is level one, is the first heading in the file, and is followed by another
              LEVEL-ONE heading. A title followed by `## Something` is refused, because a level-two
              heading under it would have no group to belong to.
identity      every other level-one and level-two heading carries [[guide:section <id> <kind>]] on the next
              line. A level-three heading carries NONE: it belongs to the nearest identified level-one
              or level-two section, and giving it an identity is an error.
id and kind   the id matches [a-z][a-z0-9]*(?:[.-][a-z0-9]+)* and is unique in the document; the kind is
              exactly one of topic, workflow, architecture, module-family.
watch         a section whose kind is workflow, architecture or module-family declares
              [[guide:watch <glob>]] immediately after its identity line, before its first content
              block, naming the paths whose change makes the section stale. Every pattern must match
              a readable file; * may appear only in the final segment and ** only as the whole final
              segment; the bare ** is refused, because a staleness signal that is always red is one
              nobody reads. Omitting it only warns, and that leniency is not permission: **a section
              with no watch surface reports stale when someone edits its record and stays silent when
              the behaviour it describes is rewritten**, which is exactly the wrong way round. It is
              not the only freshness signal — a file named by a resolving [code:] citation is hashed
              independently, so editing cited code reports GUIDE_STALE with no watch declared at all.
              What a watch adds is the code the section does NOT cite: a sibling module, a file added
              later, the implementation a claim depends on without naming. Citations track what you
              pointed at; a watch tracks the surface. **The failure mode is
              inverted from everything else here**: omitting the directive warns, while declaring one
              that matches no readable file refuses the whole document. Declaring nothing is correct
              only where there is no code to watch at all, which is the case named earlier in this
              procedure; anywhere else the omission is the leniency being taken as permission.
              Expansion comes from the
              repository's tracked and non-ignored files, so a correct pattern starts failing the day
              its directory becomes git-ignored.
citations     every evidence-bearing block ends with a resolving reference -- [authority: <path>] or
              [code: <path>:<symbol>] -- or carries [[guide:exempt framing]] or
              [[guide:exempt illustration]]. Headings, navigation and literal code are not
              evidence-bearing.
anchors       [authority: <path>#<heading-slug>] points at one heading inside a record instead of the
              whole file, and the slug is validated against that file's headings. Prefer it: without
              it, a claim about the backup scheduler and a claim about the restore procedure cite the
              same two-hundred-line record indistinguishably. The slug is the heading lowercased with
              every run of characters outside [a-z0-9_] replaced by a hyphen and the ends trimmed, so
              `Startup Sequence (main.py)` becomes `startup-sequence-main-py`.
list items    a list item's citation belongs on that item's own line.
wrapping      a PARAGRAPH may wrap freely: continuation lines join it until a blank line, heading,
              fence, list marker, callout, directive or table, and one citation on its last line
              covers the whole paragraph. A LIST ITEM and a CALLOUT get no continuation, so each
              wrapped line is its own block and an uncited one fails the document. Wrap prose
              normally; keep a list item on one line however long it runs.
routed only   an [authority:] target must be a record the discovery graph routes to. A file that hangs
              off Instructions rather than State, Rationale or Build Log is not routable and is refused.
tables        a table may declare [[guide:table shared]] on the line AFTER the table, followed with no
              blank line by at least one citation line; its rows inherit that evidence, and a row may
              add to or override it with [[guide:row override]]. Without a shared set, every
              heterogeneous evidence-bearing row resolves on its own. A shared declaration may appear
              once per table and may not carry an exemption.
exemptions    an exemption FOLLOWS the block it exempts, on its own line. It cannot exempt a table
              row, cannot be doubled, and cannot sit on a block that also carries a citation.
```

**[code:] needs the code present.** It resolves only when the file exists in this checkout and the
named symbol occurs in its text; a bare path with no locator is refused. A tree holding authorities and
no product code -- a conversion rehearsal, an authority-only handover -- cannot use it at all, and every
claim must then rest on the record that asserts it. That is a real limit on such a tree, not a failure
of the composition: the Guide is only ever as checkable as what it was given.

Cite the authority for what a converted repository's records establish, and the code for what only the
implementation can establish. A guide with no citations cannot be checked by anyone who does not already
know the codebase; that is the one place a generated Guide must beat the manual it replaces.

## Before offering a version

- headings balanced, and every section named in the section record present, with the tables that record
  says it owns — the record set in "Deciding the sections" is what establishes the expectation, so there
  is something to check against rather than a remembered count;
- **zero externally loaded resources**, so it opens offline;
- no second encoding anywhere — see "What must not happen", which owns that rule;
- **per-section density measured against the records**, not totalled — and against a predecessor as well
  where one exists;
- **where a predecessor guide exists, no information loss against it** — every multi-word line of that
  document contiguously present. This does not apply to the authorities: a Guide that reproduced its
  records would be the mirror this procedure exists to prevent;
- a duplicated subject canonical in one section and cross-linked from the other — see "Detail to
  include", which owns that rule;
- **exact identifiers measured against the records the page cites** — every symbol, path, file and
  threshold a cited record names appears in the page, unless it falls in one of five kinds that
  belong to the record and not to a manual: a rejected alternative, a superseded value, a ticket
  identifier or status, dated evidence such as a commit or a run, or an internal of a retired system
  the record documents as gone. An absence outside those five is a drop.
  A composition drifts by turning names into descriptions: *on focus-out or Enter* for
  `editingFinished`, *the old wrapper* for the wrapper's name. Each is readable, none is searchable,
  and no other check notices, because the sentence is still true and still cited.

Generation plumbing is not reader content. Internal source paths, unavailable commit placeholders,
generator commands and staleness instructions stay out of **the sections you compose**; machine provenance
belongs in metadata. A closing note about how the Guide was generated is not an application subject.

**This governs composed content, not the wrapper.** The shipped shell prints a permanent snapshot notice
— which commit it came from, that it may be behind the authorities, and the `-GuideStatus` command that
checks — and `context-routing.md` requires exactly that. It is chrome, identical on every page, written by
nobody composing anything. The rule here is that a *section* must not explain how the Guide was made.

## What no check can catch

**A citation resolves whether or not the sentence above it is true, or even about this repository.** The
grammar proves a claim is attributed, never that it is right. Read the composed source before generating
it, and read it as a reader rather than as its author.
