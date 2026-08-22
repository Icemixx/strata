# Doc consolidation — current claims corrected, superseded claims folded in

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/consolidation.md`. Load when recording a decision that supersedes earlier recorded entries, or when the user asks for a doc cleanup. Adopted 2026-07-26 at the founder's direction, replacing the previous append-only rule for the Rationale and Build Log files.

## The rule

Keep the five authorities truthful without rewriting accurate history. Update current Guide claims, current State claims, and Instructions in place. For a later settled decision or verified fact that makes an earlier live Rationale or Build Log claim wrong, write one dated consolidated entry with the current fact plus the compressed chain of reasoning, delete only the superseded live claims, and name what it replaced.

## Scope and judgment

- Guide: update current software architecture, behavior, operator/developer technical workflows, technical conventions, and intrinsic limitations in place.
- State: update Current Reality, active work, gates, priorities, and unresolved items in place; closed ticket history is not erased.
- Instructions: update mandatory conduct, protocol parameters, enforcement rules, and Guide pointers in place.
- Rationale and Build Log: append new decisions/events by default; consolidate only superseded live claims, carrying forward durable lessons.
- Preserve accurate dated historical evidence, including incident lessons and observed verification, even when the architecture later evolves. When only a clause is stale, change that clause rather than deleting accurate context.

## Bounding State: the closed-item archive

State is the one authority the core requires to be read **through EOF** at every session start. That is correct while it describes current work and becomes a standing tax once it is mostly finished tickets — the read cost is paid by every session forever and grows monotonically. Split it when the finished-work majority is large enough to notice, not on a fixed threshold.

**The split, and the order matters:**

1. **Measure first and record the numbers** — bytes before, bytes after, and the share of the file that is closed work. Without them nobody can tell later whether the split was worth it.
2. **State keeps one compact line per closed item**: identifier, title, status, date, **the commit that shipped it**, and where its evidence lives. The commit hash is what makes the archive rarely worth opening at all.
3. **The archive receives only the moved detail** and opens with a header stating that it is a subordinate appendix of State, is not current truth, and loses to State on any conflict.
4. **Amend the read rule in the project's own instructions too**, not just the core. If any instruction still says to read State's history at startup, the split saves nothing — an agent will simply read both files. **This step is the entire win; the file move alone achieves nothing.**
5. **Re-point every mechanical check.** Checks that scan State for item identifiers, or cross-reference closed items against the Build Log, must still pass. Verify by running them, not by reading them.
6. **Move mechanically; do not prune while moving.** Deciding per item what is still worth keeping is a separate judgment pass with its own risk. A straight move is reversible and its benefit is immediate.

**Applies to State only.** The other authorities already have bounded read rules — the Build Log is read tail-first, Rationale through its settled register, the Guide by task-relevant section — so splitting them saves nothing at startup and costs a file. Note that a Rationale file with a settled-decision register at its head is already this pattern; State is adopting a structure the model has always had elsewhere.

**A related, smaller win worth checking at the same time:** the project instructions file is loaded on *every* session rather than read once, so length there is paid more often than anywhere else. Where a rule carries a long incident narrative inline, the rule stays and the narrative moves to Rationale behind a one-line pointer.
