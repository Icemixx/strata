# Harness notes — Claude Code

## H1 — Startup and evidence

The Claude Code router loads this adapter at chat start, after the universal core and project instructions. Announce it once: `loaded: _agents/universal/harness-claude-code.md`. Resolve the current callable lineup from tool evidence; never rely on remembered model versions.

## H2 — Capability mapping

Map Opus → highest / Architect, Sonnet → middle / Senior implementer + Implementer, and Haiku → lowest / Mechanic. Resolve the callable model for each tier from the Agent tool at chat start and announce the mapping once. The tool's accepted model choices are the callable truth.

## H3 — Spawn mechanics

Use only Claude Code's in-session Agent tool. Any tier assignment uses the resolved `model`.
