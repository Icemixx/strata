# Claude Code interoperability

Load this dossier when Claude Code mechanics are needed or when examining, continuing, or preparing a
handoff for a Claude Code session. It is not a startup import.

## Roles and delegation

| Role | Cached model family |
| --- | --- |
| Architect | Opus |
| Engineer | Sonnet |
| Technician | Haiku |

**Model self-identification.** Two sources, and prefer the second when a procedure needs the model for the
current turn rather than for the session.

The environment context names the family and the exact model id. It is immediate and needs no file
inspection, but it is a statement in your own prompt: nobody else can check it, and it does not show
whether the model changed earlier in the session.

The session transcript records the model on every assistant message, at
`<user-home>/.claude/projects/<encoded-project-path>/<session-id>.jsonl`. The latest real `message.model`
is the model executing now; the sequence of distinct values across the file is the switch history. Ignore
`<synthetic>`, which marks generated records rather than a model. This source is independently checkable
and is the only one that detects a mid-session switch, so use it when a procedure re-determines tier per
turn.

Report the id verbatim rather than inferring a family from behaviour, and map it to a role by family
above. If neither source is available, say "cannot determine" rather than guessing.

Use Claude Code's native Agent mechanism and request the mapped model for each independent assignment.
Give delegated agents a self-contained brief because their usable context is determined by that
assignment and harness behavior, not by the Active Agent's assumptions. Treat each assignment as
terminal and retrieve its final report before relying on it.

If a mapped model is unavailable, inspect current callable capability evidence and disclose any
same-role substitution. Do not replace Opus with Fable or substitute across roles for a DAP seat unless
the user explicitly reopens the accepted mapping.

## Native sessions and continuity

Claude Code main sessions normally live as top-level `*.jsonl` files beneath
`<user-home>/.claude/projects/<encoded-project-path>/`. Nested session subdirectories and `subagents/`
belong to delegated work, not the main conversation. Match normalized repository identity and reject
sidechains, metadata-only, empty, and bootstrap-only candidates.

Main-session records and compaction summaries may be needed to reconstruct continuity. Recover only the
portion needed for the task and verify all claimed artifacts in the live repository. Background agents
or artifact files are incomplete evidence until their result is retrieved and checked.

## Permissions, artifacts, and publication

Claude Code permission modes and background execution govern what the harness can run; they do not grant
task authority. Return useful artifacts through explicit results or stable repository paths. Commit and
publication remain governed by the user's request and Project Instructions, not by the ability of the
harness to execute Git commands.
