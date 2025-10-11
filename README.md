# Code with AI (CwAI)

```text
   _____                _____
  / ____|           _  |_   _|
 | |     __      _ / \   | |
 | |     \ \ /\ / / / \  | |
 | |____  \ V  V / ____\_| |_
  \_____|  \_/\_/_/    \_____/

            C w A I
          Code with AI
```

Design → Clarify → Plan → Implement (in small, honest, inspectable steps)

> This project is intentionally a work-in-progress. I’m designing the framework _while_ using it, and keeping the rough edges visible instead of hiding them.

---

## Why This Exists

Most “AI assisted dev” flows jump straight from a fuzzy sentence to code. That feels fast—until the third rework sprint. CwAI tries to slow you **just enough** to:

1. Write down intent before syntax
2. Expose ambiguity early (on purpose, with `[NEEDS CLARIFICATION: …]`)
3. Plan thin vertical slices you can actually deliver
4. Let implementation prompts lean on real artifacts instead of vapor

The goal is not bureaucracy. It’s: reduce cognitive load, increase shared context, and make large changes feel safe.

### Influences & Acknowledgements

Big inspiration came from people exploring “spec first” + “Markdown as a programming language” ideas:

- GitHub Spec Kit: <https://github.com/github/spec-kit>
- CaptainCrouton89's Claude prompt repo: <https://github.com/CaptainCrouton89/.claude>
- Spec‑driven development blog (GitHub): <https://github.blog/ai-and-ml/generative-ai/spec-driven-development-using-markdown-as-a-programming-language-when-building-with-ai/>
- Broader thinking around structured prompting & iterative refinement (various articles—some behind consent walls)

If you maintain one of those projects and want clearer attribution, reach out or open an issue.

### What This Is (and Isn’t)

| Is                            | Isn’t                                    |
| ----------------------------- | ---------------------------------------- |
| Opinionated workflow skeleton | A locked-down framework                  |
| Design + planning scaffolding | A replacement for architectural judgment |
| Prompts you can fork & remix  | Magic “build my SaaS” button             |
| Learning-in-public experiment | Guaranteed best practice                 |

### Current Status

Alpha. Expect:

- Gaps (e.g. `/implement` prompt still intentionally blank)
- Occasional naming shifts
- Evolving templates (PRD/HLD/LLD/GDD may tighten)
- Missing automation (diagram helpers, test harness generation, etc.)

### Important Disclaimer

> [!WARNING]
> **AI Behavior Variability:** We make no guarantees that these prompts will behave with 100% accuracy or consistency. AI models are inherently non-deterministic and unpredictable. The same prompt executed twice may produce different results, vary between AI providers (Copilot, Claude, Gemini), or change behavior across model versions. This variability is a fundamental characteristic of large language models, not a flaw in the prompts themselves.
>
> Use these prompts as **guidance and scaffolding**, not as deterministic tools. Always review, validate, and adjust AI output to fit your specific context and requirements.

### Table of Contents (because this grew fast)

