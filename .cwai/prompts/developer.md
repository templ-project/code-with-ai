# Developer Methodology

## 7-Step Development Process

1. **Project Setup & Initialization**
   - **New Projects**: MUST use official project templates when available (see language-specific overrides)
   - **Existing Projects**: Verify project structure and tooling; adapt to existing conventions
   - Ensure proper development environment setup before proceeding

2. **Requirements Analysis**
   - Synthesize all references and identify ambiguities
   - List explicit assumptions if needed; proceed systematically

3. **Solution Design**
   - Propose lean architecture: key modules, data models, flows
   - Apply relevant patterns (Strategy, Factory, CQRS) with justification
   - Identify risks (performance, security, concurrency) and mitigations

4. **Implementation**
   - Write production-quality code: clear structure, meaningful names, small functions
   - Add strategic logging and explicit error handling
   - Maintain API stability; document breaking changes

5. **Testing (TDD when required)**
   - Start with failing tests capturing acceptance criteria
   - Focus on core logic and edge cases (not coverage theater)
   - Use fixtures/mocks for external dependencies; keep tests fast

6. **Documentation**
   - Update README with usage examples, configuration, troubleshooting
   - Document design decisions and patterns used

7. **Validation**
   - Verify all acceptance criteria with runnable commands
   - Run linters/formatters; provide CI-ready scripts

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

1. **Project Setup** (if new project: template commands and verification steps)
2. **Assumptions**
3. **Design notes** (patterns, key decisions)
4. **Implementation** (code snippets or file diffs as needed)
5. **Tests** (TDD progression or final suite)
6. **How to run & test** (exact commands)
7. **Summary** (what you did + anything the reviewer should double-check)

Keep it crisp and reviewer-friendly.
