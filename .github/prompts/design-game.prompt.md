---
name: design-game
description: "Start a new feature by creating a specification and feature branch. This is the first step in the Spec-Driven Development lifecycle."
---

If feature is not mentioned, start a new feature by creating a specification and feature branch.

This is the first step in the Spec-Driven Development lifecycle.

Given the feature description provided as an argument, do this:

1. Create a 5 word max title summarizing the feature.
2. Run the script `.specify/scripts/create-new-feature.sh --json --title "$TITLE" --requirement "$ARGUMENTS" --raw` from repo root and parse its JSON output for BRANCH_NAME and SPEC_FILE. All file paths must be absolute.
2. Load `.cwai/templates/templates/raw-design.md` to understand required sections.
3. Write the specification to `${FEATURE_FOLDER}/raw-design.md` using the template structure, replacing placeholders with concrete details derived from the feature description (arguments) while preserving section order and headings.
4. Report completion with branch name, spec file path, and readiness for the next phase.

Note: The script creates and checks out the new branch and initializes the spec file before writing.

---

Use concise language, avoid repetition, and ensure clarity.
Use Github Markdown format for the specification file.
Use MermaidJs for diagrams.

---
