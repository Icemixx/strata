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

Suggested levels are advisory. Work proceeds at the user's chosen effort; an audit reports the actual
depth when available, or marks it unverified.

| Work | Level |
| --- | --- |
| Mechanical passes: inventory, running a check, recording coverage | `low` or `medium` |
| Anything that rules on evidence; the working default for an audit | `high` |
| The record checks in `audit.md`, and any truth check against code | `xhigh` |

For a whole audit, `xhigh` may be useful. Depth does not supply coverage or determine whether work may
proceed.

`max` buys depth per judgement, not reach. Prefer a second bounded pass over raising a single pass to it.

Two things are named "ultra" and they are unrelated. **Ultracode** is a setting on the effort control in
the VS Code extension, described by its own tooltip as *xhigh + workflows*: it carries the `xhigh` depth
above plus additional workflow behaviour, so wherever this table says `xhigh`, Ultracode satisfies it.
**`/code-review ultra`** is a separate multi-agent review that fans out across agents; it is user-
triggered and billed, and a session cannot start one for itself. Where a task is short of reach rather
than depth, that second one is the distinction that matters.

Recorded from the extension's own interface rather than from behaviour. What the workflow half changes is
not established here; a session that determines it should say so and correct this.

The setting belongs to the user and no session tool changes it. Report actual depth when it is available;
otherwise mark it unverified.

## Native sessions and continuity

Claude Code main sessions normally live as top-level `*.jsonl` files beneath
`<user-home>/.claude/projects/<encoded-project-path>/`. Nested session subdirectories and `subagents/`
belong to delegated work, not the main conversation. Match normalized repository identity and reject
sidechains, metadata-only, empty, and bootstrap-only candidates.

Main-session records and compaction summaries may be needed to reconstruct continuity. Recover only the
portion needed for the task and verify all claimed artifacts in the live repository.

## Permissions, artifacts, and publication

Claude Code permission modes and background execution govern what the harness can run; they do not grant
task authority.

**Permission rules are a recognized-command filter, not isolation.** They match invocations against
patterns; they are not a filesystem boundary. A path a rule denies through one command form remains
reachable through a form the filter does not recognize, so permission rules cannot be relied on to make a
directory unreadable. Where a procedure needs one participant not to read another's files - a blind phase,
for instance - that separation is instruction-governed and has to be stated as a rule the agent keeps, not
delegated to a permission entry that will not hold it.

**Selective routine execution.** In auto mode a separate classifier model reviews each action no
permission rule settles. File reads and searches, file edits inside the working directories outside
protected paths, and a built-in set of read-only shell commands skip it; where the server reviews actions
as part of the session's own model requests, read-only shell commands are reviewed too. An action that
matches a `permissions.allow` rule runs without classifier review, apart from the exceptions the
permission-modes documentation lists, such as writes to protected paths. Each review carries part of the
transcript plus the pending action and adds a round-trip before execution; the documentation counts those
calls as token usage on Enterprise and API-billed accounts, and no separate calls exist where the server
reviews actions within the session's requests. An allowed routine command skips the review entirely.

Allow only reviewed, fixed-purpose read/inspection, screenshot, local-build, host-test and checker entry
points, one rule per entry point in the shell tool's own form, `Bash(...)` or `PowerShell(...)`.
Everything before the first `*` limits the rule, so place it after the subcommand: `Bash(git log *)`
allows only `git log`. An allow rule must match every subcommand of a compound command; a deny or ask rule
applies when any subcommand matches. On entering auto mode, Claude Code drops rules broad enough to run
arbitrary code - blanket `Bash(*)` or `PowerShell(*)`, wildcarded interpreters such as `Bash(python*)`,
package-manager run commands - and restores them on leaving it. A routine step written as an inline
script or interpreter call therefore cannot be pre-approved by a narrow rule: give it a fixed script and
allow that script's invocation. A host-test rule must not also match device-integration runs, and an
inspection rule must not match input actions, installs, resets or data writes.

Keep mutations reviewed by giving them no rule: delete, persistent-data overwrite, upload and push
commands then reach the classifier like any unmatched command. An `ask` rule is different. In auto mode
it always forces a human prompt, which stops an unattended run until someone answers, so reserve it for
actions a person must confirm every time. `autoMode` entries (`environment`, `allow`, `soft_deny`,
`hard_deny`) are natural-language guidance for the classifier, not rule matches, and the classifier reads
them only from user settings (`~/.claude/settings.json`), managed settings or the `--settings` flag,
never from `.claude/settings.json` or `.claude/settings.local.json`. `autoMode.classifyAllShell: true`
suspends every shell allow rule while auto mode is active. `claude auto-mode config` prints the effective
classifier configuration. Neither this dossier nor an agent's request installs a policy; permission
settings remain the user's configuration work.

Sources: [Permissions](https://code.claude.com/docs/en/permissions),
[Permission modes](https://code.claude.com/docs/en/permission-modes),
[Auto mode configuration](https://code.claude.com/docs/en/auto-mode-config).

**A foreground command is moved to the background at 600 seconds.** It keeps running there and completes
normally; a 590.527 s call returned in the foreground. So a single call can span any wait up to ten
minutes, and a longer one is not one call. Treat 600 s as the ceiling of a bounded wait, not as a limit on
waiting: the wait continues by re-issuing the call.

Return useful artifacts through explicit results or stable repository paths. Commit and
publication remain governed by the user's request and Project Instructions, not by the ability of the
harness to execute Git commands.
