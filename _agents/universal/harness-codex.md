# Harness notes — Codex

## H1 — Startup and evidence

The Codex router loads this adapter at chat start, after the universal core and project instructions. Announce it once: `loaded: _agents/universal/harness-codex.md`. Resolve the current callable lineup from tool evidence; never rely on remembered model versions.

## H2 — Capability mapping

Map Sol → highest / Architect, Terra → middle / Senior implementer + Implementer, and Luna → lowest / Mechanic. Resolve the callable model for each tier from `spawn_agent` at chat start and announce the mapping once. The tool's accepted overrides are the callable truth.

## H3 — Spawn mechanics

Use only the in-session `spawn_agent`. Any tier assignment uses the resolved `model`, a supported `reasoning_effort`, and `fork_turns: "none"`. A full-history fork inherits the parent model and cannot override it. Do not use `codex exec` for delegation; it is outside the in-session mechanism.
