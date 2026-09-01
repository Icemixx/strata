# Specification building

## Purpose

Use this procedure to create, revise, or confirm a retained specification, regardless of whether its
inputs came from a user discussion, investigation, audit, DAP, debate, existing design, or another
specification.

A specification is a cold-start implementation contract. A capable agent that did not participate in
the work that produced it must be able to implement it without reading chat history, provider sessions,
temporary deliberation artifacts, or the author's mind. A document that still requires a new
architectural decision is a draft, not an implementation-ready specification.

Writing or confirming a specification does not authorize implementation, migration, synchronization,
commit, publication, external action, or cleanup. Those remain separate scopes.

## Trigger and inputs

Run this procedure only when the user explicitly requests a specification or another routed procedure
requires one. Agreement, a completed analysis, or a converged discussion does not otherwise authorize
writing a specification.

Before drafting:

1. Name the requested outcome and the exact implementation scope.
2. Inventory the inputs that carry requirements, decisions, reasons, measurements, or constraints.
3. Verify material claims against available primary artifacts. Mark inference and unavailable evidence;
   do not silently promote either to fact.
4. Extract an itemized input ledger. For a debate this includes every settled item; for another source it
   includes every explicit requirement and accepted decision.
5. Identify the live implementation baseline and inspect the files the specification proposes to change.
   Record drift-sensitive observations as a baseline to recheck, not timeless truth.

The caller owns source-specific lifecycle. This procedure does not decide whether an audit closes, a
debate branch is deleted, an authority changes, or an older specification is superseded.

## Provenance recovery for an inherited specification

When an existing specification is not self-contained, start with that document, its explicit references,
and the live implementation baseline. Do not begin with an arbitrary chat date window or assume that the
latest session contains the origin of every requirement.

Inspect the most direct producing input first, then trace backward only where a load-bearing requirement
lacks its decision, reason, or evidence. Follow referenced sessions or artifacts beyond the initial time
window when necessary. Stop when every such requirement has a verified source, an explicit inference, an
unavailable-evidence disposition, or a named unresolved decision. Record the sessions or other inputs
inspected, their relevant time range, and any discovery limitation that could have hidden material context.

This is a repair path for inherited specifications, not a normal implementation dependency.

## Draft and confirmation state

Put one exact marker near the top of the document:

```text
SPECIFICATION: draft
```

Replace it only after every gate in this procedure passes:

```text
SPECIFICATION: confirmed — implementation-ready
```

`draft` is an honest working state, not an implementation handoff. Unresolved implementation-blocking
choices, missing inputs, or unverified load-bearing claims keep the marker at `draft`.

Unless the user or calling procedure selects another path, write the retained document at
`_sediment/<subject>-spec.md`. The exact path must be known before inbound references are created.

## Content contract

Headings may fit the subject, but the document must contain enough explicit information to answer all of
the following without its source conversation:

- **Outcome:** What observable result is being built, and for whom?
- **Scope:** Which repositories, components, files, interfaces, and data are in scope? What is deliberately
  excluded? Which adjacent action needs separate authorization?
- **Baseline:** What exists now, which behavior must survive, and what must be rechecked for drift before
  editing?
- **Decisions and reasoning:** What was decided, why, which alternatives were rejected, and which measured
  or observed evidence made the conclusion load-bearing?
- **Exact contract:** What paths, formats, schemas, syntax, identifiers, ordering, defaults, state
  transitions, error classes, atomicity, and recovery behavior apply? Include only applicable dimensions,
  but pin every dimension on which two conforming implementations could differ materially.
- **Implementation sequence:** What changes first, what depends on it, and where must the implementer stop
  rather than cross a scope boundary?
- **Validation:** Which positive and watched-red cases prove each invariant? Name applicable commands,
  fixtures, expected signals, and preservation checks. A check is not evidence for a behavior it never
  exercises.
- **Completion:** What exact conditions make the implementation complete, and which results would leave it
  partial or blocked?
- **Limits:** What the mechanism cannot prove and what remains a human review responsibility.

Retain the reasoning and measurements needed to understand and safely revise the contract. Remove debate
turn order, rhetoric, speaker history, and other process residue. Native session identifiers may be
optional audit provenance, but no required instruction or rationale may exist only in those sessions.

Do not turn an experiment into a universal rule. State which observations establish a contract, which
only demonstrate feasibility, and which remain provisional.

## Traceability gate

Map every input-ledger item to one of these dispositions:

- implemented by a named section of the specification;
- deliberately excluded, with the owning boundary and reason;
- unresolved, with the exact decision still required; or
- unavailable or unverified, with the effect on readiness.

The mapping may be a compact table in the specification or a mechanically checked companion used during
drafting, but a confirmed specification must retain every exclusion, unresolved item, and readiness-
affecting evidence gap in the document itself. An input that silently disappears fails confirmation.

An unresolved item may be non-blocking only when the specification defines a deterministic default and
the item's resolution cannot change compatibility, safety, externally visible behavior, stored data, or
the acceptance result. Otherwise the specification stays `draft`.

## Cold-start ambiguity gate

Review the draft as though the source material no longer exists:

1. For each instruction, ask where two competent agents could make different choices while both claiming
   compliance.
2. Pin each material choice by behavior and, where applicable, file, location, representation, and failure
   result. Intent alone is not a contract.
3. Search for placeholders and disguised decisions such as `TBD`, `as appropriate`, `for example`,
   `where needed`, an unexplained `etc.`, or a choice deferred to the implementer. Resolve or explicitly
   disposition each occurrence.
4. Check that referenced paths, symbols, commands, and fixtures exist, or are explicitly identified as
   outputs to create.
5. Check that the validation plan can fail for every required behavior before trusting its passing form.
6. Confirm that no step requires opening the source chat, session, debate branch, or temporary report to
   discover what to do.

Do not elevate reversible internal engineering choices into user decisions. A choice blocks confirmation
only when different conforming implementations could materially change compatibility, safety, stored data,
recovery, externally visible behavior, or the acceptance result, or when the user explicitly retained that
choice. Leave other representation and implementation mechanics to the implementer within the pinned
contract.

If any material ambiguity remains, keep `SPECIFICATION: draft` and return the smallest decision set to the
user. Do not bury an architectural choice inside implementation.

## Confirmation

The author performs the traceability and cold-start gates. When another procedure requires independent
confirmation, the reviewer reads the specification first without relying on the source deliberation,
records every ambiguity or missing implementation fact, and only then checks the input ledger for
conservation. The author revises; the reviewer rechecks the changed document.

Confirmation requires all of the following:

- every input-ledger item has a valid disposition;
- no implementation-blocking decision remains;
- the live baseline, preservation rules, exact contract, validation, and completion conditions are
  sufficient for a fresh agent;
- any required independent reviewer expressly accepts the revised specification; and
- any contract another harness must execute has passed the execution check required by `kit-editing.md`.

Only then replace the draft marker with
`SPECIFICATION: confirmed — implementation-ready`. Record any independently required confirmation in the
specification because temporary inputs may later be removed.

## Handoff

Hand off the specification itself, its exact repository path, and the separately authorized action. Do
not send the recipient to the generating conversation for context. At implementation start, the agent
rechecks the stated baseline for drift and stops if drift changes a load-bearing assumption or the agreed
scope.
