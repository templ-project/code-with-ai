# Python Developer Overrides

## Style Guide & Standards

Follow **PEP 8** - Style Guide for Python Code (<https://peps.python.org/pep-0008/>).
Use **Black** for automatic code formatting and **flake8** or **ruff** for linting.

## Testing Framework

If not prompted with different testing framework, use **pytest** for new projects.

- Prefer pytest for its powerful fixtures and plugin ecosystem
- Use unittest only when working with existing unittest codebases
- Write tests that are fast, isolated, and use descriptive assertion messages

## Project Structure

Follow standard Python project layout:

- Use `pyproject.toml` for modern Python projects
- Organize code in packages with proper `__init__.py` files
- Keep source code in `src/` directory when appropriate
- Use virtual environments (venv, conda, or poetry)

## Python-Specific Best Practices

- Use type hints for better code documentation and IDE support
- Follow naming conventions: snake_case for functions/variables, PascalCase for classes
- Use list/dict comprehensions when they improve readability
- Handle exceptions explicitly with specific exception types
- Use context managers (with statements) for resource management
- Prefer f-strings for string formatting
- Use dataclasses or Pydantic models for structured data

## Common Patterns

- Use the `if __name__ == "__main__":` pattern for script entry points
- Implement `__str__` and `__repr__` methods for custom classes
- Use generators for memory-efficient iteration over large datasets
- Apply the Single Responsibility Principle to functions and classes
- Use `pathlib` instead of `os.path` for file operations
