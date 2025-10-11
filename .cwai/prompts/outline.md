---
description: "Draft or refactor specifications from a natural language feature description"
scripts:
  sh: .cwai/scripts/create-feature.sh
  pwsh: .cwai/scripts/create-feature.ps1
---

Purpose: Your job is to draft or refactor specifications documents from natural language feature descriptions

## Input Definition

Variables available to you:

- `SCRIPT` – [DETECTABLE] Resolved from front‑matter `scripts` map. Use the first executable path (key `sh`) unless otherwise specified.
  - Detect Shell and then read script to familiarize yourself with the arguments (they differ based on shell type Bash+Zsh vs Pwsh)
- `DOCUMENT_TYPE` – [OPTIONAL] User hint: one of `prd|gdd|hld|lld|spec` (case-insensitive) (e.g. `--type hld`).
  - If not mentioned, use heuristic detection on `ARGUMENTS` based on [Heuristics (Inference Aids)] section of this document and your experience
  - If unclear, return: `ERROR: document_type_ambiguous`
- `TEMPLATE` – [DETECTABLE] Value looked up from the [Document Type Mapping] section (column TEMPLATE) based on `DOCUMENT_TYPE`.
- `TASK_TYPE` – [DETECTABLE] Value looked up from the [Document Type Mapping] section (column TASK_TYPE) based on `DOCUMENT_TYPE`.
- `CODE_STACK` – [OPTIONAL] Default: `typescript,node`. Only applied when `DOCUMENT_TYPE=lld` to tailor Low Level Design content (e.g. `--stack c++,xmake`).
- `ARGUMENTS` – [MANDATORY] The raw feature description text supplied after `/outline` (remove the other `--` marked inputs).
  - If missing, return: `ERROR: input_unavailable`

## Execution Flow

**Mandatory actions** → Given the feature description (`ARGUMENTS`), follow these steps **exactly**:

1. Resolve `DOCUMENT_TYPE`.
   - If user explicitly supplied one (flag, keyword, or direct mention), normalize to lowercase and validate against mapping.
   - Otherwise infer via heuristics (see Heuristics section). If multiple match → report `ERROR: document_type_ambiguous` and stop.
   - If no match → default: `DOCUMENT_TYPE=spec`.
   - Derive `TEMPLATE` and `TASK_TYPE` from the mapping row.

2. Invoke scaffold script (do not alter raw `ARGUMENTS`).
   - Command form (POSIX safe):
     - `$SCRIPT --json --template "$TEMPLATE" --labels "$TEMPLATE,$TASK_TYPE" "$ARGUMENTS"`
   - Expect JSON on stdout containing: `BRANCH_NAME`, `FEATURE_FOLDER`, `ISSUE_NUMBER`, `COPIED_TEMPLATES` (absolute paths). If any key missing → `ERROR: script_output_incomplete`.
   - If script exits non-zero or JSON parse fails → `ERROR: script_execution_failed`.

3. Validate template sources.
   - `COPIED_TEMPLATES` should be a non-empty array of absolute file paths under the feature folder.
   - For each copied template path `P`, derive base filename `T = basename(P)` (without extension normalization; expect `.md`).
   - Confirm source canonical template exists at `.cwai/templates/outline/$T` (if missing → `ERROR: template_not_found`).

4. Generate each document.
   - Read canonical template instructions from `.cwai/templates/outline/$T`.
   - Produce a finalized GitHub Markdown document tailored to `ARGUMENTS`, `DOCUMENT_TYPE`, and when `DOCUMENT_TYPE=lld` also incorporate `CODE_STACK` specifics (e.g., code architecture, module boundaries, interfaces in the given stack).
   - Overwrite `${FEATURE_FOLDER}/$T` (no append, UTF-8, ensure trailing newline).
   - MUST remove instructional scaffolding comments unless explicitly required for context.

5. Post-process / cleanup.
   - Remove empty placeholder headings (heading followed immediately by another heading or EOF).
   - Normalize heading levels so there is exactly one H1 at top (document title) unless original template mandates otherwise.
   - Ensure lists use consistent marker (`-`).
   - Collapse >2 consecutive blank lines to a single blank line.

6. Output completion report (structured JSON fenced in Markdown for downstream tooling) containing:
   - `branch`: value of `BRANCH_NAME`
   - `documents`: array of objects `{ file, type, taskType }`
   - `ready`: boolean (true when all steps succeeded)
   - `next_action_hint`: short string (e.g., `review_and_create_pr`)

If any step fails, emit only an error line: `ERROR: <error_code>` and no partial documents.

## Error Codes

- `ERROR: input_unavailable` – Missing or empty `ARGUMENTS`.
- `ERROR: document_type_ambiguous` – Multiple candidate types with equal weight.
- `ERROR: script_execution_failed` – Script failed (non-zero or stderr-critical) or JSON invalid.
- `ERROR: script_output_incomplete` – JSON missing required keys.
- `ERROR: template_not_found` – Canonical template missing.
- `ERROR: generation_failed` – Failed to write or transform a document.

## Output Contract (Success)

```json
{
  "branch": "<BRANCH_NAME>",
  "documents": [{"file": "<FEATURE_FOLDER>/<file>.md", "type": "<DOCUMENT_TYPE>", "taskType": "<TASK_TYPE>"}],
  "ready": true,
  "next_action_hint": "review_and_create_pr"
}
```

Only this JSON (inside a fenced block) plus any human-readable preface is allowed; do not append supplementary analysis after success JSON.

## Acceptance Criteria

- [ ] Script output is a valid JSON
- [ ] Design Document has been generated and filled in
- [ ] Design Document has been cleaned of unnecessary sections

## Document Type Mapping

| DOCUMENT_TYPE | TEMPLATE            | TEMPLATE_PATH                                  | TASK_TYPE |
| ------------- | ------------------- | ---------------------------------------------- | --------- |
| gdd           | game-design         | .cwai/templates/outline/game-design.md         | epic      |
| prd           | product-requirement | .cwai/templates/outline/product-requirement.md | epic      |
| hld           | high-level-design   | .cwai/templates/outline/high-level-design.md   | story     |
| lld           | low-level-design    | .cwai/templates/outline/low-level-design.md    | task      |
| spec          | spec-document       | .cwai/templates/outline/spec-document.md       | story     |

All template file names in `TEMPLATE_PATH` are canonical sources; copies produced by the script will be regenerated/overwritten.

## Heuristics (Inference Aids)

Keyword → DOCUMENT_TYPE (first strong match wins):

- PRD: `kpi`, `business goal`, `user story`, `success metric`, `market`, `persona`
- GDD: `gameplay`, `mechanic`, `level design`, `progression`, `narrative`, `player experience`
- HLD: `architecture`, `component diagram`, `scalability`, `latency`, `throughput`, `system boundary`
- LLD: `class`, `interface`, `function signature`, `module`, `api endpoint`, `schema`, `algorithm`
- SPEC (fallback): anything else / ambiguous

If both HLD and LLD indicators present but no explicit type: prefer `hld` unless majority of sentences contain code-level constructs (>40% with tokens like `class`, `function`, `dto`).

## Additional Notes

- Preserve any code blocks provided in `ARGUMENTS` without altering indentation.
- Do not fabricate metrics; mark unknown data points as `TBD`.
- When `DOCUMENT_TYPE=lld`, include: module breakdown, data structures, error handling strategy, interface contracts, and sequence flows relevant to `CODE_STACK` languages.
- Ensure consistent hyphen usage (standard hyphen-minus `-`).
