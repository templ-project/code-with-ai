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
2. Run `ls .cwai/templates/design` to understand what templates suit better the requirement.
3. Run `.cwai/scripts/create-feature.sh --json [--template game ...] [--label design,story] "$ARGUMENTS"` and parse JSON for BRANCH_NAME, FEATURE_FOLDER, ISSUE_NUMBER, COPIED_TEMPLATES - all path variables are absolute.

4. For each template in COPIED_TEMPLATES, perform the following:

- load the corresponding outline from `.cwai/templates/outline/[template].md`
- load the existing design file at `${FEATURE_FOLDER}/[template].md` if it exists (to understand what was agreed already)
- write the new design to `${FEATURE_FOLDER}/[template].md` with a fresh document using the structure from the outline (GitHub Markdown). Do not append.
<!-- 2. Load the original design template `.cwai/templates/game-design.md` to understand the game design structure.

3. If the requirement is to refactor, load also the existing design file at `${FEATURE_FOLDER}/game-design.md` to fully understand what was agreed already.
4. Write the new design to `${FEATURE_FOLDER}/game-design.md` with a fresh Game Design Document using the structure from the original design template (GitHub Markdown). Do not append.
5. Report completion with branch name, spec file path, and readiness for the next phase. -->
