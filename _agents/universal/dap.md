# Decisions & Devil's Advocate Policy (DAP)

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/dap.md`. Load for a BIG decision (Level 1) or when the core's explicit Level-2 trigger fires. Part D in the core is the lightweight every-session floor; this file owns the deeper decision process.

## Level 1 — Supervisor self-check (any big decision; no user prompt needed)

Level 1 uses no reviewer council and emits no DAP verdict stamp. Before committing to a big decision, the Supervisor produces in chat — and graduates durable results to the Rationale file as a dated "Why X, not Y" entry:

1. **Context re-check** — re-read the relevant project context, constraints, and prior Rationale/Build-Log entries; state how the change integrates and what it touches across layers.
2. **Alternatives** — at least two viable options with trade-offs, limitations, and assumptions; say why the winner wins and what is being given up.
3. **Learning from mistakes** — name any past inconsistency, inefficiency, or wrong assumption this improves on (check the Build Log), and how it is avoided now.
4. **Documentation** — record the decision where it belongs in the same change: Rationale entry, State/Build-Log updates, and proposed edits to any affected docs.
5. **Open questions** — surface what needs the user's judgment (missing context, strategic direction) instead of assuming.

## Level 2 — Council review (ONLY when the user explicitly asks)

DAP's council does **not** gate routine changes; normal work proceeds without a DAP stamp.

**When invoked,** spawn exactly **six independent, terminal, read-only reviewers in addition to the active Supervisor: two from the current harness's highest tier, two from its middle tier, and two from its lowest tier.** The active Supervisor never counts, regardless of its model tier. Required reviewers may therefore be below, equal to, or above the Supervisor. Level 2 completes only if all six return successfully.

Each reviewer is an independent, terminal, read-only critic with a self-contained prompt. Distribute the lenses below and batch seats only as required by current concurrency. The Supervisor synthesizes the findings; where they dissent, surface the debate and take the **most conservative** option.

No replacement, tier substitution, or partial council: if any of the six cannot start or complete, Level 2 is incomplete. Report the failed seat; do not spawn a substitute, issue a DAP verdict stamp, or claim council review. An ordinary Supervisor self-review may still help the work, but it is not DAP Level 2.

**Verdict stamp** (emit exactly one when DAP completes):

- `DAP: no dissent — [one-line reason]`
- `DAP: dissent on [topic] — chose [option] (most conservative)` — preceded by the full debate: counter-arguments, trade-offs, alternatives.

**Review lenses** (plus any `DAP_EXTRA_LENSES` from the project file):

- Naming: descriptive, follows the project's naming conventions (private prefixes, constant casing)?
- Boundaries: does this import/call across a layer or module boundary the project forbids?
- DRY: is equivalent logic already defined elsewhere?
- Security: any hardcoded secrets, unvalidated input, or data access outside the sanctioned layer?
- Side-effects: does this affect other callers or startup behaviour?
- User-facing text: does it follow the project's localization/text conventions?
