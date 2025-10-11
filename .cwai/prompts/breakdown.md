---
description: Break down the provided design document into a set of epics, stories, tasks, etc
---

## Implementation Decomposition Planning Prompt

Purpose: Given a design/spec document, produce a structured delivery plan broken down into Epics → Stories → Tasks with clear acceptance criteria, traceability to source sections, dependencies, estimates, and release staging. Output must be deterministic, concise, and execution‑ready.

## Input Definition

Variables available to you:

- `DOCUMENT` — [MANDATORY] Path to spec file (e.g., `specs/00001-config-module/high-level-design.md`)
  - If missing, return: `ERROR: missing_document`
- `DOCUMENT_TYPE` — [OPTIONAL] Document type hint: `prd|gdd|hld|lld` (case‑insensitive) (.e.g. `--type hld`)
- `FORMAT` — [OPTIONAL] Output format: `markdown` (default) or `json` (e.g. `--format markdown`)
- `MAX_ITEMS` — [OPTIONAL] Default: 6 — Maximum number of top‑level items (e.g. `--max-items 12`)
- `ARGUMENTS` — [OPTIONAL] Additional flags or hints following the `/breakdown` prompt (e.g. `provide only epics, no other task types`)

## Execution Process

```text
1. Validate Input
   - Confirm `DOCUMENT` path exists and is readable.
   - If missing or invalid, return `ERROR: invalid_document`.

2. Produce Plan
   - Follow `.cwai/templates/plan.md` precisely (terminology, fields, ordering).
   - Select granularity based on `DOCUMENT_TYPE` and content.

3. Generate Output
   - Produce in requested `FORMAT`.
   - File location: same folder as `DOCUMENT`.
   - Filename: `<document-name>.plan.md` or `<document-name>.plan.json`.
   - Apply `$MAX_ITEMS` to top‑level items; if exceeding, pause and request confirmation with a brief justification.

4. Clean Up
   - Remove instructional/placeholder sections not meant for final output.

5. Report Completion (stdout/log)
   - Count of top‑level items
   - List of item IDs with titles (ordered by priority)
```

Return `ERROR: insufficient_signal` if `DOCUMENT` contains fewer than 2 distinct capabilities.
