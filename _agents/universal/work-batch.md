# Work batches — finish the authorized queue, report once

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/work-batch.md`. Load before beginning or resuming one or more authorized work items, including after context compaction.

## The unit of work

**The reporting unit is the work batch, not one ticket.** A work batch has a finite authorized starting queue and may admit only the bounded verified follow-up items this procedure permits. It closes only when the fresh queue check below finds no ready or in-flight batch item. Never infer the batch from every open heading in a project's backlog.

Keep the batch in the project's authoritative queue or plan. Ensure each batch item has a status, dependency order, assigned tier or owner, and a concrete done-when check; for every newly admitted follow-up, also record its originating ticket or sweep. An item is **ready** only when it is inside the current authorization, has a safe concrete next action, and has no unmet dependency, unresolved decision, protected-scope conflict, credential requirement, or external blocker.

An adjacent-sweep finding joins the active batch only when it is verified, recorded as a separate ticket, within the approved scope and risk class, supplied with its order and verification, and otherwise ready. A finding that needs new product, architecture, security, destructive-action, cost, or external authority stays recorded for later disposition. Read-only work never gains mutation authority from this rule.

## Records continuously; report once

Complete and record each ticket according to the project's rules, then return to the batch queue. Completing, committing, documenting, or sweeping one ticket is not a completion milestone for the batch. A new finding is a queue event, not a chat-report event.

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
