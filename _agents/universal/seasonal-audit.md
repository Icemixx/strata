# Seasonal Full-App Audit (command)

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/seasonal-audit.md`. Load when the user asks for a "seasonal audit", "full-app audit", or "refactor audit". This is a periodic whole-repo health check: the Supervisor routes planning and mechanical sweeps to the lowest capable tiers, then owns final verification. Apply DAP Level 1 (`_agents/universal/dap.md`) to every proposed change; Level 2 remains explicit-only. Update the project's living docs for anything you change.

**Before starting, read the project file's `AUDIT_ADDENDUM`** — it holds the stack-specific checklists, invariants, and non-negotiable constraints. The universal protocol:

**Step 0 — Discovery (always first)**

- Inventory source files: path, size, role. Flag oversized modules (project threshold; default ~500 lines).
- Map the persistence layer: definitions vs actual usage — catalog what is CREATED vs what is USED; flag drift both ways.
- Deliver the inventory + a high-level assessment BEFORE drilling into modules; then drill in on request.

**Categories**

1. **Data & schema integrity** — drift, missing constraints, orphaned structures, naming inconsistencies, violations of the project's stated schema rules.
2. **Query / data-access safety** — injection surfaces (string-built queries vs parameterized), unbounded reads, N+1 patterns, index-defeating predicates, transaction/commit placement.
3. **Principles & smells** — DRY / KISS / YAGNI; SRP (long functions/modules, God Objects); Open/Closed; dependency inversion (receive connections/resources, don't self-instantiate); Law of Demeter; CQS; SLAP; fail-fast (no swallowed errors returning fallback data indistinguishable from success); defensive guards. Dead code: zero-caller ≠ dead — CONFIRM intent before recommending removal.
4. **Architecture checks** — the project file's layer boundaries and isolation rules, verified import-by-import.
5. **Tests** — map coverage against `TEST_SUITE`; flag critical paths with zero tests; check tests assert behaviour, not just "no exception".
6. **Robustness / performance / security / dependencies** — swallowed exceptions, import-time crash risks, shared mutable state, hot-path DDL, unpinned/unused dependencies, any NEW hardcoded secret.

**Output**

- Discovery inventory (file/role/size).
- Findings by category: each with file:line, severity (critical/high/medium/low), and a concrete fix.
- Prioritized plan: each step classified by tier (B6) and shipped with its verification (B7), plus a devil's-advocate critique of the step.
- A concise tracking checklist.