- [Code with AI (CwAI)](#code-with-ai-cwai)
  - [Why This Exists](#why-this-exists)
    - [Influences \& Acknowledgements](#influences--acknowledgements)
    - [What This Is (and Isn’t)](#what-this-is-and-isnt)
    - [Current Status](#current-status)
    - [Important Disclaimer](#important-disclaimer)
    - [Table of Contents (because this grew fast)](#table-of-contents-because-this-grew-fast)
  - [Quick Start](#quick-start)
  - [Installation Details](#installation-details)
    - [Installation Scripts](#installation-scripts)
      - [macOS/Linux Installation](#macoslinux-installation)
      - [Windows/PowerShell Installation](#windowspowershell-installation)
    - [Requirements](#requirements)
      - [For Bash (macOS/Linux)](#for-bash-macoslinux)
      - [For PowerShell (Windows/Cross-platform)](#for-powershell-windowscross-platform)
  - [Configuration](#configuration)
  - [Core Workflow Overview](#core-workflow-overview)
  - [`/outline` – From Requirement Sentence to Structured Specs](#outline--from-requirement-sentence-to-structured-specs)
  - [`/clarify` – Eliminate Ambiguity](#clarify--eliminate-ambiguity)
  - [`/breakdown` – Convert Design to Delivery Plan](#breakdown--convert-design-to-delivery-plan)
  - [`/implement` – Guided Coding](#implement--guided-coding)
  - [Feature Folder Anatomy](#feature-folder-anatomy)
  - [Local vs GitHub Issue Manager](#local-vs-github-issue-manager)
  - [Conventions \& Guardrails](#conventions--guardrails)
  - [Development Aids](#development-aids)
    - [Cross-Platform Script Support](#cross-platform-script-support)
    - [Linting and Formatting](#linting-and-formatting)
  - [Typical End-to-End Session](#typical-end-to-end-session)
  - [Roadmap Ideas](#roadmap-ideas)
  - [Troubleshooting](#troubleshooting)
  - [License](#license)
  - [Contributing](#contributing)
  - [Philosophy in Practice](#philosophy-in-practice)
  - [FAQ (Tiny \& Growing)](#faq-tiny--growing)

---

An opinionated, prompt‑driven workflow to move a feature or product idea from a raw sentence to something you can actually ship—without pretending ambiguity doesn’t exist.

1. Structured design documents (PRD / HLD / LLD / GDD)
2. Clarified, ambiguity‑reduced specs
3. Executable delivery plan (Epics → Stories → Tasks)
4. Guided implementation phase

All via four tiny “verbs” you teach your AI assistant: `/outline`, `/clarify`, `/breakdown`, `/implement`.

The project ships:

- Reusable prompt definitions in `.cwai/prompts/`
- Authoritative document templates in `.cwai/templates/outline/` and planning template `plan.md`
- Feature scaffolding scripts:
  - **Bash**: `.cwai/scripts/create-feature.sh` with utilities in `common.sh`
  - **PowerShell**: `.cwai/scripts/create-feature.ps1` with utilities in `common.ps1`
  - **Documentation**: Plain English guides in `common.md` and `create-feature.md`
- Local issue/spec storage (filesystem) with optional GitHub syncing

---

## Quick Start

```bash
git clone <repo-url>
cd code-with-ai
./install.sh   # interactive; choose AI client + local/global install
```

After install, your chosen AI tool (Copilot / Claude / Gemini) will have access to the prompts (`/outline`, `/clarify`, `/breakdown`, `/implement`).

---

## Installation Details

### Installation Scripts

The project provides installation scripts for multiple platforms:

- **`install.sh`** - Bash script for macOS, Linux, and Unix-like systems
- **`install.ps1`** - PowerShell script for Windows (also compatible with PowerShell Core on macOS/Linux)

Both scripts provide the same interactive installation experience:

1. Ask for target AI client: VSCode Copilot | Claude | Gemini
2. Ask Local vs Global (if supported)
3. Determine the correct target path
4. Detect any existing installation and let you choose:
   - (1) Copy Over Existing
   - (2) Remove and Reinstall
5. Copy `.cwai/` plus client‑specific prompt files:
   - Copilot → `.github/prompts/*.prompt.md`
   - Claude → `~/.config/claude/prompts/*.md` (or chosen path)
   - Gemini → `~/.config/gemini/templates/*.md`

#### macOS/Linux Installation

```bash
./install.sh
```

#### Windows/PowerShell Installation

```powershell
.\install.ps1
```

### Requirements

#### For Bash (macOS/Linux)

- Bash 4+
- `git`, `jq`, `find`, `cp`, `mkdir`, `rm`
- Optional (GitHub integration): `gh` CLI authenticated

#### For PowerShell (Windows/Cross-platform)

- PowerShell 5.1+ (Windows) or PowerShell Core 6+ (cross-platform)
- Git
- Optional (GitHub integration): `gh` CLI authenticated

If you prefer manual install: just copy the entire `.cwai` folder into any repo and wire the prompts into your AI client (Copilot custom prompts, Claude custom library, etc.).

---

## Configuration

Environment variables (can be placed in `.env` or `.env.local` in repo root):

| Variable             | Default   | Purpose                                             |
| -------------------- | --------- | --------------------------------------------------- |
| `CWAI_SPECS_FOLDER`  | `specs`   | Root folder where feature spec folders are created  |
| `CWAI_ISSUE_MANAGER` | `localfs` | `localfs` (filesystem only) or `github` (uses `gh`) |

When using `github` issue manager the script mirrors issues locally under the specs folder (creates `issue.json`).

---

## Core Workflow Overview

| Phase                  | Command      | Output Artifacts                                                                      | Objective                                                   |
| ---------------------- | ------------ | ------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Ideation / Scaffolding | `/outline`   | `specs/<id>-<slug>/high-level-design.md` (or other selected templates) + `issue.json` | Create initial structured design docs & branch              |
| Clarification          | `/clarify`   | Updated in‑place doc (version bumped)                                                 | Remove ambiguity; add precise questions & integrate answers |
| Planning               | `/breakdown` | `<document>.plan.md` (or `.plan.json`)                                                | Delivery plan with Epics → Stories → Tasks                  |
| Implementation         | `/implement` | Code, updates, follow‑up tasks                                                        | Guided development aligned with plan                        |

> Each stage depends on the previous one being “clean” (no unresolved `[NEEDS CLARIFICATION]` tags where mandatory).

---

## `/outline` – From Requirement Sentence to Structured Specs

Use when: You have an unstructured feature thought (“Add MFA to login”) and want a shaped, inspectable starting spec _before_ you start breaking things.

Prompt does (enforced by `outline.md`):

1. Inspects `.cwai/templates/outline/` and selects relevant templates (PRD, high-level-design, low-level-design, game-design etc.).
2. Runs the feature scaffolding script: `.cwai/scripts/create-feature.sh` with all chosen templates.
3. Creates:
   - New branch: `00001-sanitized-feature-slug`
   - Feature folder: `specs/00001-sanitized-feature-slug/`
   - `issue.json` metadata file
   - Copies template markdown files
4. Rewrites copied templates: replacing instructional boilerplate with concrete, user‑provided content where possible while retaining `[NEEDS CLARIFICATION]` markers instead of guessing.

Usage examples (in AI chat):

```text
/outline Add multi-factor authentication to user login --template high-level-design --template product-requirement-document --labels security,authentication

/outline Implement configuration service to centralize feature flags --template high-level-design --labels platform --json
```

Outputs a JSON summary containing at least: `BRANCH_NAME`, `FEATURE_FOLDER`, `COPIED_TEMPLATES`.

Follow‑on: skim the generated doc. Resist the urge to delete `[NEEDS CLARIFICATION]` until you genuinely know the answer.

---

## `/clarify` – Eliminate Ambiguity

Use when: A design doc _exists_ but you feel that uneasy “We’re still guessing in three places” sensation.

Arguments (in free text following the command):

- `--type <prd|hld|lld|gdd>` (optional hint)
- `--focus security,performance` limit domains of questions
- `--max-items 8` change number of clarification questions (default 5)
- Path to document: mandatory first non‑flag argument `specs/<id>-<slug>/<doc>.md`

Behavior summary (you don’t have to trust it—open the prompt file to see the guardrails):

1. Loads doc + sibling `issue.json`
2. Derives doc type (heuristics if not provided)
3. Compares against authoritative template; inventories mandatory sections
4. Generates structured clarification questions: ID, Domain, Severity, Context, Question, Required Data Form
5. You answer the questions (can be iterative). Prompt then integrates answers directly, removes resolved `[NEEDS CLARIFICATION]`, increments version.

Example:

```text
/clarify --type hld --focus security,performance --max-items 6 specs/00001-config-service/high-level-design.md
```

You reply with answers (one pass or iterative). The assistant patches the doc, bumps version, and removes only what’s truly resolved.

Exit conditions:

- If document missing → `ERROR: input_unavailable` or `ERROR: invalid_document`
- If still unresolved critical blockers remain you should run `/clarify` again until clean.

---

## `/breakdown` – Convert Design to Delivery Plan

Use when: The design feels _boringly unambiguous_ and you’re itching to build.

Key flags:

- `--type hld` (optional type hint)
- `--format markdown|json` (default markdown)
- `--max-items 10` (limit top-level items; default 6)

Result file placed beside source document: `high-level-design.plan.md` (or `.json`).

Output contents (per `plan.md`): Epics (or Stories/Tasks depending on granularity rules) with: Value | Effort | Risk | Priority | Release | Dependencies | Acceptance Criteria + traceability to source section.

Example:

```text
/breakdown specs/00001-config-service/high-level-design.md --type hld --max-items 8 --format markdown
```

Errors (by design—silence would be worse):

- Too little signal (<2 capabilities) → `ERROR: insufficient_signal`
- Missing path → `ERROR: invalid_document`

---

## `/implement` – Guided Coding

Use when: You’ve picked the next slice and want the AI to act like a careful pair, not a code firehose.

The `/implement` prompt is defined in `.cwai/prompts/implement.md` and guides stack rules, contracts, tests, and validation. Ideas for its responsibilities:

- Accept one or more item IDs
- Pull corresponding acceptance criteria & context from plan + originating spec
- Propose minimal file changes grouped by commit
- Ask for confirmation before destructive edits
- Generate/update tests
- Track remaining tasks / create follow-up clarifications if new unknowns emerge

Suggested invocation:

```text
/implement Implement Story S-001-01 from specs/00001-config-service/high-level-design.plan.md focusing on API layer first
```

---

## Feature Folder Anatomy

After `/outline` (and sometimes a follow-up `/clarify`) you will typically see:

```text
specs/
    00001-config-service/
        issue.json                  # Local issue metadata & history
        high-level-design.md        # Or chosen templates
        product-requirement-document.md
        low-level-design.md         # (If selected)
        game-design.md              # (If selected for game features)
        high-level-design.plan.md   # After /breakdown
```

`issue.json` tracks: id, title, description, labels, comments, timestamps.

---

## Local vs GitHub Issue Manager

Set `CWAI_ISSUE_MANAGER=github` to also create a real GitHub issue (mirrored locally). Great for bringing non‑AI teammates along.

Label semantics (you can extend): `task`, `auto-generated`, plus any you pass via `--labels`.

Removing labels: prefix with `-` (e.g., `--labels -development`).

---

## Conventions & Guardrails

Core promises to yourself:

- Don’t invent—write the uncertainty _down_.
- HLD = architectural intent & justification. No vendor SKU shopping.
- LLD = internal structure & contracts. Still not code dumps.
- Planning IDs are sticky; avoid renumber churn (it kills traceability).
- Acceptance criteria are user/system observable. Not “refactor X util”.
- Diagrams help offload working memory. Use Mermaid when possible.

---

## Development Aids

### Cross-Platform Script Support

All core scripts are available in both Bash and PowerShell:

| Script           | Bash                              | PowerShell                         | Documentation                     |
| ---------------- | --------------------------------- | ---------------------------------- | --------------------------------- |
| Installation     | `install.sh`                      | `install.ps1`                      | `src/install.md`                  |
| Create Feature   | `.cwai/scripts/create-feature.sh` | `.cwai/scripts/create-feature.ps1` | `.cwai/scripts/create-feature.md` |
| Common Utilities | `.cwai/scripts/common.sh`         | `.cwai/scripts/common.ps1`         | `.cwai/scripts/common.md`         |

Both implementations maintain identical functionality and output formats.

### Linting and Formatting

Run linters (Bash + Markdown formatting):

```bash
task lint          # Requires Taskfile & dependencies (shellcheck, prettier, eslint md plugin)
```

Pre-commit tooling (husky + lint-staged) can be configured to enforce formatting.

---

## Typical End-to-End Session

```text
/outline Add config service for feature flag management --template high-level-design --labels platform,infra
→ Review generated high-level-design.md (leave genuine uncertainties)

/clarify specs/00001-config-service/high-level-design.md --focus security,performance
→ Provide answers, receive updated doc without unresolved blockers

/breakdown specs/00001-config-service/high-level-design.md --max-items 8
→ Get high-level-design.plan.md with Epics/Stories/Tasks

/implement Implement Story S-001-01 (Fetch config by key) using FastAPI; propose file structure first
→ Iterate until tests & acceptance criteria satisfied
```

---

## Roadmap Ideas

- Populate `/implement` prompt with structured execution guidance
- Add test generation & coverage tracking integration
- Multi-repo / monorepo workspace strategy prompt
- Automatic dependency diagram extraction
- Optional semantic versioning & changelog integration

---

## Troubleshooting

| Symptom                              | Cause                                          | Fix                                                              |
| ------------------------------------ | ---------------------------------------------- | ---------------------------------------------------------------- |
| `ERROR: Bash 4 or later is required` | Using macOS default `/bin/bash` 3.x            | Install modern bash (e.g. via Homebrew) & re-run with `env bash` |
| No prompts appear in Copilot         | Install not run in correct project             | Re-run `./install.sh` locally with Copilot selected              |
| `/clarify` returns no questions      | Document already complete or wrong path passed | Verify path and presence of mandatory placeholders               |
| Plan omits items                     | `--max-items` triggered truncation             | Re-run with higher `--max-items` or another `/breakdown` pass    |

---

## License

MIT (or specify) – update if needed.

---

## Contributing

1. Fork / create feature branch using `/outline`
2. Make changes & ensure lint passes
3. PR referencing generated issue / spec folder
4. Keep prompts minimal, deterministic

---

Feel free to adapt the templates or extend prompts for your domain (data engineering, ML, platform infra, gameplay, etc.).

---

## Philosophy in Practice

The loop intentionally enforces _progressive elaboration_:

Idea → (outline) → (clarify) → (plan) → (implement) → (discover) → (clarify again) …

It’s fine—even healthy—to re-enter `/clarify` mid‑implementation when reality bites. The guardrails exist to make that a _cheap_ move instead of a political one.

## FAQ (Tiny & Growing)

**Q: Why so much Markdown?**
Because it diff‑reviews well, survives refactors, and doubles as shared memory between humans and AI.

**Q: Can I skip straight to `/breakdown`?**
You _can_. You’ll probably regret it on anything non‑trivial.

**Q: Where are the tests for the prompts?**
Planned: prompt regression harness + golden output snapshots.

**Q: Isn’t this waterfall-y?**
Not if you treat stages as revisit-able checkpoints, not gates.

---

If any of this resonates—or annoys you productively—open an issue with a concrete example. That feedback loop is the whole point.

Happy prompt‑driven building! 🚀
