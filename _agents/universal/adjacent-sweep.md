# Adjacent sweep — look past the edges of the ticket you were given

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/adjacent-sweep.md`. Load when finishing an implementation task, or when writing a delegation brief for one.

**A ticket describes one instance of a problem. It almost never describes the only one.** The sweep is the step between "the fix works" and "the fix is done": having just understood a defect well enough to repair it, you are momentarily the best-placed person alive to find its siblings — and that understanding evaporates the moment you move on.

## The rule

**After the named fix passes, and BEFORE the ticket is closed, search for the same class of defect elsewhere.** Not "review the codebase" — that is unbounded, wastes tokens, and stalls (core A4). The question is narrow and answerable:

> This bug had a *shape*. Where else does that shape exist?

Name the shape explicitly before searching, because the name is what makes the search bounded. "A magnitude parameter documented as unsigned that silently applies `abs()`." "A widget removed while pre-existing tests still drive it." "A row written through a path that bypasses the validation every other path enforces." "State set at init that lives behind a collapsed disclosure." Then grep for that shape, and read what you find.

## Non-negotiables when sweeping is enabled

- **Findings become separate tickets, not silent scope expansion and not reporting triggers.** A sweep that quietly widens the current diff is worse than no sweep: it smuggles unreviewed work in under a ticket the reviewer thinks they understand. Repair only what is genuinely inside the ticket you were handed. Record every verified sibling separately. During an active work batch, the supervisor admits an eligible sibling to that batch in its normal dependency and priority order; otherwise it remains recorded for later. A finding by itself is never a reason to issue a progress report.
- **Check whether it is actually wrong before calling it wrong.** A sibling that *looks* like the bug is frequently deliberate, documented, or covered by a test you have not read. Verify first. A sweep that cries wolf trains the next reader to skip sweep findings.
- **Record negative results.** "The sweep found no further instance of X, having checked Y and Z" is a real finding: it stops the next session re-searching the same ground, and it is honest about what was and was not looked at. Silence reads as "nobody looked."
- **Delegated workers must be told to sweep.** A worker handed an exact scope implements exactly that scope and nothing looks past the edges. If the brief does not ask for a sweep, no sweep happens — so put it in the brief. The worker returns literal sweep evidence to its supervisor; it does not repair or schedule out-of-scope siblings itself. A worker-to-supervisor result is not a user-facing progress report.
- **Search by the property, not only by the pattern — and record which handle you used.** The shape you name is a *syntactic proxy* for a *semantic* set, and the proxy is almost always narrower. A member that satisfies the property while being spelled differently is invisible to the very search that defined the set — and the sweep reports the same "found N" whether or not it was complete, so **there is no failure signal and completeness has to be argued rather than assumed.** State the property that defines the set, enumerate by at least one handle that is *not* the one that defines it, and reconcile the two lists. Then write down the handle you used, so the next reader can see what it could not have seen. For example, a search keyed to a required parameter can miss an equivalent optional parameter under another name whose effective value comes from a fallback expression. A later audit may trust the recorded sweep unless the semantic set and search handles are explicit.
- **The durable form of a finished sweep is a gate, not a list.** If the set can gain members later — a new parameter, call site, subclass or enum case — then a sweep result is a snapshot that begins decaying the moment it is written, **and it keeps reporting success while it decays.** Where the project supports it, leave behind a check that fails when a new member appears unclassified, and prove that check can still fail by reintroducing the defect it exists to catch. A list in a record is a thing nobody re-runs.
- **One search layer, not a recursive audit.** Sweep the shape you just fixed once. Do not recursively sweep each sibling merely because the search found it. If a sibling later becomes its own implementation ticket, it receives the normal bounded sweep for the shape actually fixed, but the same search is not repeated without new evidence.

## Sweep classes worth checking by default

Not exhaustive; the shape of the actual bug always beats a checklist. But these recur across projects:

- **Bypass paths.** A validation enforced at one boundary is usually bypassed by another — bulk import, sync/merge, restore-from-backup, seed data, admin tooling, direct-write test helpers. Ask: what writes this table *without* going through the guard I just fixed?
- **The other callers.** You changed a function's contract; who else calls it? Including callers that only exist in tests, and callers that pass nothing and rely on a default.
- **The other direction.** You fixed A→B; does B→A have the mirror bug? Encode/decode, serialise/deserialise, apply/revert, add/remove.
- **Removals strand things.** Deleting a widget, key, string, parameter or route leaves behind code and tests that reference it — very often in files you never opened. Grep the whole tree, not just what you touched, and run those tests too.
- **The sibling field.** You fixed one column, parameter or enum case; look at the ones declared beside it. They were usually written in the same sitting by the same reasoning.
- **Stale claims near the change.** Comments, docs and record entries adjacent to your edit that described the old behaviour are now false. A confidently wrong comment outlives the person who wrote it.

## Why this exists

Empirically it is where the value is: a focused post-change sweep often finds adjacent defects that were
not part of the ticket but share its mechanism or boundary. Ask once what else looks like the thing just
fixed, then disposition every finding explicitly.

The counter-case matters too: tests can cover a changed item beside an independent sibling while missing a
dependent neighbour whose reference changes the outcome. Every named gate may pass while the dependency
path remains broken. The adjacent sweep asks what references, calls, or consumes the thing just fixed.

## Cost, stated so it is chosen deliberately

Sweeping makes every ticket slower and less predictable; a one-hour ticket can spawn four more. A user or project rule may explicitly opt out when throughput matters more than this extra coverage. Otherwise the sweep applies. Never skip it silently under time pressure.
