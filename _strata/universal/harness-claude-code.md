# Claude Code interoperability

Load this dossier when Claude Code mechanics are needed or when examining, continuing, or preparing a
handoff for a Claude Code session. It is not a startup import.

## Roles and delegation

| Role | Cached model family |
| --- | --- |
| Architect | Opus |
| Engineer | Sonnet |
| Technician | Haiku |

**Model self-identification.** Two sources with different jobs. The environment context answers what you
are now; the transcript answers what you have been.

The environment context names the family and the exact model id, and it is re-stated to you on every turn.
It is the live value and the only one that describes the turn you are currently executing, so it is what a
procedure re-determining tier per prompt must read.

The session transcript at `<user-home>/.claude/projects/<encoded-project-path>/<session-id>.jsonl` records
`message.model` on each assistant message, but records are written as a turn completes: the newest entry
is the previous turn, and the turn in flight is absent. It therefore cannot tell you what you are running
right now, and a procedure that relies on it alone detects a switch only after a round was already written
under the wrong tier. Use it for the switch history and because a third party can check it, not to
determine the current turn.

It has one job nothing else can do. `message.model` is recorded per assistant message, so it is the only
place a model change *inside* a single prompt becomes visible: capacity fallback can serve part of one
response from a lower tier, and no live check sits between an agent's own tool calls. An Opus session
running a debate evidence pass was served its final write by Sonnet as it hit a session limit, and the
transcript is where that shows. The environment context covers the boundary between prompts; this covers
what happened inside one, after the fact.

**Select the transcript by `CLAUDE_CODE_SESSION_ID`, never by recency.** That directory also holds child
and sidechain sessions running other models, so the newest file is frequently not yours: an agent that
guessed by modification time read a 10-record sidechain, reported a third model that was neither its
previous nor its current one, and would have certified the wrong tier. Ignore `<synthetic>`, which marks
generated records rather than a model. If the variable is unset, say so rather than picking a candidate.

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
