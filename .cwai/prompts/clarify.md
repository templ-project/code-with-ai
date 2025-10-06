---
description: "Analyze an existing design spec (PRD / HLD / LLD / GDD) and produce structured clarifying questions & completion guidance"
---

Purpose: Given one or more already generated design documents (Product Requirement Document, High-Level Design, Low-Level Design, Game Design Document), analyze gaps, ambiguities, structural defects, and readiness for its downstream phase. Output ONLY questions and actionable recommendations—never fabricate answers.

## Input Definition

The user input is always available to you as raw text (even if `$ARGUMENTS` appears literally somewhere). If input is missing or invalid→ stop and report: `ERROR: input_unavailable`.

Variables available to you:

- `DOCUMENT` - [MANDATORY] Path to a single spec file under `specs/xxxxx-yyyyy/document.md` (e.g. `specs/00001-generic-multi-purpose-config-module/high-level-design.md`)
- `DOCUMENT_TYPE` - [OPTIONAL] Type of document provided for easier evaluation (e.g. `--type hld specs/00001-generic-multi-purpose-config-module/high-level-design.md`)
- `CLARIFY_FOCUS` - [OPTIONAL] Limits question domains (e.g. `--focus security,performance`)
- `CLARIFY_ITEMS` - [OPTIONAL] Limits the number of questions to be asked (.e.g `--max-items 5`) - default value: 5
- `ARGUMENTS` - [OPTIONAL] everything else that follows the `/clarify` prompt

## Supported Doc Type Heuristics

| Type | Required Identifier (any match)                   | Primary Template File                                     |
| ---- | ------------------------------------------------- | --------------------------------------------------------- |
| PRD  | `Product Requirements Document` / `PRD ID`        | `.cwai/templates/outline/product-requirement-document.md` |
| HLD  | `High-Level Design (HLD)` / `Target Architecture` | `.cwai/templates/outline/high-level-design.md`            |
| LLD  | `Low-Level Design (LLD)` / `Module Descriptions`  | `.cwai/templates/outline/low-level-design.md`             |
| GDD  | `Game Design Document (GDD)` / `Core Loop`        | `.cwai/templates/outline/game-design.md`                  |

If ambiguous (multiple heuristics) → determine a best fit for the document and act accordingly; analyze based on the $ARGUMENTS requirement.

## Execution Flow (MANDATORY)

```
1. Load $DOCUMENT, read the `issue.json` file present in the same folder as the $DOCUMENT and
  a. Detect type from $DOCUMENT_TYPE or (heuristics) $ARGUMENTS - can be other type than the ones mentioned above.
  b. If exists, load the corresponding template (from `.cwai/templates/...`) in memory (do NOT output it).
  c. Build Mandatory Section Inventory from template (section headings marked [MANDATORY] or table rows explicitly flagged Yes).
  d. Analyze document, parse for `[NEEDS CLARIFICATION]` tags
  e. Analyze document, understand it based on the `issue.json` requirements
  f. Analyze document, compare it with the original template.
  g. Prepare a list of unknowns; limit it to $CLARIFY_ITEMS most important ones

2. Consolidate document based on questions asked to user (use the list of unknowns) and answers received by user

3. Reformulate $DOCUMENT to include the clarifications and increase $DOCUMENT's version (overwrite or inline edit)
```

## Clarification Question Domains

Use only domains that apply (omit empty):
`requirements`, `scope`, `objectives`, `assumptions`, `constraints`, `dependencies`, `architecture-logical`, `architecture-physical`, `interfaces`, `data`, `algorithms`, `security`, `performance`, `reliability`, `continuity`, `costs`, `operations`, `risks`, `testing`, `compliance`, `gameplay`, `progression`, `mechanics`, `accessibility`, `metrics`, `diagrams`, `other`.

## Question Structure

Each question MUST:

```text
ID: Q-### (sequential, per document)
Domain: one of allowed domains
Severity: BLOCKER|HIGH|MEDIUM|LOW
Context: 1–2 line cite (quote or paraphrase fragment) OR `section-missing`
Question: Direct, specific, singular
Required Data Form: e.g. "Provide numeric target (p95 latency in ms)" / "List interface fields (name:type:direction)" / "Decision rationale (chosen vs alternatives)"
```

Never bundle multiple unknowns in one question. Avoid yes/no phrasing unless validating an assumption.
