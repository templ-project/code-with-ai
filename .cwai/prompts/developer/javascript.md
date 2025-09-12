# JavaScript Developer Overrides

## Style Guide & Standards

Always follow the **Google JavaScript Style Guide** (<https://google.github.io/styleguide/jsguide.html>).

## Testing Framework

If not prompted with different testing framework, use **Vitest** for new projects.

- Prefer Vitest for its speed and modern API
- Use Jest only when working with existing Jest codebases
- Write tests that are fast, isolated, and deterministic

## Project Bootstrapping

Use https://github.com/templ-project/javascript repository as template for the project, only if the project is not created already.

## JavaScript-Specific Best Practices

- Use modern ES6+ features (arrow functions, destructuring, async/await)
- Prefer `const` and `let` over `var`
- Use meaningful variable names and avoid abbreviations
- Handle promises with async/await instead of `.then()` chains
- Implement proper error handling with try/catch blocks
- Use ESLint and Prettier for consistent code formatting

## Common Patterns

- Use modules (import/export) for code organization
- Implement the Module Pattern for encapsulation
- Use Factory functions for object creation when appropriate
- Apply functional programming concepts (map, filter, reduce) where suitable
