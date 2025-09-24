# Raw Design Template

> Purpose: A neutral, client-facing initial idea/specification capture. This document may begin incomplete or ambiguous. It should capture intent (WHAT & WHY) — not implementation (HOW). Leave placeholders for unknowns rather than guessing.

---

## 1. Context & Background _(optional)_

[Business situation, narrative, origin, triggering event]

## 2. Problem / Opportunity Statement

[Single clear paragraph: What problem exists? For whom? Why now?]

## 3. Objectives & Success Metrics

- Objective 1: [Outcome phrased, not solution]
- Objective 2: ...

Success Metrics (qualitative or early directional):

- Metric: [Description / target if known]

## 4. Stakeholders & Primary Users _(clarify roles not job titles)_

- Primary User(s): [Who directly benefits]
- Secondary Users: [...]
- Stakeholders: [Reviewers / sponsors]

## 5. Scope

### In Scope

- [Items clearly included]

### Out of Scope

- [Items explicitly excluded to prevent scope creep]

## 6. Assumptions

- [Assumed truth pending validation]

## 7. Constraints

- [Regulatory / temporal / budgetary / operational / domain constraints]

## 8. Requirements

Separate into functional (WHAT behavior) and non-functional (qualities/performance). Do NOT include implementation details.

### Functional (FR1, FR2, ...)

- FR1: [Concise requirement]
- FR2: ...

### Non-Functional (NFR1, NFR2, ...) _(optional)_

- NFR1: [Performance / availability / accessibility / compliance]

## 9. User Stories

Use format: `As a <user type>, I can <goal> so that <benefit>.`

- Story 1: ... (FR1, FR2)
- Story 2: ...

## 10. Acceptance Criteria

Testable, binary validation statements. Reference FR / Story IDs.

- AC1: WHEN [CONDITION] THEN [OBSERVABLE RESULT] (FR1)
- AC2: ...

## 11. Flows / Scenarios _(optional)_

High-level narrative or bullet flows (no technical sequence):

1. [Start → Action → Outcome]

## 12. Domain Concepts / Entities _(optional)_

| Concept | Definition | Relationships / Notes |
| ------- | ---------- | --------------------- |
|         |            |                       |

## 13. Edge Cases & Failure Modes

- Case: [Description] → Expected Handling (FRx)

## 14. Risks & Mitigations _(optional)_

| Risk | Impact | Likelihood | Mitigation / Next Step |
| ---- | ------ | ---------- | ---------------------- |
|      |        |            |                        |

## 15. Open Questions

? [Unknown requiring clarification]
? [...]

## 16. Glossary _(optional)_

- Term: Definition

## 17. Attachments / References _(optional)_

- [Link or reference id]

## 18. Notes

[Additional notes, clarifications, rationale that do not fit other sections]

---

### Authoring Guidelines

- Avoid: solutioning, technology names, code, library/framework/tool choices.
- Use: clear, verifiable, stakeholder-readable language.
- Prefer unknowns listed in Open Questions over speculation.
- Requirements must be testable; combine or split to remove ambiguity.

### Completion Signals (for next-phase readiness)

- Core problem & objectives articulated
- Functional requirements numbered & traceable to user stories
- Acceptance criteria exist for each critical requirement
- Open Questions acknowledged (can be non-empty)

### Revision History _(optional)_

| Version | Date       | Author | Summary       |
| ------- | ---------- | ------ | ------------- |
| 0.1     | YYYY-MM-DD | name   | Initial draft |
