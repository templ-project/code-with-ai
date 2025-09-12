## Your Tasks

1. **Requirements & References**
   - Read and synthesize all provided references. Identify ambiguities.
   - If assumptions are needed, list them explicitly under **Assumptions** and proceed.
   - Do not proceed to next task until you understand the requirements.

2. **Design**
   - Propose a lean solution sketch: key modules, data models, and flows.
   - Note relevant **design patterns** (e.g., Strategy, Adapter, Factory, CQRS) and why they fit.
   - Call out risks (perf, security, concurrency, migration) and mitigations.

3. **Implementation**
   - Write production-quality code with clear structure, small functions, and meaningful names.
   - Add logging where it helps debugging (not noise). Handle errors explicitly.
   - Keep public APIs stable; document any breaking changes.

4. **Testing (TDD)**
   - Start with failing unit tests that capture the acceptance criteria.
   - Aim for meaningful coverage of core logic and edge cases (not coverage theater).
   - Include fixtures/mocks for external I/O. Keep tests fast and deterministic.

5. **Documentation**
   - Update/produce concise README or module-level docs.
   - Include **Usage examples**, **Configuration**, and **Troubleshooting**.

6. **Validation**
   - Verify acceptance criteria (below) with runnable commands.
   - Run linters/formatters; ensure CI-friendly scripts are provided.

---

## Deliverables

- **Code** implementing the feature.
- **Tests** (unit, and lightweight integration if relevant).
- **Assumptions** list (only those you needed to make).
- **Design notes** (short rationale + patterns used).
- **How to run & test**: copy-paste commands.
- **Concise summary** of what changed.

---

## Acceptance Criteria (fill/adjust as needed)

- [ ] Functional behavior matches <FEATURE_DESCRIPTION> and/or <REFERENCES_OR_NONE>.
- [ ] Input validation and error handling are explicit and tested.
- [ ] Performance: meets <PERF_TARGETS_OR_DEFAULTS>.
- [ ] Security: no secrets in code; handles untrusted inputs safely; follows least privilege.
- [ ] Code follows the chosen style guide and passes lint/format checks.
- [ ] Tests: cover happy paths + edge cases; all pass locally with provided commands.
- [ ] Backward compatibility respected or intentionally versioned.
- [ ] Clear runbook/README updates provided.

---

## Output Format

Respond with:
1) **Assumptions**
2) **Design notes** (patterns, key decisions)
3) **Implementation** (code snippets or file diffs as needed)
4) **Tests** (TDD progression or final suite)
5) **How to run & test** (exact commands)
6) **Summary** (what you did + anything the reviewer should double-check)

Keep it crisp and reviewer-friendly.
