# Editing the kit — the shared, cross-repo unit

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/kit-editing.md`. **Load BEFORE any edit to `_agents/universal_agent_instructions.md` or anything in `_agents/universal/`, and before syncing a project repo from canonical.** The core carries a short pointer at the top; this file carries the procedure and the reasoning.

## ⚠️ STOP — editing THIS file or `_agents/universal/*` changes EVERY repository

**This file and everything in `_agents/universal/` are a shared, verbatim, cross-repo unit. The copy you
are editing is one of many. Git will only ever carry the change into the repo you are standing in —
every other repo keeps the old text and silently drifts.**

### The canonical home is its own repository

**`https://github.com/Icemixx/universal_agent_kit`** holds the master copy (added 2026-07-29). Its
layout mirrors a consuming repo: `_agents/universal_agent_instructions.md` + `_agents/universal/*`.
Every project repository holds a COPY. That canonical repository is the source of truth.

**That repository is PUBLIC and its history is permanent.** Commit to it with a GitHub `users.noreply`
author address, never a personal one, and keep the message about the RULE and the SHAPE of the failure
— never the private repository it was found in, its ticket ids, its internal tool names, or the user's
words. The incident that motivates a kit rule is by construction a private-repo incident; say what the
rule prevents, not where it was learned.

### Hard boundary — the universal payload is project-agnostic

The defining property of this kit is that its copied payload applies unchanged to every repository.
Universal files therefore specify only **capabilities, invariants, interfaces, audience boundaries,
required outcomes, and verification semantics**. They must never prescribe or assume a consuming
project's programming language, framework, runtime, package manager, test runner, database engine,
localization scheme, business domain, source-tree layout, ticket namespace, or native checker
implementation. Put every such realization in project-owned instructions, manifests, checkers, tests,
and Guide material.

Write universal examples as placeholders (`<project-native command>`, `<test suite>`, `<route>`) or as
tool-neutral pseudocode. The only narrow exceptions are:

- Git operations required by the kit's repository publication/sync/provenance contract;
- a harness adapter naming the mechanics of that harness, confined to its own `harness-*.md` file; and
- literal paths and filenames that are themselves part of the universal kit contract.

Before every canonical commit, inspect the complete changed universal payload—not only the new lines—
for consuming-project names and stack/tool assumptions. Any hit outside those exceptions blocks the
commit. Rephrase the rule as a general contract and move the concrete implementation to the consuming
repository; never make a growing allowlist of favored stacks.

**On ANY change to the kit, in ANY repo, that repository MUST be updated in the SAME turn.** Do not
leave it for later and do not leave it to the user to mirror by hand: an edit that lands only in the
project repo you happen to be standing in is exactly the silent drift this banner exists to prevent.
The agent PUSHES the change to the canonical repo, then TELLS the user which repos now need to pull.

### Syncing a project repo FROM the canonical repo

Trigger: "sync the universal kit", "update the agent files", or equivalent. Project repos hold
**copies**, not submodules or remotes — there is no `git pull` relationship with the canonical repo, so
"pull" here means copy-and-commit:

1. `git clone --depth 1 https://github.com/Icemixx/universal_agent_kit` into a scratch/temp directory
   — never inside the project repo.
2. Copy its `_agents/universal_agent_instructions.md` and the ENTIRE `_agents/universal/` folder over
   the project's copies. **Never touch `_agents/project_*.md`** — those are project-owned and are not
   part of the kit.
3. Hash-compare the copies to confirm (normalise `\r\n` → `\n` first), then commit in the project repo,
   naming the canonical commit you synced from. Report which files actually changed.
4. **Write the canonical commit SHA into `_agents/.kit-version`** (that one line, nothing else). It is
   **project-owned and deliberately NOT inside `_agents/universal/`**: the folder is copied wholesale,
   so a marker living inside it would be overwritten by the canonical copy on every sync, and the
   canonical repo cannot carry its own SHA anyway — the value does not exist until after the commit
   that would contain it. Without this step the freshness check below silently compares against
   nothing.

### Detecting a stale copy — session start

Copies do not update themselves, and kit changes arrive in bursts, which is exactly when nobody thinks
to look. So at session start, read `_agents/.kit-version` and run
`git ls-remote <canonicalHEAD`; if they differ, **say so and carry on** — report only, never sync as
a side effect. The whole round trip is one command returning one line.

**If the check cannot run — no network, no remote, missing or unreadable marker — say THAT, explicitly.**
A freshness check that degrades quietly into "looks fine" is worse than none, because its silence is
read as confirmation. Report the literal reason it could not run.

Line endings are handled by the canonical repo's `.gitattributes` (`* text=auto eol=lf`), so the kit
normalises identically on every machine and in every repo. Compare CONTENT, not bytes: a project repo
may legitimately check the copies out with different endings, which is why step 3 normalises first.

Therefore, whenever you modify this file or ANY file in `_agents/universal/`, you **MUST**:

1. **Push the identical change to `universal_agent_kit` in the same turn**, then **tell the user
   explicitly, in your final message of that turn**, that the shared kit changed and which repositories
   now need to pull. Not only in a commit message, and never buried in a list of project changes.
2. **Name the exact files changed and quote the before/after of each edit**, so the change can be
   reviewed without re-deriving anything or diffing by hand.
3. **Never make such an edit as an incidental side effect** of project work. If a project task seems to
   require changing the shared kit, say so and get the user's go-ahead first — a project-specific need
   almost always belongs in `project_instructions.md` instead (which wins on conflict anyway).
4. **Verify sync rather than assuming it.** Checking is seconds:
   `git clone --depth 1 https://github.com/Icemixx/universal_agent_kit` into a scratch dir and
   hash-compare each file against the local copy. Normalise line endings (`\r\n` → `\n`) before
   hashing, or a CRLF checkout difference reads as a false mismatch. Note `gh` may not be installed;
   plain `git` is enough.
5. **Verify the project-agnostic boundary.** Inspect the full changed payload for project names,
   domain vocabulary, and stack-native commands or assumptions. Remove or generalize every hit not
   covered by the three narrow exceptions above before committing.

Rationale, and why this warning exists at the top where it is re-read every session: on 2026-07-28 a
session corrected a genuine self-contradiction in this file (two file descriptions still said
"append-only" after that rule had been repealed) and reported it as one bullet inside a large
project-cleanup summary. The fix was right; the silence was not. The user only found out by asking. A
shared file changed in one repo and nowhere else is worse than the contradiction it fixed, because
nothing will ever surface the divergence.
