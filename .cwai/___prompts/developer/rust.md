# Rust Developer Overrides

## Standards & Testing

- **Style Guide:** [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- **Testing:** Built-in `test` framework or `proptest` for property-based testing
- **Tooling:** `rustfmt` for formatting, `clippy` for linting

## Rust Best Practices

- **Memory Safety:** Leverage ownership, borrowing, and lifetimes for zero-cost abstractions
- **Performance:** Focus on performance-critical and system-level programming
- **Concurrency:** Use async programming patterns and safe concurrency primitives
- **Error Handling:** Comprehensive `Result` and `Option` usage with explicit error propagation
- **Security:** Configure secrets via environment variables, config files, or vault systems
- **Code Organization:** Use modules, traits, and crates effectively
- **Development:** Enable all recommended lints and follow idiomatic Rust patterns
