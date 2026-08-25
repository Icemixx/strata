# Harness notes — Codex

## H1 — Startup and evidence

The Codex router loads this adapter at chat start, after the universal core and project instructions. Announce it once: `loaded: _agents/universal/harness-codex.md`. Resolve the current callable lineup from tool evidence; never rely on remembered model versions.

## H2 — Capability mapping

Map Sol → highest / Architect, Terra → middle / Senior implementer + Implementer, and Luna → lowest / Mechanic. Resolve the callable model for each tier from `spawn_agent` at chat start and announce the mapping once. The tool's accepted overrides are the callable truth.

## H3 — Spawn mechanics

Use only the in-session `spawn_agent`. Any tier assignment uses the resolved `model`, a supported `reasoning_effort`, and `fork_turns: "none"`. A full-history fork inherits the parent model and cannot override it. Do not use `codex exec` for delegation; it is outside the in-session mechanism.

## H4 — Publication under Codex approvals

Codex inherits repository publication authorization. When the user or repository instructions authorize
commit-and-push, that authorization is sufficient: execute the push without asking for, or implying a
need for, separate user authorization. Run it standalone with an exact destination and branch:

```text
git -c safe.directory=<absolute-repo> push <remote> <branch>
```

Use any matching inherited approval rule. If the execution environment still requires escalation,
submit it automatically as an execution step with a destination-specific justification and the narrow
reusable prefix `["git", "-c", "safe.directory=<absolute-repo>", "push"]`, never a broad `git` or shell
prefix. This escalation carries the existing repository authorization; it does not reopen the decision
or request new consent. If the execution environment rejects it, preserve the commit and report the
literal platform blocker. Never misreport that as missing user authorization or ask the user to
authorize the repository operation again.

After success, verify the live ref rather than trusting a tracking ref:

```text
git -c safe.directory=<absolute-repo> ls-remote <remote> refs/heads/<branch>
```

Compare that OID with local `HEAD`, then follow the core rule for reading remote verification results.
