# Self-critique menu — situational variants (D3–D12)

Part of the universal agent set (core: `_agents/universal_agent_instructions.md`). On loading this file, announce it with one visible line: `loaded: _agents/universal/self-critique.md`. D1+D2 — the mandatory minimum before closing any significant work block — live in the core (Part D). Load this menu when closing a LONG or HIGH-STAKES work block, or when the user asks for a deeper self-review. Bake these into prompts rather than ad-hoc asks; explicitly ALLOWING the model to call out uncertainties and to push back beats an artificial "everything is fine" grin.

**SITUATIONAL variants:**

- **D3.** Long session: "Which of your earlier recommendations are you least sure about now that we've gone deeper?" — catches decisions made early on thin context and never revisited.
- **D4.** "What assumptions did you make in this conversation that you never stated explicitly?" — surfaces confident silent assumptions (especially architectural ones in code review). Overconfident errors do NOT show up under D1: the model only flags what it knew was shaky.
- **D5.** "If this breaks in 3 months, what's the most likely reason?" — future fragility, a different failure mode from present-state gaps.
- **D6.** After any claim of DONE: "What didn't you do? Audit and tell me all the things you skipped, missed, or ignored."
- **D7.** "Walk me through how you checked that" — demand shown work and definitive evidence for claims (especially while debugging), not summaries taken at face value.
- **D8.** Retrospective pair: "What could I have done differently to make this session more efficient?" and "What tools, scripts, or docs would have reduced your churn had they existed when we started?" — then actually create the winners, so the repo gets more agent-friendly each session.
- **D9.** Quick lightweight close when time is short: "Any outstanding questions or punts?"

**FRESH EYES:**

- **D10.** The same thread that made a confident call will defend it, not flag it. For important results, paste the final output into a fresh session (or a different model) with zero authorship context: "Evaluate this response. What is missed or wrong?" The new instance has no ego and will shred its own previous work.
- **D11.** For really important work, request an independent panel review — this already exists as DAP (`_agents/universal/dap.md`): invoke the council instead of improvising one.

**STRETCH** (sparingly — known hallucination/scope-creep risk; end-of-work polish only, with extra guidance):

- **D12.** "If you could add one unrequested thing that would make this module truly outstanding, what would it be?"
