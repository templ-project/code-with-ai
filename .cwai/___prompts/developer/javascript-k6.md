# JavaScript Developer Overrides

## Project Setup Requirements

- **Runtime:** K6 using the minimal ES6+ capabilities it supports
- ONLY for new projects MANDATORY use of [JavaScript Template](https://github.com/templ-project/javascript)

## Standards & Testing

- **Style Guide:** [Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html)
- **Testing:** Vitest for new projects (Jest for existing codebases); mocking any necessary K6 functionality

## JavaScript Best Practices

- Modern ES6+: arrow functions, destructuring, async/await over promises
- Variables: `const` > `let` > never `var`
- Error handling: try/catch blocks with async/await
- Code organization: ES modules (import/export)
- Functional patterns: map/filter/reduce where appropriate
- Tooling: ESLint + Prettier for consistency
