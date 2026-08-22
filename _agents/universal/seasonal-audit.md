# Seasonal Full-App Audit (command)

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/seasonal-audit.md`. Load when the user asks for a "seasonal audit", "full-app audit", or "refactor audit".

This is a periodic whole-repository health and correctness review. It answers three separate questions:

1. **Structural health** — is the codebase maintainable, robust, secure, testable, and consistent with its intended architecture?
2. **Behavioral correctness** — does the implementation perform the behavior the project says it should, including boundary, failure, persistence, concurrency, and state-transition cases?
3. **Engineering value** — which fixes or refactors are genuinely worth making after benefit, user impact, maintenance value, complexity, regression risk, and effort are considered?

The goal is not maximum refactoring. "Leave this alone" is a valid and often preferable conclusion. Do not recommend a change merely because another abstraction, pattern, decomposition, or newer dependency exists.

The Supervisor routes bounded planning and mechanical sweeps to the lowest capable tiers and owns final verification. Apply DAP Level 1 (`_agents/universal/dap.md`) to proposed changes that meet the core big-decision threshold: architecture, schema, security-sensitive paths, or anything expensive to reverse. Every other non-trivial recommendation follows the core decision-transparency rule; maintainability and refactor recommendations also receive the Engineering-value test. Level 2 remains explicit-only. Group coupled proposals into one decision where that is the honest decision boundary. An audit recommendation or priority label is analysis, not authorization to implement it.

## Operating boundary

- **Default to inspection and reporting only.** Unless the user explicitly authorizes remediation, do not edit source, tests, generated files, configuration, or dependencies. Write only the audit artifact or project records that the user's request or the project's audit-reporting protocol requires; that recording obligation never grants production-code mutation authority.
- Safe read-only discovery and non-destructive verification are allowed. Do not touch devices, accounts, external services, persistent user data, or run potentially destructive or state-changing checks unless the user has authorized that exact scope. List such checks as unrun gates.
- Do not print secrets, credentials, private user data, or unfiltered contents of potentially sensitive files into evidence artifacts.
- Follow the project's declared authority and precedence rules. Check freshness and supersession before treating a requirement as current. Record contradictory authorities as findings; do not silently select whichever one matches the code.
- Read the project file's `AUDIT_ADDENDUM` before starting. It owns stack-, architecture-, domain-, and project-specific invariants, intentional exceptions, framework checks, and non-negotiable constraints. The project file wins on conflict. The universal audit cannot narrow an addendum requirement.

## Step 0 — Coverage contract and discovery

Before detailed findings, establish a finite coverage contract:

- Record the revision and working-tree state being audited.
- Name the in-scope roots and explicit exclusions. Classify generated, vendored, binary, cache, build-output, archive, fixture, and dependency material rather than accidentally treating it as first-party source.
- Identify the project's governing behavior and requirements sources in their declared precedence order.
- Inventory in-scope source files by path, size, and role. Flag oversized modules using the project threshold (default about 500 lines), but size alone is not a refactor justification.
- Map major subsystems, dependency direction, state ownership, persistence boundaries, external integrations, and important data flows.
- Map persistence definitions against actual usage: catalog what is created and what is used, and flag drift in both directions.
- Select the material user-visible, business-critical, security-sensitive, and data-loss-sensitive flows that require end-to-end tracing. State the risk basis for any sampling.
- Create a coverage ledger. Every in-scope subsystem, selected flow, and applicable addendum invariant ends as **reviewed**, **excluded with reason**, or **not assessed with blocker**.

Produce the inventory, coverage contract, and high-level assessment as an internal or project-recorded checkpoint before detailed findings. For a full-app, refactor, or seasonal audit, continue through the declared scope unless the user requested discovery only. Communicate interim and final results according to the project's reporting rules.

Completion means the declared coverage ledger is closed honestly; it does not mean every possible runtime behavior has been proven correct.

## Audit lenses

These are lenses, not finding quotas. Give each finding one primary lens and optional cross-cutting tags; cross-reference rather than duplicate it.

1. **Behavioral and domain correctness** — compare implementation with current governing requirements and invariants. Trace material flows from entry point through validation, state transitions, writes, reload/sync consequences, and user-visible outcome. Check calculations, ordering, boundary cases, failures, async/concurrency behavior, and cross-component assumptions. Tests are evidence, not automatically the specification.

2. **Data, schema, and access integrity** — schema drift, missing constraints, orphaned structures, invalid-state representability, naming inconsistencies, migration/versioning hazards, injection surfaces, unbounded reads, N+1 patterns, index-defeating predicates, stale reads, partial writes, transaction placement, and incorrect consistency assumptions.

3. **Architecture, principles, and maintainability** — verify stated layer and responsibility boundaries import-by-import and along actual call paths. Check dependency direction and inversion (receive connections/resources rather than self-instantiating them), state ownership, coupling, DRY, KISS, YAGNI, SRP, Open/Closed, Law of Demeter, CQS, SLAP, fail-fast behavior, unnecessary abstraction, premature generalization, wrapper/helper proliferation, duplicated business rules, excessive indirection, and overly clever code. Judge against the project's real needs, not architecture fashion. Identify structures worth preserving.

4. **Framework, lifecycle, and state correctness** — apply the addendum's stack-specific rules. Check lifecycle leaks, invalid or duplicated state ownership, async races, stale state, inappropriate side effects, unnecessary recomputation or rebuilds, unsafe callbacks/context use, cleanup/disposal, and framework-pattern misuse. Separate material defects from micro-optimizations.

5. **Tests and verification quality** — map coverage against `TEST_SUITE`; find critical behavior with no regression protection, assertions that prove only "no exception", missing boundary/failure cases, brittle implementation-coupled tests, duplicated tests, mocks standing in for critical integration paths, and tests incapable of detecting the defect they claim to cover. Record commands actually run and literal results. A passing suite does not end the correctness review.

6. **Robustness, security, privacy, performance, and dependencies** — swallowed exceptions; believable empty/default/success fallbacks; inconsistent post-failure state; retry and cleanup hazards; import/startup crash risks; shared mutable state; meaningful hot-path inefficiency or unbounded work; unsafe input; trust-boundary, authentication, authorization, privilege, or network-surface violations; secret exposure or any new hardcoded secret; sensitive logging; unused, unpinned, deprecated, or problematic dependencies; and unnecessary packages. State when current advisory or external verification was not performed. Do not recommend an upgrade solely because a newer version exists.

7. **Dead, duplicate, and suspicious code** — unreachable or abandoned implementations, stale compatibility paths, duplicate implementations, unused helpers/types/providers, TODO/FIXME/HACK markers, and remnants of removed features. Zero callers does not prove dead code: confirm intent and history before recommending removal.

## Addendum invariant ledger

Re-verify every applicable `AUDIT_ADDENDUM` invariant and intentional exception. Record each as:

- **Pass** — with the source, command, or trace that supports it;
- **Finding** — linked to the corresponding finding entry; or
- **Not assessed** — with the blocker and exact verification still needed.

Project constraints and non-negotiable security, privacy, data-integrity, domain, or architecture boundaries are pass/fail obligations. Refactor economics cannot waive them.

## Evidence and classification

Do not manufacture findings to populate a lens. There is no finding quota, and an empty lens is a valid result.

Every finding must distinguish fact from inference and include:

- one primary lens and any cross-cutting tags;
- classification and severity;
- the governing requirement or invariant when correctness is at issue;
- exact, stable evidence using the project's citation convention (for example file plus symbol, test, command, or commit; line numbers may supplement an audit artifact when useful);
- evidence type: static trace, requirement contradiction, failing test, reproducible runtime observation, device/external evidence, or another named type;
- why it matters and affected callers or flows;
- concrete fix or disposition;
- verification already observed, plus any unrun confirmation or falsification gate.

Classify each finding as one of:

- **Verified defect** — incorrect behavior is demonstrated by a logically conclusive trace, requirement contradiction, failing assertion, or reproducible observation.
- **Probable defect** — strong evidence of incorrect behavior exists, but a named confirmation gate remains.
- **Maintainability issue** — behavior works, but the structure creates meaningful continuing cost or risk.
- **Refactor opportunity** — a change has a concrete, defensible net benefit.
- **Optional polish** — valid but low-value improvement.

Do not inflate severity or convert a probable defect into a verified one because the missing gate is inconvenient. Report confidence and untested surfaces per material flow. Never issue a blanket certificate that the whole application is behaviorally correct.

## Engineering-value test

For every maintainability recommendation or refactor opportunity, assess qualitatively:

- current concrete problem and present cost;
- proposed change;
- user/correctness and maintenance benefit;
- affected callers and side effects;
- implementation effort and verification burden;
- regression and added-complexity risk;
- consequence of doing nothing.

The burden of proof is on the refactor. Prefer boring, explicit, understandable code. Duplication can be cheaper than abstraction, and a large cohesive module can be better than arbitrary fragmentation. If benefit does not clearly exceed complexity, regression risk, and effort, recommend leaving the code unchanged.

## Output

- Discovery inventory, subsystem/data-flow map, and closed coverage ledger.
- Executive assessment of structural health, behavioral-correctness confidence and limits, highest material risks, maintainability, and whether the codebase needs broad refactoring, targeted remediation, or little structural change.
- One deduplicated finding ledger using the evidence contract above. Omit empty finding sections; include the addendum invariant ledger separately.
- Strong areas and structures that should be preserved.
- Prioritized remediation/refactor plan. Each proposed change is classified by tier (B6) and includes verification (B7). Proposals meeting the core big-decision threshold receive DAP Level 1. Other non-trivial recommendations receive normal decision transparency, and maintainability or refactor recommendations receive the Engineering-value test. Do not manufacture a full DAP decision for routine work; coupled proposals may share one decision critique when they form one honest decision boundary.
- Qualitative prioritization that separates hard obligations from discretionary improvements, then sorts recommendations into:
  - **Fix now**
  - **Worth improving**
  - **Only if touching this area anyway**
  - **Do not change**
- Concise tracking checklist and an explicit list of exclusions, blockers, and unrun gates.

Finish by answering:

1. What are **up to five material code-related risks** if the code ships as audited? Report fewer, including none, when fewer are supported.
2. What are **up to five highest-value improvements**, independent of architectural fashion? Report fewer, including none, rather than padding the list.
3. Which parts should specifically **not** be refactored because they are already appropriately simple, cohesive, or intentionally structured?
