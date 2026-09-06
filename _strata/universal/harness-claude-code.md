# Claude Code interoperability

Load this dossier when Claude Code mechanics are needed or when examining, continuing, or preparing a
handoff for a Claude Code session.

## Roles and delegation

| Role | Cached model family |
| --- | --- |
| Architect | Opus |
| Engineer | Sonnet |
| Technician | Haiku |

**Model self-identification.** Two sources with different jobs. The environment context answers what you
are now; the transcript answers what you have been.

The environment context names the family and the exact model id, and it is re-stated to you on every turn.
It is the live value and the only one that describes the turn you are currently executing, so use it when
a workflow genuinely needs current-turn model identity.

The session transcript at `<user-home>/.claude/projects/<encoded-project-path>/<session-id>.jsonl` records
`message.model` on each assistant message, but records are written as a turn completes: the newest entry
is the previous turn, and the turn in flight is absent. It therefore cannot tell you what you are running
right now, and a role-constrained workflow that relies on it alone detects a switch only after work was
already performed. Use it for the switch history, not to determine the current turn.

It has one job nothing else can do. `message.model` is recorded per assistant message, so it is the only
place a model change *inside* a single prompt becomes visible, which capacity fallback can cause. The
environment context covers the boundary between prompts; this covers what happened inside one, after the
fact.

**Select the transcript by `CLAUDE_CODE_SESSION_ID`, never by recency.** That directory also holds child
and sidechain sessions running other models, so the newest file is frequently not yours. Ignore
`<synthetic>`, which marks generated records rather than a model. If the variable is unset, say so rather than picking a candidate.

Report the id verbatim rather than inferring a family from behaviour, and map it to a role by family
above. If neither source is available, say "cannot determine" rather than guessing.

Use Claude Code's native Agent mechanism and request the mapped model for each independent assignment.

Do not replace Opus with Fable or substitute across roles for a DAP seat unless the user explicitly
reopens the mapping above.

## Reasoning depth

Claude Code exposes a reasoning-effort ladder: `low`, `medium`, `high`, `xhigh`, `max`. It governs how
much thinking happens per step. It does not make the session read more files — coverage comes from tool
calls, depth from this setting, and neither substitutes for the other.

| Work | Level |
| --- | --- |
| Mechanical passes: inventory, running a check, recording coverage | `low` or `medium` |
| Anything that rules on evidence; the working default for an audit | `high` |
| The record checks in `audit.md`, and any truth check against code | `xhigh` |

Where one level must serve a whole audit, use `xhigh`. The failure modes are not symmetric: too much depth
costs time and money visibly, while too little returns a clean report and says nothing about what it could
not think through.

`max` buys depth per judgement, not reach. Prefer a second bounded pass over raising a single pass to it.

Two things are named "ultra" and they are unrelated. **Ultracode** is a setting on the effort control in
the VS Code extension, described by its own tooltip as *xhigh + workflows*: it carries the `xhigh` depth
above plus additional workflow behaviour, so wherever this table says `xhigh`, Ultracode satisfies it.
**`/code-review ultra`** is a separate multi-agent review that fans out across agents; it is user-
triggered and billed, and a session cannot start one for itself. Where a task is short of reach rather
than depth, that second one is the distinction that matters.

Recorded from the extension's own interface rather than from behaviour. What the workflow half changes is
not established here; a session that determines it should say so and correct this.

The setting belongs to the user and no session tool changes it. Report that the session is below the
recommended level and let the user raise it; do not proceed quietly and do not claim a depth you did not
run at.

## Native sessions and continuity

Claude Code main sessions normally live as top-level `*.jsonl` files beneath
`<user-home>/.claude/projects/<encoded-project-path>/`. Nested session subdirectories and `subagents/`
belong to delegated work, not the main conversation. Match normalized repository identity and reject
sidechains, metadata-only, empty, and bootstrap-only candidates.

Main-session records and compaction summaries may be needed to reconstruct continuity. Recover only the
portion needed for the task and verify all claimed artifacts in the live repository.

## Permissions, artifacts, and publication

Claude Code permission modes and background execution govern what the harness can run; they do not grant
task authority. Return useful artifacts through explicit results or stable repository paths. Commit and
publication remain governed by the user's request and Project Instructions, not by the ability of the
harness to execute Git commands.
