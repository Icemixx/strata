# Composing the Guide

Use this procedure when writing or refreshing `_strata/project_guide.md`, the composition source the Guide
is rendered from.

`context.ps1` never writes that file. It reads it, and branches: with a composition source, that file is
the document and the authorities are what it cites; without one, it renders every authority record in
full. The fallback is valid output and it is not a manual — on a large repository it produces a document
several hundred times the size of a composed one. **Composing is an agent's job, done deliberately.**

## What the source is

A Markdown document that explains the software to a reader, in which every claim points at the authority
that holds it. It is derived and non-authoritative: it repeats no record, owns no fact, and is safe to
rewrite because everything it says is recoverable from what it cites.

Write it for someone who needs to understand the program, not for someone auditing it. Sections follow the
subject, not the authority layout — a reader wants "how a statement becomes a tax figure", not "everything
in `state/software/`".

## The rules that only appear when generation refuses

Each of these fails the whole refresh rather than warning, so they are worth knowing before the first
attempt rather than after it.

```text
identity      every level-one and level-two heading carries [[guide:section <id> <kind>]] on the next
              line. A level-three heading carries NONE: it belongs to the nearest identified level-one
              or level-two section, and giving it an identity is an error.
id and kind   the id matches [a-z][a-z0-9]*(?:[.-][a-z0-9]+)* and is unique in the document; the kind is
              exactly one of topic, workflow, architecture, module-family.
citations     every evidence-bearing block ends with a resolving reference -- [authority: <path>] or
              [code: <path>:<symbol>] -- or carries [[guide:exempt framing]] or
              [[guide:exempt illustration]]. Headings, navigation and literal code are not
              evidence-bearing.
list items    a list item's citation belongs on that item's own line.
wrapping      a wrapped continuation line parses as its OWN block, so an item that wraps is an uncited
              block wherever its citation sits. Composition sources want long single lines -- the
              opposite of ordinary Markdown practice here.
routed only   an [authority:] target must be a record the discovery graph routes to. A file that hangs
              off Instructions rather than State, Rationale or Build Log is not routable and is refused.
tables        a table may declare [[guide:table shared]] followed by its evidence, which its rows
              inherit; a row may add to or override it with [[guide:row override]]. Without a shared
              set, every heterogeneous evidence-bearing row resolves on its own.
```

## What no check can catch

**A citation resolves whether or not the sentence above it is true, or even about this repository.** The
grammar proves that a claim is attributed, never that it is right. Two drafts written from finished
authorities used a sibling project's vocabulary — one named the wrong query-module suffix, the other
described an entity the product does not have — and both cited correctly while doing it.

Read the composed source before generating it, and read it as a reader rather than as its author.

## Refreshing

Cite State and Rationale; do not restate a ticket. A status changes between refreshes, so a manual that
copied one is wrong the moment someone reads it. Point at the authority and let the reader follow.

Section identity survives heading edits, so rename a heading freely while the section still owns the same
subject. Create a new id when ownership changes materially, and never reuse a retired id for a different
subject — the manifest carries sections forward by identity, and a reused id silently attaches the old
provenance to new content.

`-GuideStatus` reports what changed and by section. A section whose authored Markdown and cited targets are
both unchanged carries forward verbatim, so an ordinary refresh recomposes only what moved.
