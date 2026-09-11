# Truth audit

Use this procedure for an unqualified, seasonal, full-application, or post-conversion audit, and for auditing the authority records. It examines whether records are accurate and sufficiently complete for their declared scope, and whether the application satisfies its governing requirements. The audit is read-only unless the user separately authorizes remediation.

Code is evidence of what happens, not automatic proof of what should happen. A record can describe a defective implementation accurately, and code and prose can agree while both violate a governing requirement. Those are correctness findings. A request for code simplification, maintainability, dead-code, or optimization opportunities uses `refactor.md`; do not start that separate review from this procedure unless the user asks for both.

## Set the depth before starting

Record the actual reasoning depth for each pass. Before beginning, read the applicable harness dossier for its audit guidance. If this session is below the stated level, tell the user and let them raise it; where the harness permits it, a delegated worker may run at a chosen level. Depth does not replace coverage: narrow a pass and say so rather than reading a broad scope shallowly.

## Declare coverage

Record the revision and worktree state, requested roots, records and flows, exclusions, available environments, selected checks, and gates that cannot run. Read Project Instructions and their routed audit supplement. Inventory material first-party surfaces and classify generated, vendor, archive, and test material by role. Every declared area ends reviewed, excluded with a reason, or not assessed with a named blocker. The archive is provenance only when the requested audit includes it.

## Establish governing claims

Read the relevant Instructions, technical State, tickets, Rationale, and Build Log with their different time meanings. A dated Build Log event remains a dated observation; its disagreement with current State does not establish a conflict merely because one is newer. Establish which requirements and invariants govern before treating an implementation, comment, or test as a pass.

## Check claims and behavior in both directions

Trace material requirements through entry points, validation, calculations, state transitions, persistence, reload or synchronization, failure handling, and user-visible outcomes. Inspect implementing code and callers; comments, test names, and passing tests are claims or evidence, not self-proving contracts. Also identify material behavior absent from the records when it exposes a missing claim within the declared scope.

Apply the relevant correctness lenses: data, schema, and access integrity; versioning and migration contracts; resource ownership and lifecycle; concurrency; error handling; security and privacy boundaries; and dependency behavior against required invariants. Test whether a relevant check can detect the claimed failure. Do not imply current external advisory research or runtime/device validation unless performed. Project hard constraints cannot be waived by refactor economics: report a demonstrated defect even when correction is expensive, and do not weaken a checker or substitute an unrelated green test for a required observation. Performance belongs here only for a demonstrated contract violation or unbounded resource behavior that threatens required operation; discretionary speedups belong to `refactor.md`.

## Compare records

Find duplicates, overlapping or contradictory claims, superseded claims left live, wrong current/completed status, missing qualifications, and broken evidence relationships. Use `consolidation.md` for the semantic definitions. Do not select the newest record merely to resolve a conflict: preserve competing claims and request the decision that evidence cannot supply. Intentional complementary records remain distinct.

## Report without fixing

Use the report path supplied by the user or project. Otherwise write `_sediment/truth-audit-YYYY-MM-DD.md`, adding the next unused `-2`, `-3` suffix on a same-day collision. Preserve an earlier-revision report rather than overwriting it, and link the report from the owning project work record under its recording rules.

For every finding, identify the claim or requirement, record and code or evidence locations (both records for a record conflict), observed result, verified or probable status, consequence, affected scope, missing evidence, and smallest correction. An absence finding names the searched scope and expected source. Deduplicate one cause while retaining affected occurrences. Refer an incidental structural opportunity to `refactor.md` without expanding this pass.

The report records revision, scope, coverage, prioritized findings, literal verification, exclusions, blockers, and supported strengths. It is **Complete for declared scope** when every required area was reviewed or explicitly excluded and findings were recorded; defects may remain unfixed. It is **Partial** when a required area was not assessed. Remediation status is separate. Do not claim whole-application correctness beyond the covered scope.

Close with up to five supported material correctness risks if the application ships as examined; fewer or none are valid. For the first post-conversion use, follow the project migration-audit supplement for its archive and conversion-evidence comparison. Completing that report does not complete migration, launch a refactor review, or generate a Guide.
