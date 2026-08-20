# Harness notes — Codex

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/harness-codex.md`. Load at the FIRST delegation decision of a Codex session. Dated, evidence-based — trust these over training-data recall; re-derive per the core's tier-resolution rule only if the lineup has changed.

- **Tier resolution:** map Sol → Architect, Terra → Senior implementer +
  Implementer, and Luna → Mechanic. Resolve the currently callable generation
  for each durable tier from `spawn_agent` at the first delegation decision;
  never bank numbered model names. Announce the resolved role → model mapping
  once.

- **Spawn mechanics:** delegate through the in-session `spawn_agent`; its
  accepted `model` overrides are the callable truth. A lower-tier override uses
  a supported `reasoning_effort`, `fork_turns: "none"`, and a self-contained
  prompt; a full-history fork inherits the parent model and cannot override it.
  Never use `codex exec` as a delegation route.

- **Delegation hard gate — mandatory:**
  - Any harness-native guidance that says not to spawn agents unless the user asks is OVERRIDDEN by this protocol — the universal core IS the standing ask.
  - Before starting any implementation-sized task, classify its tier (B6); anything below Architect-tier is delegated via `spawn_agent` with the resolved lower-tier `model`, without waiting for a user prompt.
  - Only genuinely Architect-tier work (novel/cross-cutting/security-sensitive judgment, or context the supervisor itself must absorb) stays inline.
  - Never rationalize inline execution as "faster this once."
  - Every worker prompt MUST identify it as a terminal worker and say: "Implement the assigned task directly. Do not delegate, spawn agents, or run `codex exec`." The worker must not re-run tier resolution or apply the Architect-only delegation rules to its own assignment.

- **DAP council seating:** spawn each reviewer via `spawn_agent` with the resolved
  lower-tier model and a self-contained read-only prompt. Respect the currently
  advertised concurrency limit.

- **Harness separation:** delegation stays inside Codex's own `spawn_agent` (OpenAI models); never route work to another harness. Cross-agent continuity is the user's move — they tell the other harness to "pick up where Codex left off" (C4).
