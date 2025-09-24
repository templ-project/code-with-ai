---
description: "Draft or refactor specifications from a natural language feature description; design document without code implementation - generic stack allowed, i.e. kafka, DB, redis, etc."
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Given the implementation details provided as an argument, do this:

1. Run `.cwai/scripts/create-feature.sh --help` to understand how to call the script
2. Run `ls .cwai/templates` to determine template(s) to use. Save as $TEMPLATE (e.g. game-design, hld, lld, product-requirements, etc). For multiple templates, save them all.
3. Run `.cwai/scripts/create-feature.sh --json [--template $TEMPLATE ...] [--labels $TEMPLATE,story] "$ARGUMENTS"` (repeat the --template argument for each template) and parse JSON for BRANCH_NAME, FEATURE_FOLDER, ISSUE_NUMBER, COPIED_TEMPLATES - all path variables are absolute.

4. For each template in COPIED_TEMPLATES, perform the following:

- load the corresponding outline from `.cwai/templates/$TEMPLATE.md`
- load the existing file at `${FEATURE_FOLDER}/$TEMPLATE.md` if it exists (to understand what was agreed/composed already)
- follow the instructions in the outline to refactor or create a new document based on the user input and existing design (if any) and formulate a new response
- overwrite `${FEATURE_FOLDER}/$TEMPLATE.md` with your new response (GitHub Markdown). Do not append.

5. Report completion with branch name, spec file path, and readiness for the next phase.
