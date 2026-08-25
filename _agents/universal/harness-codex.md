# Harness notes — Codex

## H1 — Startup and evidence

The Codex router loads this adapter at chat start, after the universal core and project instructions. Announce it once: `loaded: _agents/universal/harness-codex.md`. Resolve the current callable lineup from tool evidence; never rely on remembered model versions.

## H2 — Capability mapping

Map Sol → highest / Architect, Terra → middle / Senior implementer + Implementer, and Luna → lowest / Mechanic. Resolve the callable model for each tier from `spawn_agent` at chat start and announce the mapping once. The tool's accepted overrides are the callable truth.

## H3 — Spawn mechanics

Use only the in-session `spawn_agent`. Any tier assignment uses the resolved `model`, a supported `reasoning_effort`, and `fork_turns: "none"`. A full-history fork inherits the parent model and cannot override it. Do not use `codex exec` for delegation; it is outside the in-session mechanism.

## H4 — Publication under Codex approvals

Repository authorization and Codex execution approval are separate. If the push is already authorized,
do not ask the user again. Run it standalone with an exact destination and branch:

```text
git -c safe.directory=<absolute-repo> push <remote> <branch>
```

If escalation is required, use a destination-specific justification and the narrow reusable prefix
`["git", "-c", "safe.directory=<absolute-repo>", "push"]`, never a broad `git` or shell prefix. If the
reviewer rejects it, preserve the commit and report: **Codex execution blocked the push despite existing
repository authorization.** Do not call that missing user authorization or bypass the reviewer.

After success, verify the live ref rather than trusting a tracking ref:

```text
git -c safe.directory=<absolute-repo> ls-remote <remote> refs/heads/<branch>
```

Compare that OID with local `HEAD`, then follow the core rule for reading remote verification results.
