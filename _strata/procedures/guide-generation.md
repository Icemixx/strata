# Generating the Guide

Use this procedure when the user asks to generate or regenerate the project Guide.

## What the Guide is

**One self-contained offline HTML file at `_strata/project_guide.html`, written for people.** It explains
the software: architecture, behaviour, workflows, operational runbooks, invariants and limitations.

**It is not an authority, because the code is.** Nothing is true because the Guide says it; it is true
because the implementation does, and the Guide explains it. A Guide that disagrees with the code is
regenerated, not reconciled.

**Agents read the code, not the Guide.** It is never loaded as agent context, so its size costs nothing
and its staleness cannot corrupt an agent's work. An agent needing technical context reads the
implementation and the records — the same sources the Guide is written from.

Generation is explicitly user-triggered. Never generate because code changed, because an authority
changed, or as part of initialization or conversion.

## Sources

Read the codebase, and read the project's records: Rationale for settled decisions and rejected
alternatives, Build Log for dated actions and observed results, State for current reality and open work.
Read the records in full; if one is too large to read whole, say in the report which parts you read.

The records are not optional. Code alone cannot distinguish a deliberate constraint from a defect. In the
measured case that established this, a Guide written from code alone reported three of that project's
settled decisions as bugs, each a trade-off with a recorded reopening condition. The records are also
where an operational procedure usually lives, including the parts learned the hard way.

**Never read a previous Guide, in any form.** Not the one you are replacing, not an archived predecessor,
not a converted copy of one. After the first generation there is always a previous Guide, and a generator
that reads its own last output compounds drift until nothing traces to anything. A previous Guide is
output, never input.

## What a claim must carry

**Cite the implementation for any claim that can drift** — behaviour, defaults, thresholds, paths, schema,
exit codes, configuration keys, failure messages. Inline and visible to the reader:

```text
[code: <repository-relative-path>:<symbol>]
```

The symbol must literally occur in the cited file. **Never cite a line number**: a line citation is broken
by the same edit that made it worth writing.

**Verify every citation before presenting the Guide.** Open each cited file and confirm the symbol occurs.
An unresolvable citation is worse than none, because it looks checked and is not. Report the literal
counts: citations, distinct files, resolved, unresolved.

A citation proves attribution, never truth. The sentence above a resolving citation can still be wrong.
Say so where it matters; only a person or an audit establishes truth.

Do not cite general narrative, product description, or a reason that lives in Rationale rather than in
code.

## Outbound references are literal paths, never hyperlinks

The Guide must open correctly with no repository present — from a copy, an attachment, a memory stick. A
relative hyperlink resolves only inside a checkout, so hyperlinking silently trades that away.

Write a record reference as literal text, and only to paths the layout guarantees: `_strata/state/index.md`,
`_strata/state/current.md`, `_strata/rationale/index.md`, `_strata/build-log/index.md`.

**Never reference an individual ticket, decision or record.** Tickets move to completed storage when they
close and the Guide is regenerated rather than maintained, so nothing repairs the reference in between.
Where a specific decision matters, name it in prose — "decided 2026-08-03, recorded in
`_strata/rationale/index.md`" — which a reader can follow and which cannot rot.

Every `<a href>` in the output is an internal anchor beginning with `#`.

## Provenance

Immediately before `</body>`, embed exactly one:

```html
<script type="application/json" id="strata-guide-provenance">{ … }</script>
```

containing `generated_at` (UTC ISO-8601), `generation_commit` (the full or short Git hash, or the literal
`unavailable`), and `citations`: one `{path, sha256}` entry per distinct cited file, hashed as found.

This is what later reports *which* cited files have changed since the Guide was written, per file, rather
than a single stale flag that says nothing actionable.

## Writing it

Organise by what the application does — subjects a person would look for, never repository folder names.
Let the codebase decide the real sections.

Depth is the point. Exact identifiers rather than categories. A reason attached to each specific, because
a value without its reason reads as arbitrary and gets "cleaned up" by the next maintainer. Edge and
failure paths with their real messages. What is preserved, enumerated. States, mappings and options as
tables. Constraints and what enforces them. Limitations stated plainly rather than omitted. Operational
runbooks as steps a person can follow.

Prefer *what happens, why it happens that way, and what follows from it* over narrating implementation
line by line.

**Never invent a fact.** Where neither code nor records establish something, say so in the text rather
than filling the gap plausibly. **Read what implements, not what describes**: a docstring is a claim to
verify, not a source to quote, and where it disagrees with the code the code wins and the disagreement is
reported. **Report contradictions rather than resolving them** — between two parts of the code, or between
a record and the code. A dated record is evidence of what was true then.

Never carry a credential, token or personal setting into the Guide.

## The artifact

Inline CSS and JavaScript only. No externally loaded script, stylesheet, font, image, frame or CSS
`url()`. Unique element ids. Internal anchors all resolving. Readable at phone width as well as desktop.
Semantic structure and stable headings, so links into it survive regeneration.

## Before presenting it

State literally: citation counts and their verification result; that every `<a href>` is an internal
anchor and no outbound hyperlink exists; that no external resource is loaded; that ids are unique and
anchors resolve; that no credential reached the output. Report what you could not establish from either
source, and every contradiction found.

Say plainly that mechanical correctness is not truth. The Guide corresponds to what you read; whether what
you read is right about the application is a separate question that this procedure does not answer.
