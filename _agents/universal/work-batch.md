# Work batches — finish the authorized queue, report once

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/work-batch.md`. Load before beginning or resuming one or more authorized work items, including after context compaction.

## The unit of work

**The reporting unit is the work batch, not one ticket.** A work batch has a finite authorized starting queue and may admit only the bounded verified follow-up items this procedure permits. It closes only when the fresh queue check below finds no ready or in-flight batch item. Never infer the batch from every open heading in a project's backlog.

Keep the batch in the project's authoritative queue or plan. Ensure each batch item has a status, dependency order, assigned tier or owner, and a concrete done-when check; for every newly admitted follow-up, also record its originating ticket or sweep. An item is **ready** only when it is inside the current authorization, has a safe concrete next action, and has no unmet dependency, unresolved decision, protected-scope conflict, credential requirement, or external blocker.

An adjacent-sweep finding joins the active batch only when it is verified, recorded as a separate ticket, within the approved scope and risk class, supplied with its order and verification, and otherwise ready. A finding that needs new product, architecture, security, destructive-action, cost, or external authority stays recorded for later disposition. Read-only work never gains mutation authority from this rule.

## Closing one ticket

The kit previously delegated this entirely to each project, which left rules about *when to stop working* with nowhere to attach — so they floated in sections read once at session start and never consulted at the moment they applied. **A rule inside a procedure you are already executing gets followed; a rule on its own gets read once.** Projects add their own steps; this transaction is the universal floor.

Use only these semantic states:

- `OPEN`: no completion claim; ready, queued, or not yet classified further.
- `PARTIAL`: some work or evidence exists, but an owned gate remains. Record every outstanding gate,
  owner, unblock condition, and next action.
- `BLOCKED`: no safe useful next action exists without the named external change or authority.
- `DONE`: every ticket-owned Done-when gate is met. No pending device, publication, fresh-session,
  follow-up, dependency, or observation clause remains owned by this ticket.

A remaining gate may be split into a new ticket before the parent closes only when the split is explicit,
the new ticket owns that gate completely, and closing the parent does not imply the split work happened.
Otherwise the parent is `PARTIAL`. Phrases such as “DONE in source; device pending” are contradictions.

Close a ticket atomically, in this order:

1. **Run and record the final evidence, then classify every gate.** “Verified” is a claim; literal command
   output, counts, environment, and observations are evidence. Tests prove logic, not rendering,
   interaction, publication, or real-world behavior.
2. **Retitle the ticket to what actually shipped** when the intention and result differ. Record decisions
   taken during implementation, including verified findings deliberately not fixed.
3. **Resolve provenance before moving the body.** A closed compact record carries exactly one form:
   - `COMMIT:<oid>` — `git cat-file -e <oid>^{commit}` or an equivalent native command succeeds in
     this repository for an already-created substantive work commit, that commit is an ancestor of the
     closing revision, and the dated Build Log evidence target names the same OID;
   - `EVIDENCE-ONLY:SELF-RECORD` — the only possible commit is the records-only closure commit;
   - `EVIDENCE-ONLY:NO-RESOLVABLE-SOURCE` — historical work has no provable prior in-repository commit.

   An evidence-only form must cite a dated Build Log record and literal gate evidence, and explain why
   no commit can be named. Free-text “unknown”, an incidental hexadecimal string, a commit from another
   repository, a guessed subject match, or shallow-history absence is not resolved provenance. Report
   `missing-local-object` or `shallow-history` non-green; never repair it heuristically. A closure-record
   commit cannot cite its own hash—the hash changes when inserted—and is not retroactively the shipping
   commit.
4. **Move the complete specification and Done-when text verbatim** to
   `_agents/project_state_archive.md` under the same unique ticket ID. State retains one
   machine-parseable compact line with identifier, shipped title, tier, dependency, `DONE`, date,
   provenance, and dated evidence pointer. Do not periodically or threshold-compact: every closure does
   this immediately.
5. **Update the other owning records and every mechanical reference.** Correct contradicted current
   claims now. Record dated decisions in Rationale, actions/evidence in Build Log, and stable technical
   behavior in the Guide where applicable. Date work when it happened, not when it was noticed.
6. **Run `AGENT_SYSTEM_CHECK`, `<AGENT_SYSTEM_CHECK> --self-test`, and the ticket's project gates.** Any
   body-sensitive check must scan State and its archive and must have a negative fixture proving it
   still fails after compaction.
7. **Commit the closure records.** This commit records closure; it is not a self-referential shipping
   citation. Push according to the core publication rule. Publication or fresh-session certification
   still owned by the ticket keeps it `PARTIAL` until separately evidenced.
8. **Anything found-but-not-fixed becomes its own queue item immediately**, with scope, owner, order,
   and verification or an explicit negative disposition.
9. **Return to the batch queue.** Closing a ticket is not a completion milestone.

**The enforcement is a check, not a resolution to be careful.** At the **start** of every ticket, run the project-native checks that prove the previous one's status reflects reality, its archive/evidence records exist, and its provenance resolves. This exists because diligence degrades exactly when throughput rises, which is when the record matters most.

## Records continuously; report once

Complete and record each ticket according to the project's rules **and the closing checklist below**, then return to the batch queue. Completing, committing, documenting, or sweeping one ticket is not a completion milestone for the batch. A new finding is a queue event, not a chat-report event.

Do not issue a user-facing per-ticket progress report, completion summary, or sweep recap while independent ready work remains. Issue one completion report when a fresh queue check shows:

1. no ready or in-flight batch item remains;
2. every finding has a recorded ticket or explicit negative disposition;
3. every completed item has its required records and verification evidence; and
4. every blocked or deferred item names its evidence, owner, unblock condition, and next action.

One blocked item does not stop independent ready work. A pending command or delegated worker is in flight, not a reason to report completion; wait for it and continue anything independent. Spawning a worker does not earn permission to stop, and a worker's result is not verification evidence until the supervisor checks it.

## Legitimate interruptions

Interrupt the batch before its ready queue is exhausted only when:

- the user explicitly asks for status, changes scope, or stops the work;
- a decision that cannot be resolved from governing records is required before any remaining useful action; or
- a safety, destructive-action, credential, external-state, or similar blocker prevents every remaining useful action.

Search the governing records before asking for a decision. Record the evidence and exact unblock condition before reporting a blocker. If one item needs a decision or is blocked while independent ready work remains, park it and continue the independent work first.

This rule governs substantive user-facing reports. It does not suppress a terminal worker's result to its supervisor, a mandatory `loaded:` marker, a harness-required non-terminal status update, a handoff required by context or usage limits, or a disclosure another governing protocol requires, including a DAP decision write-up or the mandatory shared-kit change notice. Keep such protocol messages minimal and do not disguise a completion summary as a status update. After a required disclosure, continue independent ready work where the harness and governing protocol permit it. Runtime persistence is harness-specific: durable records and handoffs protect interrupted work; prose, background workers, commits, and timers are not universal liveness guarantees.
