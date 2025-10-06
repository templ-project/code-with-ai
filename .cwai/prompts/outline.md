---
description: "Draft or refactor specifications from a natural language feature description"
scripts:
  sh: .cwai/scripts/create-feature.sh
---

## Input Definition

The user input is always available to you as raw text (even if `$ARGUMENTS` appears literally somewhere). If input is missing or invalid→ stop and report: `ERROR: input_unavailable`.

Variables available to you:

- `SCRIPT` - From front-matter `scripts.sh`, representing path to feature scaffolding script
- `ARGUMENTS` - User invocation after `/outline`, representing raw feature description

## Execution Flow

**Mandatory actions** → Given the implementation details provided as an argument, do this and follow all steps **exactly**:

```
1. Read `.cwai/templates/outline` folder content → pick $TEMPLATE(s) (e.g. game-design, high-level-design (hld), low-level-design (lld), product-requirement-document (prd)).
   - Save all that apply.

2. Run `$SCRIPT --json --template $TEMPLATE... --labels $TEMPLATE,story "$ARGUMENTS"` (pass `$ARGUMENTS` **exactly** as given to you, do not summarize)
   - Repeat `--template` for each template.
   - Parse JSON for: `BRANCH_NAME`, `FEATURE_FOLDER`, `ISSUE_NUMBER`, `COPIED_TEMPLATES` (all absolute paths).
   - If this fails → stop and report: `ERROR: script_help_unavailable`.

3. For each template TEMPLATE in `COPIED_TEMPLATES`:
   - Follow the instructions in `.cwai/templates/outline/$TEMPLATE` to produce a proper document.
   - Overwrite `${FEATURE_FOLDER}/$TEMPLATE.md` (GitHub Markdown, no append).

4. Clean the final doc of unnecessary sections (instructions, checklists, etc.) unless specified in the outline.

5. Report completion with:
   - Branch name
   - Spec file path
   - Readiness for the next phase
```
