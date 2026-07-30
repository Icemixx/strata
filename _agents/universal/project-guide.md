# Technical Guide and five-authority procedure

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/project-guide.md`. Load before creating or materially updating a Technical Guide, adopting the five-authority model in an established repository, classifying documentation, or validating Guide structure.

## Authority routing

The project has exactly five authorities. Do not solve overlap by silently duplicating text.

| Authority | Owns | Update rule |
| --- | --- | --- |
| Guide (`TECHNICAL_GUIDE`) | Current software architecture, behavior, operator/developer technical workflows, technical conventions, and intrinsic limitations | Update current claims in place. |
| State (`REFERENCE_PLAN`) | Current reality, scope, active backlog, priorities, approvals, unresolved defects/limitations needing work, acceptance gates | Update current claims in place. |
| Rationale (`REFERENCE_PLAN`) | Settled why, rejected alternatives, explicit reopening conditions | An unresolved decision stays in State; consolidate only superseded claims. |
| Build Log (`REFERENCE_PLAN`) | Dated actions, commands actually run, exact observed results/evidence | Append events; consolidate only superseded claims. |
| Instructions | Mandatory agent conduct, protocol parameters, enforcement rules, and pointers to the Guide | Update in place; link to the Guide instead of duplicating its architecture or workflow material. |

Place a stable suite path and default invocation in Instructions; put a planned acceptance command and expected result on the State ticket; put the exact dated run, environment, and observed result in the Build Log. The Guide describes the stable technical workflow, not a mutable status report.

## Guide contract

`TECHNICAL_GUIDE` defaults to `_agents/project_guide.html`. It is one offline, self-contained HTML file: inline CSS, JavaScript, and assets only. It must have unique IDs; resolved internal and cross-file anchors; valid relative links; and no externally loaded script, stylesheet, font, image, frame, or CSS `url()` resource. Use semantic structure and stable headings/anchors so inbound links remain durable.

Structural validation proves only structure, not content completeness. A headless render or screenshot is optional visual evidence and never replaces link/resource checks or human review of accuracy.

README is a human entry and redirect, not a sixth authority. It may name run/build entry points, but must not duplicate architecture, current status, counts, or release claims; link to the owning authority instead.

## New project

1. Create the five authorities at their declared paths. Set `TECHNICAL_GUIDE` and keep `REFERENCE_PLAN` limited to State, Rationale, and Build Log.
2. Create the Guide from the codebase and confirmed workflows. Include current software architecture, behavior, operator/developer technical workflows, technical conventions, intrinsic limitations, and stable links to the other authorities.
3. Add an initial State snapshot, any settled Rationale entries, and a dated Build Log initialization event with observed setup evidence.
4. Validate the Guide structurally and review it for accurate ownership before treating setup as complete.

## Established repository adoption

1. Inventory project documentation, routers, inbound links, and legacy authority claims before editing. Exclude secrets, credentials, personal/local settings, transcripts, memory, caches, and logs from copying or migration.
2. Classify each clause, not merely each file: current technical truth → Guide; current execution truth and unresolved work → State; settled why → Rationale; dated proof → Build Log; mandatory rules → Instructions. Stop and ask when a mixed or ambiguous clause cannot be classified safely.
3. Preserve accurate dated history. Update or consolidate only a claim that is now wrong according to `_agents/universal/consolidation.md`.
4. Repoint live inbound links and anchors. Deliberately retire, redirect, or reduce duplicate live authorities only after their current content has a single owning destination; never silently delete original material.
5. Keep routers bare. Never copy administrator-managed policy, local state, secrets, transcripts, memory, caches, or logs.

## Validation

Before reporting completion, verify:

- every project authority has one non-overlapping role and all live inbound references reach it;
- IDs are unique; internal fragments resolve; referenced relative files and cross-file fragments resolve;
- no external script, stylesheet, font, image, frame, or CSS URL is loaded;
- no duplicate live authority or README status/architecture copy remains;
- structural validation and optional rendering are reported separately from human completeness review.
