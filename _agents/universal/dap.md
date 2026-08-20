# Decisions & Devil's Advocate Policy (DAP)

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/dap.md`. Load for any BIG decision (architecture, schema, security-sensitive paths, anything expensive to reverse) and whenever the user explicitly asks for a critical review ("apply DAP", "DAP this", "be a critic", "suggest a plan"). Part D in the core is the lightweight every-session floor; this file is the deep process. On 2026-07-26 it absorbed the former Feature Generation Meta-Protocol (FGMP) — the Level 1 write-up below is FGMP's surviving core; the full 7-step ceremony was retired as unenforced overhead.

## Level 1 — Structured decision write-up (any big decision; no user prompt needed)

Before committing to a big decision, produce in chat — and graduate durable results to the Rationale file as a dated "Why X, not Y" entry:

1. **Context re-check** — re-read the relevant project context, constraints, and prior Rationale/Build-Log entries; state how the change integrates and what it touches across layers.
2. **Alternatives** — at least two viable options with trade-offs, limitations, and assumptions; say why the winner wins and what is being given up.
3. **Learning from mistakes** — name any past inconsistency, inefficiency, or wrong assumption this improves on (check the Build Log), and how it is avoided now.
4. **Documentation** — record the decision where it belongs in the same change: Rationale entry, State/Build-Log updates, and proposed edits to any affected docs.
5. **Open questions** — surface what needs the user's judgment (missing context, strategic direction) instead of assuming.

## Level 2 — Council review (ONLY when the user explicitly asks)

DAP's council does **not** gate routine changes; normal work proceeds without a DAP stamp.

**When invoked,** spin up a **6-subagent council — 2 reviewers from each of the current harness's three tiers: highest, middle, and lowest** (per its `_agents/universal/harness-*.md` file). The supervising Architect does not count as a reviewer. Each reviewer is an independent, terminal critic; distribute the lenses below among them and use self-contained read-only prompts. Seat and batch the reviewers through the current harness's delegation mechanism and current concurrency allowance. The Architect synthesizes the independent findings; where they dissent, surface the debate and take the **most conservative** option. If subagents or a tier are unavailable, run the same lenses as a **rigorous self-review and say so explicitly** — never claim a council review that did not actually happen.

**Verdict stamp** (emit exactly one when DAP completes):

- `DAP: no dissent — [one-line reason]`
- `DAP: dissent on [topic] — chose [option] (most conservative)` — preceded by the full debate: counter-arguments, trade-offs, alternatives.
- `DAP: self-review only (council unavailable) — [verdict]`

**Review lenses** (plus any `DAP_EXTRA_LENSES` from the project file):

- Naming: descriptive, follows the project's naming conventions (private prefixes, constant casing)?
- Boundaries: does this import/call across a layer or module boundary the project forbids?
- DRY: is equivalent logic already defined elsewhere?
- Security: any hardcoded secrets, unvalidated input, or data access outside the sanctioned layer?
- Side-effects: does this affect other callers or startup behaviour?
- User-facing text: does it follow the project's localization/text conventions?
