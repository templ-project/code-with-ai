## Execution Flow (main)

1. Parse inputs (business brief, drivers, requirements, current state)
   → If missing: ERROR "Insufficient inputs for HLD"
2. Summarize Context & Drivers
   → Validate objectives are SMART; else WARN and mark [NEEDS CLARIFICATION]
3. Capture Assumptions, Constraints, Dependencies
4. Document Current State (logical, physical, interfaces)
   → If unknown: WARN and mark discovery tasks
5. Propose Target Architecture (logical first, then physical)
   → Include interface impacts; avoid vendor lock-in specifics unless required
6. Define NFRs & Service Continuity (RTO/RPO, failure modes, SPOF, symmetry)
7. Asses Security & Compliance (threats, controls, data flows)
8. Estimate Cost Model (CapEx / OpEx) & Support Model
9. Define Risks & Mitigations; Decommissioning; Roadmap
10. Run Review Checklist
    → If any [NEEDS CLARIFICATION]: WARN "HLD has uncertainties"
    → If low-level build details present: ERROR "Remove implementation detail"
11. Cleanup document of unnecessary sections.
12. Return: SUCCESS (HLD ready for governance / planning)

---

## ⚡ Quick Guidelines

- ✅ HLD = **WHAT the solution looks like** and **WHY these choices**, not step-by-step build.
- ❌ No low-level config, code, or vendor SKUs (leave for LLD/implementation).
- 🧩 Separate **logical** (concepts & flows) from **physical** (tech components).
- 🧪 Every decision should map to drivers, requirements, or constraints.
- 🏷 Use `[NEEDS CLARIFICATION: …]` instead of guessing.

---

# High-Level Design (HLD): [SYSTEM / FEATURE NAME]

