# Doc consolidation — current claims corrected, superseded claims folded in

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/consolidation.md`. Load when recording a decision that supersedes earlier recorded entries, or when the user asks for a doc cleanup. This procedure replaces the previous append-only rule for the Rationale and Build Log files.

## The rule

Keep the five authorities truthful without rewriting accurate history. Update current Guide claims, current State claims, and Instructions in place. For a later settled decision or verified fact that makes an earlier live Rationale or Build Log claim wrong, write one dated consolidated entry with the current fact plus the compressed chain of reasoning, delete only the superseded live claims, and name what it replaced.

## Scope and judgment

- Guide: update current software architecture, behavior, operator/developer technical workflows, technical conventions, and intrinsic limitations in place.
- State: update Current Reality, active work, gates, priorities, and unresolved items in place; closed ticket history is not erased.
- Instructions: update mandatory conduct, protocol parameters, enforcement rules, and Guide pointers in their current audience file; worker rules belong in `project_instructions.md`, top-level-only rules in `project_instructions_supervisor.md`, and neither is duplicated.
- Rationale and Build Log: append new decisions/events by default; consolidate only superseded live claims, carrying forward durable lessons.
- Preserve accurate dated historical evidence, including incident lessons and observed verification, even when the architecture later evolves. When only a clause is stale, change that clause rather than deleting accurate context.

## Bounding a file that is read every session

Two files are paid for on every session rather than when consulted: **State**, which the supervisor layer requires to be read through EOF, and the **worker-facing project instructions**, which the routers load into every session. Both start small and both grow monotonically, so both eventually charge every future session for material almost none of them needs. The procedures below are the sanctioned way to bound them. A repository initialized under the current `initialize.md` already has the archives and supervisor surface; continuous closure then prevents regrowth.

### State: the closed-item archive

State is correct to be read whole while it describes current work, and becomes a standing tax once it is mostly finished tickets. Split it when the finished-work majority is large enough to notice, not on a fixed threshold.

**The split, and the order matters:**

1. **Measure first and record the numbers** — bytes before, bytes after, and the share of the file that is closed work. Without them nobody can tell later whether the split was worth it.
2. **State keeps one machine-parseable compact line per closed item**: identifier, title, tier, dependency, `DONE`, date, one allowed provenance form, and a dated evidence pointer. Use the strict status, provenance, and closure transaction in `_agents/universal/work-batch.md`; never invent a commit for self-referential or unattributable records.
3. **The archive receives only the moved detail** and opens with a header stating that it is a subordinate appendix of State, is not current truth, and loses to State on any conflict.
4. **Amend the read rule in the project's own instructions too**, not just the core. If any instruction still says to read State's history at startup, the split saves nothing — an agent will simply read both files. **This step is the entire win; the file move alone achieves nothing.**
5. **Re-point every mechanical check.** Checks that scan State for item identifiers, or cross-reference closed items against the Build Log, must still pass. Verify by running them, not by reading them.
6. **Move mechanically; do not prune while moving.** Deciding per item what is still worth keeping is a separate judgment pass with its own risk. A straight move is reversible and its benefit is immediate.

After the retrofit, every newly closed ticket moves in the closure transaction itself. Periodic or threshold-only compaction is a regression: it permits State to grow back between cleanup passes. `DONE` with an outstanding owned gate must be reclassified before any move.

**Applies to State only.** The other authorities already have bounded read rules — the Build Log is read tail-first, Rationale through its settled register, the Guide by task-relevant section — so splitting them saves nothing at startup and costs a file. Note that a Rationale file with a settled-decision register at its head is already this pattern; State is adopting a structure the model has always had elsewhere.

### The Instructions authority: split the audiences, keep the rules, move the stories

The worker-facing instructions file is loaded by the routers into **every session AND every spawned agent**, so its length is paid more often than any other file's — more often than State's, which is read once per top-level session. First move project-specific supervision, integration, and certification rules that a terminal worker cannot use to `project_instructions_supervisor.md`; keep every worker imperative in `project_instructions.md`. The sole conditional top-level load edge stays at the top of the worker-facing file, and routers never import the supervisor file directly. `_agents/universal/instruction-topology.md` owns that audience contract.

The remaining worker-facing file grows for a good reason: a rule that cost something to learn gets its incident narrative written beside it, and those narratives are why the rules hold. They are not waste. They are simply in the most expensive place in the repository.

**The split.** The *rule* stays where an agent reads it. The *narrative* moves to **`_agents/project_instructions_archive.md`** — a subordinate appendix of the instructions file, never read at session start, opened only when someone wants the reason behind a specific rule — and the rule keeps a **bare pointer** to the entry holding its evidence.

**Not Rationale, and the distinction is worth stating because it was got wrong once.** Rationale is a file that *is* read: it holds settled decisions an agent consults to avoid re-deciding something. Spent incident evidence is inert — nobody needs it while working — so putting it there swaps one loaded file for another and saves less than it appears to. A decision with a reopening condition belongs in Rationale; the story of how a rule was learned belongs in the archive.

**Keep the pointer bare.** Retaining a sentence of cost inline feels safer and is where most of the length actually is; the imperative plus a pointer is enough, because the rule is what must be obeyed and the story is what must be *findable*.

**Never move a passage that IS the rule.** A quoted user ruling is the authority itself — moving it leaves a weaker rule, not a shorter one. Same for any rule whose wording is the thing being enforced.

**This one takes judgment and must not be run mechanically.** Compress only where the rule is fully intelligible without the story. A narrative stays inline when it is load-bearing **in the moment of reading** — typically when the failure mode is invisible or counter-intuitive, so an agent who knows only the rule would not recognise the situation the rule is about. When in doubt, leave it: a rule nobody understands is worse than a file that is slightly too long.

**Verify the same way:** record before/after byte counts, confirm no rule lost its meaning, and run whatever documentation checks the project has rather than reading them.

**And check what the move did to those checks.** A check that scans for *identifiers* keeps working and fails loudly if one is dropped. A check that scans a *body* is the dangerous one: once the bodies move it finds nothing to object to and **keeps passing while no longer checking anything.** Point it at the archive as well, and **prove it can still fail** by reintroducing the defect it exists to catch.
