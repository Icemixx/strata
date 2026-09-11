# Code refactor review

Use this procedure for an explicit code refactor review, refactor audit, simplification review, or optimization opportunities. It asks what can be removed, simplified, consolidated, reorganized, or optimized while preserving required behavior, and whether the benefit is worth the change. An instruction to implement a named refactor authorizes only that stated work under ordinary execution rules; it does not start an unsolicited whole-codebase review.

This is a review of application code, architecture, data-access structure, dependency usage, and test maintainability. It is not documentation consolidation. `consolidation.md` owns authorized record repair; `audit.md` owns governing-claim and behavioral correctness findings. A demonstrated correctness, security, or data-integrity failure is reported under its own classification rather than presented as a refactor; project hard constraints are not tradeable against refactor economics.

The review reports proposals and structures to leave unchanged. It does not change production code, records, tests, dependencies, configuration, or project authorities unless the user separately authorizes that remediation.

## Declare coverage

Record revision and worktree state, roots, project constraints, runtime targets, integrations, unavailable checks, and actual reasoning depth. Read Project Instructions, the routed audit supplement, relevant architecture decisions, and intentional exceptions. Classify first-party, generated, vendor, archive, and fixture code by role. Every declared area ends reviewed, excluded with a reason, or not assessed with a named blocker.

Map actual imports and calls, entry points, state and resource ownership, persistence boundaries, and compatibility obligations. Dynamic discovery or external consumers limit conclusions; state that limit rather than treating a zero textual caller count as proof of dead code.

## Find candidates

Inspect implementations and callers using more than one search handle where one spelling can miss an equivalent. There is no module-size, finding, or architecture quota. Investigate:

- unnecessary branches, state, indirection, wrappers, parallel representations, or cleverness that has a demonstrated reading, change, or test cost;
- duplicated business rules or invariants, including dissimilar implementations that have drifted;
- unused speculative features, abstractions, configuration, extension points, or dependencies;
- responsibility mixing, dependency direction or cycles, ownership leaks, and change coupling on real call paths;
- unreachable or superseded code, stale adapters, unused helpers, and compatibility remnants after checking exports, callbacks, registration, builds, platform variants, supported data, and external consumers;
- material repeated work, avoidable queries, redundant reads or rebuilds, allocation, unbounded work, or unnecessary dependencies; and
- brittle test coupling, duplicated test purpose, misleading mocks, expensive setup, or missing characterization needed for a safe refactor.

Similar text, a preferred pattern, fewer lines, or one trace of non-use is not enough evidence. A large cohesive module is not defective because it is large. Retain intentional compatibility paths while their obligations remain.

## Establish the contract and value

For each proposal, name the behavior, interfaces, failure modes, data or persistence formats, ordering, concurrency, supported versions, and side effects it must preserve. Distinguish intended guarantees from accidental behavior. Identify a behavior change or bug fix as such; do not smuggle it into a refactor.

State the present cost and its evidence, smallest proposed change, alternative including leaving it alone, expected benefit, affected callers, migration and test effort, regression and complexity risk, and the cost of doing nothing. Performance proposals name the workload and a measured baseline when available; otherwise label the benefit unverified and name the measurement needed before choosing it.

## Report without implementing

Use the report path supplied by the user or project. Otherwise write `_sediment/code-refactor-review-YYYY-MM-DD.md`, adding the next unused `-2`, `-3` suffix on a same-day collision. Preserve an earlier-revision report rather than overwriting it, and link the report from the owning project work record under its recording rules.

The report contains coverage, literal measurements and checks, proposals with engineering-value assessments, incidental verified or probable defects, blockers and unrun gates, and structures worth preserving. Each proposal names stable code paths or symbols, affected callers or flows, evidence, assumptions, behavioral constraints, and a verification plan that could reject it. Prioritize as **worth doing**, **only when touching this area**, or **leave unchanged**. Report up to five supported highest-value improvements and explicit structures that should not be refactored; fewer or none are valid. These labels never authorize implementation.

Report an incidental correctness defect promptly with its own classification and link to `audit.md`; do not suppress it or expand into an unrequested truth audit. One underlying issue has one primary finding with cross-references, not duplicate mandatory ledgers.

The review is **Complete for declared scope** when every required area was reviewed or explicitly excluded and proposals and limitations were recorded, including when it recommends no refactor. It is **Partial** when a required area was not assessed. It is not a correctness certificate or a completed refactor. A later authorized implementation verifies preserved behavior with applicable existing tests and focused regression, characterization, or benchmark evidence; deleting an obligation to obtain green output is not success.
