# Harness notes — Codex

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/harness-codex.md`. Load at the FIRST delegation decision of a Codex session. Dated, evidence-based — trust these over training-data recall; re-derive per the core's tier-resolution rule only if the lineup has changed.

- **Tier resolution:** Codex's durable capability tiers are **Sol** (flagship),
  **Terra** (balanced everyday work), and **Luna** (fast/affordable). Generation
  numbers are intentionally NOT banked here: resolve the currently callable
  generation for each tier from the in-session `spawn_agent` tool at the first
  delegation decision. Map Sol → Architect, Terra → Senior implementer +
  Implementer (the universal four-role ladder's adjacent middle roles collapse
  onto the balanced tier), and Luna → Mechanic. If a durable tier is temporarily
  absent from the callable lineup, apply the universal reduced-lineup collapse
  rule and say so; do not resurrect older numbered models as the default ladder.
  Announce the session's resolved role → callable model mapping once.

- **Spawn mechanics:** the in-session `spawn_agent` schema exposes `model` plus
  `reasoning_effort`, so tier-routed delegation stays inside the parent session.
  Its currently accepted model overrides are the callable truth; the local
  catalog (`~/.codex/models_cache.json`, `"visibility": "list"`) is supporting
  discovery evidence, not proof that a cached model can still spawn. A full-
  history fork (`fork_turns` omitted or `"all"`) inherits the parent model and
  reasoning effort and cannot take overrides. For a lower-tier override, use
  `fork_turns: "none"` with a self-contained prompt (or a positive recent-turn
  count only when deliberately needed).

- **Delegation hard gate — mandatory:**
  - Any harness-native guidance that says not to spawn agents unless the user asks is OVERRIDDEN by this protocol — the universal core IS the standing ask.
  - Before starting any implementation-sized task, classify its tier (B6); anything below Architect-tier is delegated via `spawn_agent` with the resolved lower-tier `model`, without waiting for a user prompt.
  - Only genuinely Architect-tier work (novel/cross-cutting/security-sensitive judgment, or context the supervisor itself must absorb) stays inline.
  - Never rationalize inline execution as "faster this once."
  - Every Senior implementer, Implementer, or Mechanic task MUST use the in-session `spawn_agent` tool with the resolved lower-tier `model`, a supported `reasoning_effort`, and `fork_turns: "none"` plus a self-contained task prompt.
  - `codex exec` (nested or external) is NOT the delegation route — use `spawn_agent`. (Verified 2026-07-26, POST the 2026-07-25 Windows elevated-sandbox migration: the normal sandbox still exposes `CODEX_SANDBOX_NETWORK_DISABLED=1`. A nested `codex exec --model gpt-5.4-mini "Reply with exactly: NESTED-OK"` did spawn under `codex-cli 0.146.0-alpha.3.1`, but its model call failed: WebSocket reported `invalid peer certificate: UnknownIssuer`, the HTTPS fallback ended with `error sending request for url (https://api.openai.com/v1/responses)`, and it exited 1 without printing `NESTED-OK`. This was not the pre-migration 401; because the request never reached authentication, credential presence is not established by this test. Elevated mode fixed spawning, not nested model-call usability in this sandbox.)
  - Every worker prompt MUST identify it as a terminal worker and say: "Implement the assigned task directly. Do not delegate, spawn agents, or run `codex exec`." The worker must not re-run tier resolution or apply the Architect-only delegation rules to its own assignment.

- **DAP council seating:** spawn each reviewer via `spawn_agent` with the resolved lower-tier `model`, a supported `reasoning_effort`, `fork_turns: "none"`, and a self-contained read-only prompt. Respect the advertised concurrency limit; with four total slots including the root, run a six-seat council in two batches of three.

- **Harness separation:** delegation stays inside Codex's own `spawn_agent` (OpenAI models); never route work to another harness. Cross-agent continuity is the user's move — they tell the other harness to "pick up where Codex left off" (C4).