**Design ID**: [HLD-###]  
**Service / Domain**: [Service Name]  
**Owner**: [Name / Role]  
**Contributors**: [Names / Roles]  
**Version**: [vX.Y] • **Date**: [YYYY-MM-DD] • **Status**: Draft  
**Input**: Business brief / proposal link: [URL or "[NEEDS CLARIFICATION: missing]"]

## Document History

| Version | Date       | Summary of Change | Reference ID |
| ------: | ---------- | ----------------- | ------------ |
|     1.0 | 2014-07-15 | Initial draft     | -            |

## Design Ownership (RACI-lite)

| Role                                   | Responsibility                        | Named Individual |
| -------------------------------------- | ------------------------------------- | ---------------- |
| Design Owner (Essential)               | Owns HLD content/versioning; handover |                  |
| Project Manager                        | Delivery governance                   |                  |
| Service Owner (Essential)              | Service lifecycle accountability      |                  |
| Service Operations Manager (Essential) | Operational readiness                 |                  |
| Design Mentor (Essential)              | Architecture review                   |                  |
| Business                               | Requirements integrity                |                  |
| Applications & Data                    | App/data architecture                 |                  |
| Technology                             | Platform standards alignment          |                  |

## 1 Context

### 1.1 Summary (for non-technical stakeholders)

- Service/system name: [ ]
- Change type: [New / Change / Upgrade]
- Business areas affected: [ ]
- Why now (driver): [ ]
- Expected outcomes: [ ]
- Very high-level “how”: [ ]
- Criticality / categorisation: [Low/Med/High or [NEEDS CLARIFICATION]]

### 1.2 Links to Documentation

- Business case / PID: [ ]
- Prior designs / related docs: [ ]
- Requirements doc: [ ]

## 2 Drivers, Requirements, Objectives

### 2.1 Drivers

- [ ]

### 2.2 Requirements (Functional & Non-Functional)

- Reference / link: [ ]
- Gaps: [NEEDS CLARIFICATION: …]

### 2.3 Objectives (SMART)

| ID     | Objective | Success Criteria |
| ------ | --------- | ---------------- |
| OBJ-01 |           |                  |

### 2.4 Impact of No Action

- [Business/operational risk if unchanged]

## 3 Assumptions, Constraints, Dependencies

### 3.1 Assumptions

| Assumption                | Impact on Design |
| ------------------------- | ---------------- |
| Org growth 10% YoY        |                  |
| ISD shrinks 1% real terms |                  |
| Split DC model (~30km)    |                  |
| Additional                |                  |

### 3.2 Constraints

- Funding: [ ]
- Skills / resources: [ ]
- Existing tech lock-in: [ ]
- Timescales: [ ]
- Customer process rigidity: [ ]
- Pre-purchased items: [ ]

### 3.3 Dependencies

- Other departments: [ ]
- Suppliers: [ ]
- Internal groups / other projects: [ ]
- Those dependent on this design: [ ]

## 4 Current State

### 4.1 Logical / Architectural Summary

- Key components, actors, data, flows.

### 4.2 Logical Diagrams

- DFD / ERD / Use cases.
- Internal interfaces: [ ]

### 4.3 Physical Technology Summary

- Hardware / software / platforms in scope.

### 4.4 Physical Diagrams

- Network / compute / storage / app topology.

### 4.5 External Interfaces

- Systems: [AD, DNS, Email, Monitoring, myFinance, myView, ETLs, Storage]
- Known change impacts: [ ]

### 4.6 Current Limitations

| ID     | Limitation | Impact |
| ------ | ---------- | ------ |
| LIM-01 |            |        |

## 5 Target Architecture

### 5.1 Options Considered (Brief)

- Alternatives & rationale for selection.

### 5.2 Logical Target Design

- Changes from current: [ ]
- Known logical limitations (1-year / 5-year): [ ]
- Residual risks/limitations: [ ]

### 5.3 Physical Solution Summary

- Platforms, hosting model, data stores, major products (generic—no SKUs).
- Reference designs cited: [Suppliers/SMEs]

### 5.4 Physical Diagrams

- Network / server / storage / app / data.

### 5.5 Interfaces (Target)

| Interface | Change Summary | Effort | Owner |
| --------- | -------------- | ------ | ----- |
|           |                |        |       |

## 6 Service Continuity & NFRs

### 6.1 Criticality & SLOs

- Criticality: [ ]
- Availability target: [ ]
- RTO: [ ] • RPO: [ ]
- Performance / scale targets: [NEEDS CLARIFICATION if missing]

### 6.2 Backup & Recovery

- Scope, frequency, retention, recovery procedures, BCP link.

### 6.3 Failure Modes & Response

| Failure Mode                    | Required Function | High-Level Process |
| ------------------------------- | ----------------- | ------------------ |
| Loss of single site (planned)   |                   |                    |
| Loss of single site (unplanned) |                   |                    |
| Data loss (partial/complete)    |                   |                    |
| During component updates        |                   |                    |

### 6.4 Single Points of Failure

- [ ]

### 6.5 Symmetry (Primary vs Secondary)

- [ ]

## 7 Security & Compliance

- Data classification, flows, and boundaries
- Threats & controls (authn/z, logging, monitoring)
- Regulatory/standards: [ ]
- Open issues: [NEEDS CLARIFICATION]

## 8 Update Methodology

For major elements: frequency, type, responsibility, expected cost.

## 9 Benefits (High Level)

- [Business, operational, risk reduction]

## 10 Risks & Mitigations (Residual)

| Risk | Type | Summary | Mitigation |
| ---- | ---- | ------- | ---------- |
|      |      |         |            |

## 11 Cost Model (High Level, excl. project costs)

### 11.1 CapEx

- Servers, upfront licenses, network, facilities.

### 11.2 CapEx-Generated OpEx

- Support, maintenance, per-seat/size uplifts, HW maintenance, annual health checks.

### 11.3 OpEx

- Hosting, backup, comms & networks.

## 12 Support & Operations

### 12.1 Service Governance

- Service Owner, Service Operations Manager, Business Owner.

### 12.2 Operational Support

| Element | Capabilities Required | Anticipated Load | Current Capacity | Training/Resourcing Needed |
| ------- | --------------------- | ---------------- | ---------------- | -------------------------- |
|         |                       |                  |                  |                            |

## 13 Decommissioning Targets

- Services / Infrastructure to retire; timing from delivery.
  | Element | Replaced By | Decommission Type | Timescale |
  |---------|-------------|-------------------|----------|
  | | | | |

## 14 Block Scheduling & Lifecycle

- Major blocks, lifecycle stages, decision gates; where outputs go (CAB, etc.).

## 15 Potential Future Improvements

- Near-term and strategic enhancements.

---

## Review & Acceptance Checklist (Gate)

### Content Quality

- [ ] No low-level implementation details
- [ ] Logical and physical separated & justified
- [ ] Stakeholder-readable; links provided
- [ ] Objectives SMART and mapped to drivers

### Completeness

- [ ] Assumptions/constraints/dependencies explicit
- [ ] Current state and target defined with diagrams
- [ ] NFRs & continuity (RTO/RPO) set
- [ ] Interfaces and impacts captured
- [ ] Security & compliance addressed
- [ ] Costs & support model outlined
- [ ] Decommissioning and risks listed
- [ ] No [NEEDS CLARIFICATION] remain

---

## Execution Status (auto-updated by main())

- [ ] Inputs parsed
- [ ] Context & drivers summarized
- [ ] Assumptions/constraints/dependencies captured
- [ ] Current state documented
- [ ] Target architecture defined (logical/physical)
- [ ] NFRs & continuity set
- [ ] Security & compliance covered
- [ ] Costs & support defined
- [ ] Risks & decommissioning set
- [ ] Review checklist passed
