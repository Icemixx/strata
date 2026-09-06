# Audit

Use this method for a seasonal, full-application, or refactor audit, and for auditing the authority
records themselves. The audit is read-only unless the user separately authorizes remediation.

Two objects, audited together because the second is nearly free once the first is under way: the
**application**, and the **authorities that describe it**. Verifying a record against the code is the same
reading as auditing the code, done from the other direction.

## Establish coverage

Record the repository revision, requested scope, explicit exclusions, available environments, and every
important gate that will not be run. Read Project Instructions and follow any routed stack-, domain-, or
product-specific audit checks. Do not imply coverage of an unexamined surface.

Inspect applicable behavior, data integrity, architecture, maintainability, tests, security and privacy,
dependencies, and dead or duplicated code. Use direct evidence where possible and label inference,
uncertainty, and environmental limitations.

## Audit the records

`consolidation.md` already says what to do with a duplicated, superseded or conflicting claim once it is
in front of you. **Nothing otherwise sends anyone to look**, which is how a repository carries records
that flatly contradict each other for months. Looking is this procedure's job; fixing is that one's.

- **Duplicates.** One claim stated in two places drifts the moment either is edited.
- **Contradictions.** Two records disagreeing about one fact. A conversion conserves, and conservation
  preserves an error as faithfully as a fact, so a converted tree is where these collect. They survive
  every structural check ever written: both statements are present, both are cited, both resolve.
- **Superseded claims.** A record stating what was decided, where a later decision reversed it and left
  the older one live. Date order is evidence, not proof — say which ruling governs and why.
- **Truth.** A record's claim about the software, checked against the software. This is the one no
  structural check can approach and the reason the audit reads both objects at once: a claim can be
  current, cited, unique, uncontradicted, and false.

Report each as a finding with its two locations. Do not resolve a conflict by picking the newer text and
moving on — `consolidation.md` step 3 ends at *surface the competing claims and ask the user*, and that
holds here.

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

## What a clean result means

A tool that reports nothing has either found nothing or cannot see anything, and the two are
indistinguishable from the outside. Say which checks ran, over what, and what each could not see. A record
audit that reports clean without naming its blind spots claims more than it established.
