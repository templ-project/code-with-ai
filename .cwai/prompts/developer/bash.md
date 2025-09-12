# Bash Developer Overrides

## Standards & Testing

- **Style Guide:** [Google Bash Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Testing:** bats-core for new projects (shunit2 or shellspec for existing codebases)
- **Static Analysis:** ShellCheck for script validation and best practices

## Bash Best Practices

- **Portability:** Write POSIX-compliant scripts when possible, use bash-specific features judiciously
- **Error Handling:** Use `set -euo pipefail` for strict error handling and undefined variable detection
- **Security:** Configure secrets via environment variables, avoid hardcoded credentials
- **Quoting:** Always quote variables to prevent word splitting and globbing issues
- **Functions:** Use functions for reusable code blocks and better organization
- **Documentation:** Include clear usage examples and parameter descriptions
- **Automation:** Design for CI/CD integration and system administration tasks
- **Testing:** Write testable scripts with clear input/output interfaces
