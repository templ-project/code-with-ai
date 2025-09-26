# TypeScript (K6) Developer Overrides

## Project Setup Requirements

- **Runtime:** K6 using the minimal ES6+ capabilities it supports

## Standards & Testing

- **Style Guide:** [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- **Testing:** Vitest for new projects (Jest for existing codebases); mocking any necessary K6 functionality
- **Linting:** ESLint + Prettier for consistency

## TypeScript Best Practices

- **Type Safety:** Leverage advanced type system features and compile-time error prevention
- **Modern Features:** Use latest TypeScript features and strict mode configuration
- **Security:** Configure keys and secrets via environment variables, config files, or vault systems
- **Code Organization:** ES modules with proper type definitions
- **Error Handling:** Explicit error types and comprehensive error boundaries
- **Development:** Enable strict compiler options for maximum type safety
