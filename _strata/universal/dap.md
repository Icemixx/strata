# Decisions and Devil's Advocate Policy

Use Level 1 for consequential decisions. Use Level 2 only for high-impact, hard-to-reverse, or genuinely
disputed decisions. The user, Project Instructions, or the Active Agent may trigger Level 2; state the
trigger before starting.

## Level 1

Re-read relevant context and prior reasoning. Compare viable alternatives and trade-offs. Separate
evidence from assumptions, revisit relevant prior mistakes, identify risks and reversibility, map the
affected scope, and surface open questions. Apply coding-specific lenses only to code-affecting
decisions. Record the settled result in Rationale; update State or Build Log only if their information
also changed.

## Level 2 council

Create exactly six independent, terminal, read-only reviewers in addition to the Active Agent:

- two Architects: Opus or Sol;
- two Engineers: Sonnet or Terra; and
- two Technicians: Haiku or Luna.

The Active Agent never occupies a seat. Failure of any seat invalidates the council. A mapped model may
be replaced only by a currently available model in the same role, with the substitution disclosed; if
no same-role model exists, the council is invalid. Claude's accepted mapping remains
Opus/Sonnet/Haiku unless the user explicitly reopens it.

Give every seat the same decision, evidence, constraints, and candidate options, while assigning useful
independent review lenses. Reviewers do not edit or coordinate with one another. The Active Agent
synthesizes their votes and reasoning.

A clear vote winner is selected. Without a clear winner, select the best-supported option from the
evidence and reasoning. Preserve material dissent; do not default to the most conservative option.

Emit exactly one verdict:

- `DAP: no dissent — chose [option] — [reason]`
- `DAP: dissent on [topic] — chose [option] — vote [count] — [reason]; dissent: [summary]`

Rationale stores the decision, vote breakdown, strongest support, material dissent, and verdict. Do not
store six full reviewer transcripts unless they are independently needed evidence.
