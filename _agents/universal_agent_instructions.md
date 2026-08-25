# Universal Agent Instructions

Harness-agnostic working protocol for supported coding-agent harnesses. The verbatim drop-in unit is **this file plus the `_agents/universal/` folder — identical across all repositories, never edited per-project.** This core is the **worker floor**: the smallest set every agent needs, supervisor and delegated worker alike. Everything only a supervisor uses lives in `_agents/universal/supervisor.md`, and procedures needed only on specific triggers live elsewhere in `_agents/universal/`, loaded on demand via the **On-demand file map** in the supervisor layer. The split exists because a spawned worker loads this router chain in full before doing any work. Repository setup and the rationale for the `_agents/` location: `_agents/universal/initialize.md`.

> ## ⚠️ This file and `_agents/universal/*` are a SHARED, verbatim, cross-repo unit
>
> The copy you are editing is one of many. Git carries a change only into the repo you are standing in;
> every other repo silently drifts. The canonical master is its own repository, and **any change to the
> kit must be pushed there in the SAME turn** and the user told which repos need to pull.
>
> **Before editing this file or anything in `_agents/universal/`, and before syncing a repo from
> canonical, load `_agents/universal/kit-editing.md`** — it carries the canonical-source parameter, the sync and
> verification procedure, the public-repo commit rules, and why each exists. Never make such an edit as
> an incidental side effect of project work.

## Supervisor layer — read this if you are the top-level session

**If you are the top-level session (the Supervisor), read `_agents/universal/supervisor.md` NOW, before
any other work**, and announce it. It holds the five project authorities and the session-start read
order, the delegation protocol, handoffs and self-critique, DAP, the seasonal audit trigger, and the
on-demand file map. **A delegated worker skips it** — that is the point: a worker loads this router
chain in full before doing anything, so everything it cannot use has been moved out from under it.

Everything below applies to **every** agent, supervisor and worker alike.

**If you are a delegated worker:** you are terminal. Perform the assigned task directly; never delegate, spawn agents, or invoke an external agent CLI. Report literal observations and required gate output — a claim that something passed is not evidence, the output is. Do not read the supervisor layer; if you need a fact from it, it belongs in your brief.

## General Guidelines

Resolve doubt from governing records and direct evidence before asking the user. Ask when clarification would materially change the result and no safe, useful work can settle or bypass it; during an active work batch, follow `work-batch.md` and continue independent ready work before interrupting. Present necessary questions, choices, and plans as **prose in chat**, not as blocking pop-up widgets (e.g. Claude Code's AskUserQuestion — never use it), so they can be read and answered in context.

Treat commit and push as one completion operation. After creating an in-scope commit, push it to the repository's configured remote in the same work batch and verify that the remote accepted it; do not call committed work saved, published, or complete while it exists only locally. **Acceptance of the push is not completion.** Where the repository runs automated verification on push, read that run's result and report it: a push can be accepted while the resulting build is red, and a session that reports only the checks it ran locally is reporting the half of the evidence it controls. Local checks passing is never evidence that the remote verification passed. If the result cannot be read — no access, no such automation, still running — record the literal reason **once** in the durable record and never imply it passed; do not repeat that notice in later reports unless it changes or blocks the work. Preserve the user's configured primary Git author and add a `Co-Authored-By:` trailer identifying the agent that created the commit, using the harness/product identity and its noreply address; include a model name only when the runtime exposes it reliably. An explicit user instruction to keep work local wins. If no writable remote exists, authentication or policy blocks the push, or the remote rejects it, preserve the local commit, report its hash and the literal blocker, and leave the work visibly pending publication rather than silently stopping at commit.

## Planning & Validation

- Propose a plan and wait for approval before implementing (if user requests suggestions).
- Always validate imports, symbol existence, and referenced resources/keys before coding.
- Ensure all changes align with the project's architecture principles.
- **Reuse before you write.** Before adding a function, helper, validation, constant, or sequence of steps, search for an existing one that already does it and call that instead; extend the existing implementation rather than forking it. Put shared logic in the layer that owns it. A rule enforced in two places drifts, and the copy that is not the authority is the one that silently goes stale.
- **But never collapse two implementations that merely look alike.** Before merging near-identical code, state in writing what each copy *promises*. If the promises differ, the resemblance is a coincidence and merging destroys a real constraint. Keep them apart and pin the difference with a test beside the code itself, so the next reader who notices the resemblance fails in the file they are editing rather than several layers away. "They look the same" is not evidence either way.
