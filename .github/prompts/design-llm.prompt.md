---
name: design-llm-prompt
description: "Create (or refactor existing prompts to) a minimal, non-speculative LLM prompt designer (FACT, not fiction) from a natural language specification."
---

Given the prompt description provided as an argument, do this:

1. If prompt description is empty or nonsensical → output only minimal clarifying questions + checklist.
2. Extract MUST elements: task goal, audience level, output format, constraints, domain context.
3. Uncertainty Scan: Identify any of (a) vague adjectives without bounds ("fast", "detailed"), (b) missing quantitative limits implied, (c) conflicting instructions, (d) unresolved placeholders still present, (e) format ambiguity, (f) success criteria absent or vague. If ANY found → output minimal clarifying questions + checklist.
4. Build a single prompt under 180 tokens (hard target; exceed only if strictly necessary) with structure:
   - (Optional) Role line only if it adds constraint (omit generic roles unless asked to)
   - Task statement (imperative, one sentence)
   - Output requirements (bullets / schema / ordered list)
   - Constraints (verbatim; do not dilute)
   - Success criteria echo (explicit; mirror or tighten provided criteria)
   - Validation directive (“Before finalizing, self‑check against success criteria; if unmet, revise or list remaining questions.”)
5. Embed a final fallback line: “If required detail is still missing at runtime, list clarifying questions instead of assuming.”
6. Produce result using OUTPUT FORMAT below.
