# Claude Code interoperability

Load this dossier when Claude Code mechanics are needed or when examining, continuing, or preparing a
handoff for a Claude Code session. It is not a startup import.

## Roles and delegation

| Role | Cached model family |
| --- | --- |
| Architect | Opus |
| Engineer | Sonnet |
| Technician | Haiku |

**Model self-identification.** A Claude Code session is told its own model in its environment context,
which names both the family and the exact model id. That statement is authoritative for the session and
needs no file inspection. Report the id verbatim rather than inferring a family from behaviour, and map it
to a role by family above. When a procedure asks for your model, this is the source; if the environment
does not state it, say "cannot determine" rather than guessing.

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
