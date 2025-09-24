---
description: "Draft (or refactor) a pure design document (concept → rules → player experience) without implementation."
scripts:
  sh: .cwai/scripts/create-feature.sh --json
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Given the implementation details provided as an argument, do this:

1. Run `.cwai/scripts/create-feature.sh --help` to understand how to call the script
2. Run `ls .cwai/templates` to understand what templates suit better the requirement.
3. Run `.cwai/scripts/create-feature.sh --json [--template game ...] [--labels $template$,story] "$ARGUMENTS"` and parse JSON for BRANCH_NAME, FEATURE_FOLDER, ISSUE_NUMBER, COPIED_TEMPLATES - all path variables are absolute.

4. For each template in COPIED_TEMPLATES, perform the following:

- load the corresponding outline from `.cwai/templates/$template.md`
- load the existing file at `${FEATURE_FOLDER}/$template.md` if it exists (to understand what was agreed/composed already)
- follow the instructions in the outline to refactor or create a new document based on the user input and existing design (if any) and formulate a new response
- overwrite `${FEATURE_FOLDER}/$template.md` with your new response (GitHub Markdown). Do not append.

5. Report completion with branch name, spec file path, and readiness for the next phase.
