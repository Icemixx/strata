# Codex interoperability

Load this dossier when Codex mechanics are needed or when examining, continuing, or preparing a handoff
for a Codex session. It is not a startup import.

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
their file edits are immediately visible. Treat each assignment as terminal and retrieve its final
report before relying on it.

If a mapped model is unavailable, inspect current callable capability evidence and disclose any
same-role substitution. Do not substitute across roles for a DAP seat.

## Native sessions and continuity

Codex native rollouts normally live under `<CODEX_HOME>/sessions/YYYY/MM/DD/rollout-*.jsonl`, with older
sessions possibly under `<CODEX_HOME>/archived_sessions/`; `<CODEX_HOME>` normally defaults to
`<user-home>/.codex`. Use `session_meta` to match normalized repository `cwd` and a user-originated main
thread. Exclude subagent and approval-review rollouts. A session index, when present, may help identify
top-level sessions, but content and timestamps still require validation.

Rollouts contain structured messages, tool calls, results, and compaction records. Recover only the
portion needed for continuity and verify all claimed artifacts in the live repository. Background or
delegated work is incomplete until its result is retrieved and verified.

## Permissions, artifacts, and publication

Runtime sandbox and approval rules control execution; they do not grant task authority. Return useful
artifacts through shared files or explicit worker reports. Repository authorization to commit or publish
still governs publication; a runtime escalation is an execution mechanism, not a second policy decision.
