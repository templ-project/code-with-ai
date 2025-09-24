## Execution Flow (main)

1. Parse HLD and requirements → ERROR if missing.
2. Break system into modules/components.
3. For each module: specify classes, methods, data, interfaces.
4. Add diagrams (class, sequence, state, activity) → WARN if omitted.
5. Define data structures & flows.
6. Specify external/internal interfaces (contracts, formats).
7. Capture algorithms, complexity, error handling, logging.
8. Security, performance, testing details.
9. Validate against assumptions, dependencies, constraints.
10. Run Review Checklist → FAIL if mandatory sections missing or contain only `[NEEDS CLARIFICATION]`.

---

## ⚡ Guidelines

- ✅ Focus on **HOW the system is built internally** (classes, methods, data, flows).
- ❌ Do not drift into requirements/business value (belongs to HLD).
- 📐 Use diagrams where possible.
- 🧩 Every interface & module must have unambiguous contracts.
- 🏷 Mark uncertainties with `[NEEDS CLARIFICATION: …]`.

---

# Low-Level Design (LLD): [SYSTEM / MODULE NAME]

**Design ID**: [LLD-###]  
**Service / Domain**: [Service Name]  
**Owner**: [Name / Role]  
**Contributors**: [Names / Roles]  
**Version**: [vX.Y] • **Date**: [YYYY-MM-DD] • **Status**: Draft  
**Input**: Reference HLD: [link or "[NEEDS CLARIFICATION]"]

## 1. Introduction [MANDATORY]

### 1.1 Purpose

Explain why this LLD exists (ref HLD).

### 1.2 Scope

What part of the system this LLD covers.

### 1.3 Audience

Who should read this (devs, testers, ops).

### 1.4 References

Link to HLD, requirements, standards.

## 2. System Overview [MANDATORY]

### 2.1 System Description

Brief description.

### 2.2 System Context

Where this component/module fits (with diagram if useful).

## 3. Detailed Design [MANDATORY]

### 3.1 Module Descriptions

- **Module Name**
  - Purpose
  - Responsibilities
  - Dependencies

### 3.2 Class Diagrams

[Include UML diagrams + explanation - Use Mermaid.js]

### 3.3 Sequence Diagrams

[Show interactions between classes/modules]

### 3.4 State Diagrams [OPTIONAL]

### 3.5 Activity Diagrams [OPTIONAL]

## 4. Data Design [MANDATORY]

### 4.1 Data Structures

Tables, collections, objects, types.

### 4.2 Database Schema

Tables, keys, constraints.

### 4.3 Data Flow

Detailed flow of information between modules.

## 5. Interface Design [MANDATORY]

### 5.1 User Interfaces

Layouts, inputs, behaviors.

### 5.2 External Interfaces (APIs)

Request/response formats, contracts.

### 5.3 Interface Contracts

Inputs, outputs, pre/post conditions.

## 6. Algorithm Design [MANDATORY]

### 6.1 Algorithms

Pseudocode / flowcharts.

### 6.2 Complexity

Time & space complexity.

## 7. Security Design [MANDATORY]

### 7.1 Measures

Encryption, validation, secure defaults.

### 7.2 Authentication & Authorization

### 7.3 Data Protection

## 8. Error Handling & Logging [MANDATORY]

### 8.1 Error Handling

Strategy, recovery.

### 8.2 Logging

Format, levels, retention.

## 9. Performance Considerations [MANDATORY]

### 9.1 Optimization Techniques

### 9.2 Load Handling & Scaling

## 10. Testing & Validation [MANDATORY]

### 10.1 Unit Testing

### 10.2 Integration Testing

### 10.3 Mapping to HLD Requirements

## 11. Deployment Considerations [OPTIONAL]

### 11.1 Deployment Architecture

### 11.2 Deployment Process

## 12. Assumptions & Dependencies [MANDATORY]

### 12.1 Assumptions

### 12.2 Dependencies

## 13. Appendix [OPTIONAL]

- Glossary
- Acronyms
- Document History

---

## Acceptance Criteria

- ✅ All **mandatory sections** completed.
- ❌ Missing or `[NEEDS CLARIFICATION]` in mandatory sections = **fail review**.
- ⚠ Optional sections may be omitted if not relevant.

---

## Review Checklist

- [ ] LLD aligns with HLD & requirements
- [ ] All modules, data, interfaces detailed
- [ ] Diagrams included where required
- [ ] No implementation-specific configs (LLD ≠ code)
- [ ] Security, error handling, performance covered
- [ ] All mandatory sections filled, no open clarifications

---
