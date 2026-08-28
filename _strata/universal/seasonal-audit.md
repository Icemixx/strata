# Seasonal audit

Use this method for a seasonal, full-application, or refactor audit. The audit is read-only unless the
user separately authorizes remediation.

## Establish coverage

Record the repository revision, requested scope, explicit exclusions, available environments, and every
important gate that will not be run. Read Project Instructions and follow any routed stack-, domain-, or
product-specific audit checks. Do not imply coverage of an unexamined surface.

Inspect applicable behavior, data integrity, architecture, maintainability, tests, security and privacy,
dependencies, and dead or duplicated code. Use direct evidence where possible and label inference,
uncertainty, and environmental limitations.

## Classify findings

- **Verified defect:** directly demonstrated incorrect behavior or violated contract.
- **Probable defect:** evidence strongly indicates a defect, but a required observation is missing.
- **Maintainability issue:** current behavior may work, but the design imposes a concrete ongoing cost or
  risk.
- **Optional improvement:** useful polish with no present correctness or maintenance failure.

Prioritize by impact, likelihood, scope, and remediation cost. Deduplicate findings that share one cause.
Recommend a refactor only when its expected benefit exceeds migration and regression cost. Do not
manufacture findings, inflate severity, or treat fashionable architecture as evidence.

Report strengths and areas that should remain unchanged alongside the prioritized findings. For each
finding, provide its evidence, affected scope, confidence, consequence, and smallest credible next step.
