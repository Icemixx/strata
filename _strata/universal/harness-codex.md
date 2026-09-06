# Codex interoperability

Load this dossier when Codex mechanics are needed or when examining, continuing, or preparing a handoff
for a Codex session.

## Roles and delegation

| Role | Cached model family | Recognized runtime model id |
| --- | --- | --- |
| Architect | Sol | `gpt-5.6-sol` |
| Engineer | Terra | `gpt-5.6-terra` |
| Technician | Luna | `gpt-5.6-luna` |

**Model self-identification.** A Codex session's reliable self-identification source is the runtime's
`turn_context` record for the current turn. In a native rollout, this is persisted as JSONL at
`<CODEX_HOME>/sessions/YYYY/MM/DD/rollout-*.jsonl`: when `CODEX_SESSION_ID` is available, select the file
whose `session_meta.payload.id` or `session_meta.payload.session_id` exactly matches it, then read the
latest `turn_context.payload.model`. That field returns the exact runtime model id, not a separate family.
It wins over session-start metadata, model catalogs or caches, requested thread settings, delegation-tool
model lists, and inference from behavior; none of those identifies the model executing the current turn.

Map the returned id to a role only by exact match with the recognized runtime-model-id column above. The
shared `sol`, `terra`, and `luna` spelling in those ids is a current naming convention, not a guaranteed
id-to-family contract: do not parse an unlisted id's suffix or display name. If the current rollout cannot
be selected unambiguously, has no current-turn `turn_context.payload.model`, or returns an unlisted id,
state the exact available fact and what cannot be determined; if no source is available, disclose
"cannot determine" rather than guessing or stopping.

Use Codex's in-session delegation tools. A full-history fork inherits the parent model; select a model
only with an isolated or bounded-history assignment. Delegated agents work in the shared workspace, so
their file edits are immediately visible.

## Reasoning depth

Codex exposes `/reasoning` as the current-chat control. The persistent configuration key is
`model_reasoning_effort`; the CLI has no dedicated reasoning flag, but its generic override accepts
`-c model_reasoning_effort='"xhigh"'`. These are user-side controls. A running main agent has no tool that
changes its own effort; selecting `reasoning_effort` when spawning an agent changes the child, not the
parent.

The legal values are model-dependent. In the live catalog verified with `codex-cli 0.153.0`, the
recognized models above expose:

| Model | Values |
| --- | --- |
| `gpt-5.6-sol` | `low`, `medium`, `high`, `xhigh`, `max`, `ultra` |
| `gpt-5.6-terra` | `low`, `medium`, `high`, `xhigh`, `max`, `ultra` |
| `gpt-5.6-luna` | `low`, `medium`, `high`, `xhigh`, `max` |

Do not treat that table as a permanent global ladder. The configuration schema also accepts `minimal`,
but the verified catalog does not offer it for these three models; compatibility belongs to the selected
model's live catalog. Re-verify after a Codex or model-catalog change rather than carrying these values
forward on memory.

When the native rollout is available, read the current value from the latest current-turn
`turn_context.payload.effort`, selecting the rollout by `CODEX_SESSION_ID` as described above. It is a
per-turn fact. Do not infer it from the user config, a model default, or a previous turn. If the field or
unambiguous rollout is unavailable, report the depth as unverified. The user may change the chat's depth
with `/reasoning`; the agent cannot invoke that composer command for them.

| Work | Level |
| --- | --- |
| Deterministic inventory or running an already-defined check | `low` |
| Coordinating inventory and recording complete coverage | `medium` |
| Judgement over evidence | `high` |
| The record checks in `audit.md`, truth checks against code, or one level for a whole audit | `xhigh` |

Use `max` only for an unusually hard bounded judgement where the extra latency is warranted. It deepens
one agent's work; it does not add coverage.

Codex's reach mechanism is a **subagent workflow**: the in-session delegation controls can fan independent
assignments out across several agent threads and collect their results. A Codex session can start that
fan-out itself when the user or an applicable `AGENTS.md` or skill instruction requests delegation; tool
availability alone is not authority to do so. `ultra`, where the selected model exposes it, combines
maximum reasoning with automatic task delegation, so it is not a pure depth increment and must not be
reported as one. Governing instructions and the runtime's concurrency limit still apply.

## Native sessions and continuity

Codex native rollouts normally live under `<CODEX_HOME>/sessions/YYYY/MM/DD/rollout-*.jsonl`, with older
sessions possibly under `<CODEX_HOME>/archived_sessions/`; `<CODEX_HOME>` normally defaults to
`<user-home>/.codex`. Use `session_meta` to match normalized repository `cwd` and a user-originated main
thread. Exclude subagent and approval-review rollouts. A session index, when present, may help identify
top-level sessions, but content and timestamps still require validation.

Rollouts contain structured messages, tool calls, results, and compaction records. Recover only the
portion needed for continuity and verify all claimed artifacts in the live repository.

## Permissions, artifacts, and publication

Runtime sandbox and approval rules control execution; they do not grant task authority. Return useful
artifacts through shared files or explicit worker reports. Repository authorization to commit or publish
still governs publication; a runtime escalation is an execution mechanism, not a second policy decision.
