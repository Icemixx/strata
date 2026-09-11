# Session pickup

Use this procedure only when the user asks to examine or continue work from a named harness session.
Load that harness's dossier for native transcript and session mechanics; load both dossiers for
cross-harness continuity.

1. Match candidate main sessions to the repository, accounting for a known repository rename when the
   request supplies both paths.
2. Exclude subagent, approval-review, empty, and bootstrap-only sessions. Never select a transcript only
   because its file is newest.
3. Read only enough to recover the last authorized request, completed work, changed artifacts, literal
   evidence, and exact unfinished step or blocker.
4. Verify transcript claims against the current filesystem, Git state, and routed project authorities.
   Live evidence determines what actually landed.
5. Report only what the task needs.

Before acting, announce the source harness, selected main-session identifier and timestamp, repository
match, last completed work, and exact unfinished step or blocker.

`Examine` is read-only. `Continue` resumes only scope already authorized in the recovered conversation;
recovery creates no new implementation, commit, publication, or external-action authority.

If no valid transcript exists, name the native stores checked and fall back to routed project
authorities. Never silently substitute a repository conversation archive for a native harness session.
