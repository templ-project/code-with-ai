# Language/Stack Rules for AI Code Generation

Use this file as the canonical ruleset. Follow Global Rules first, then apply the selected Language Rules. Prefer clarity over cleverness and keep outputs runnable, testable, and secure.

## Global Rules

- Style: [Google Style Guide](https://google.github.io/styleguide/) or best applicable rules by programming language.
- Code quality: prioritize readability, small functions, single responsibility.
- Errors: return explicit errors; avoid silent failures; include context in messages; make use of error codes.
- Security: never hardcode secrets; prefer env vars or secret managers; redact in logs.
- Testing: include minimal unit tests for new public behavior when feasible.
- Docs: include a short README or usage notes when creating new runnable code.
- Tooling: adopt ecosystem-standard formatters/linters (e.g., Prettier, Black, gofmt).
- CI/CD: default to deterministic builds; pin dependencies where practical.
- Ports/paths: make configurable via env vars with safe defaults.
- Licensing: do not include copyrighted snippets; generate original code.
- Modules: accepted licenses are MIT and Apache like; anything restricting to make code public is forbidden
- Instrumentation: Even when Stack has its proprietary instrumentation, make use of [Taskfile](https://github.com/go-task/task) to write complex tasks that will permit developer to automate things
- Process: Follow the 8-step Developer Methodology in `../prompts/implement.md` (Setup → Requirements → Design → Implementation → Testing → Documentation → Validation).

---

## Bash

- Runtime: Bash 4 and Above
- Style: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).
- Guide: Shell style (internal) and Google Shell Style where applicable.
- Tooling: `shellcheck` and `shfmt`.
- Shebang/strict mode: `#!/usr/bin/env bash` and `set -euo pipefail`.
- Quoting: quote all variable expansions; avoid word-splitting/globbing surprises.
- IO/Args: usage block; validate flags; exit non-zero on misuse.
- Secrets: never echo; pass via env or stdin.
- Testing: small functions; isolate side effects.

## C

- Style: Follow established C conventions.
- Guide: MISRA C (when applicable), CERT C, or project style; prefer consistency.
- Standard: C11+ (C17/C23 if needed); warnings-as-errors.
- Testing: Unity/CUnit; sanitizers (ASan/UBSan) in debug.
- Memory: pair alloc/free; check returns; bounds-check.
- Security: avoid unsafe APIs; use size-aware variants.

## C++

- Style: [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html).
- Project Template: [templ-project/cpp](https://github.com/templ-project/cpp)
- Standard: C++20+; RAII; smart pointers; no raw new/delete.
- Tooling: -Wall -Wextra -Werror; clang-tidy.
- Concurrency: std::thread/atomic; avoid data races.
- Testing: GoogleTest/Catch2; DI for testability.
- New projects: use the org C++ template.

## Elixir

- Style: [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide).
- Formatting: `mix format`; analysis: Credo.
- OTP: supervision trees; isolate side effects.
- Concurrency: processes and message passing.
- Testing: ExUnit.

## Go

- Style: [Effective Go](https://go.dev/doc/effective_go).
- Tooling: `gofmt`, `go vet`, `staticcheck`.
- Errors: return errors, not panics (except unrecoverable).
- Concurrency: goroutines/channels; context propagation mandatory.
- Testing: testing/testify; table-driven tests.

## Java

- Style: [Google Java Style](https://google.github.io/styleguide/javaguide.html).
- Build: Gradle/Maven; reproducible builds.
- Frameworks: Spring; prefer constructor injection.
- Concurrency: java.util.concurrent; avoid manual threads.
- Testing: JUnit 5; Testcontainers when applicable.

## JavaScript

- Style: [Google JS Style](https://google.github.io/styleguide/jsguide.html); ESLint + Prettier.
- Testing: Vitest (new) or Jest (existing).

### JavaScript (K6)

- Runtime: K6 (ES6 subset); avoid Node APIs.
- Testing: Vitest/Jest; mock K6 as needed.

### JavaScript (Node.js)

- Runtime: Node 22 or above, with ESM by default; const/let only.
- Project Template: [templ-project/javascript](https://github.com/templ-project/javascript)

### JavaScript (Deno)

- Runtime: Deno stable; default to ESM. Prefer URL imports or `deno.json` imports map.
- Tooling: `deno fmt`, `deno lint`, `deno check` for type-check with JSR/TypeScript.
- Testing: `deno test` for Deno-native; for cross-runtime libraries use Vitest in a separate Node test matrix.
- Permissions: run with least privilege (`--allow-read` specific paths, avoid `--allow-all`).
- Packaging: target web-compatible ESM; avoid Node-only APIs.
- CI: cache Deno and modules; run `deno fmt --check`, `deno lint`, `deno test`.

### JavaScript (Bun)

- Runtime: Bun stable; ESM by default. Target web/Node compat where feasible.
- Tooling: `bun run lint` with ESLint/Prettier; `bun` for scripts and dev server.
- Testing: `bun test` for Bun-native; for cross-runtime libraries, add Vitest in a separate matrix.
- Compatibility: avoid Bun-only APIs unless the project is Bun-only; document support explicitly.
- CI: install Bun via official installer; run `bun test` and lint.

## Objective-C

- Style: [Apple Coding Guidelines](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CodingGuidelines/).
- ARC: use ARC; understand retain/release.
- Patterns: delegation, categories, protocols.
- Testing: XCTest; secrets in Keychain.

## PowerShell

- Runtime: Powershell 7
- Style: Microsoft PowerShell Best Practices.
- Portability: target pwsh cross-platform.
- Naming: approved verb-noun; parameter validation.
- Analysis: PSScriptAnalyzer; tests with Pester.

## Python

- Runtime: Python 3.11 or above
- Style: [PEP 8](https://peps.python.org/pep-0008/).
- Tooling: Black; Ruff/flake8.
- Types: type hints; mypy recommended for libs.
- Packaging: pyproject.toml; src/ layout.
- Testing: pytest with fixtures.

## Rust

- Style: [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/).
- Tooling: rustfmt + clippy (deny warnings in CI).
- Errors: Result with thiserror/anyhow; avoid panics in libs.
- Ownership: avoid unnecessary clones.
- Testing: cargo test; property tests with proptest as needed.

## TypeScript

- Style: [Google TypeScript Style](https://google.github.io/styleguide/tsguide.html); ESLint + Prettier.
- Testing: Vitest (new) or Jest (existing).

### TypeScript (K6)

- Runtime: K6 constraints; emit ESM.
- Testing: Vitest/Jest; mock K6 as needed.

### TypeScript (Node.js)

- Runtime: Node 22 or above, with ESM by default; const/let only.

### TypeScript (Deno)

- Runtime: Deno stable; ESM; use `deno.json` or `deno.jsonc` for compiler options and import maps.
- Types: Deno provides type checking; use `deno check` or `deno test --allow-none`.
- Testing: `deno test` for platform code; for universal libraries, keep a Node/Vitest job too.
- Imports: prefer URL imports or import maps; avoid Node resolution semantics.
- CI: run `deno fmt --check`, `deno lint`, `deno test`.

### TypeScript (Bun)

- Runtime: Bun stable; ESM; supports TS out of the box.
- Types: configure `tsconfig.json` with `module`=ESNext, `target`=ES2022+; strict mode.
- Testing: `bun test` for Bun-native; use Vitest for cross-runtime libraries.
- Tooling: ESLint + Prettier; `bunx` to run CLIs.
- CI: install Bun; run `bun test` and lint; include Node/Vitest if cross-runtime.

## Zig

- Style: [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide).
- Formatting: built-in formatter.
- Memory: explicit allocators; no hidden allocations in APIs.
- Testing: zig test; document comptime usage/invariants.

---

## Security and Secrets (All Languages)

- Never print secrets; redact by default.
- Load secrets from environment or a secret manager; don’t commit to VCS.
- When logging configs, include keys and metadata only, never secret values.

## Observability (All Languages)

- Emit structured logs; prefer JSON when feasible.
- Include request IDs/correlation IDs; add metrics for critical paths.
- Keep logging levels appropriate: info (normal), warn (unexpected but tolerable), error (actionable).

## Deliverables (When Creating Projects)

- Minimal README with run/test instructions
- Dependency manifest (package.json, pyproject.toml, go.mod, Cargo.toml, etc.)
- Lint/format configs
- Unit tests for public APIs
