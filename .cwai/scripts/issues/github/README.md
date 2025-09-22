# GitHub Scripts

This directory contains GitHub-specific automation scripts for managing issues, tasks, and projects.

## Scripts

### `create-issue.sh`

Creates GitHub issues/tasks with support for parent relationships and project assignment.

**Usage:**

```bash
./create-issue.sh [OPTIONS] <task_body>
```

**Features:**

- Creates GitHub issues with automatic labeling
- Links tasks to parent issues with bidirectional comments
- Adds issues to specified GitHub projects
- Supports comma-separated labels
- Auto-generates titles from task descriptions
- JSON output support

**Examples:**

```bash
# Simple task creation
./create-issue.sh "Implement user authentication module"

# Task with parent relationship and project assignment
./create-issue.sh --parent 123 --project "@templ-project" "Create login form component"

# Task with multiple labels and custom title
./create-issue.sh --title "Auth Module" --labels "backend,authentication,security" "Implement OAuth2 authentication system"

# JSON output for automation
./create-issue.sh --parent 456 --labels "frontend,ui" --json "Design user dashboard layout"
```

**Options:**

- `--parent|-p <number>`: Link to parent issue number
- `--title|-t <title>`: Custom issue title (auto-generated if not provided)
- `--labels|-L <labels>`: Comma-separated list of labels
- `--project|-P <name>`: Project name (with or without @ prefix)
- `--json`: Output JSON instead of human-readable text
- `--help|-h`: Show help message

### `common.sh`

Shared GitHub functionality library containing:

- Environment loading and validation
- GitHub authentication handling
- Label management (create/get)
- Issue creation and management
- Project assignment functionality
- Parent-child issue relationships

**Functions:**

- `load_environment()`: Load .env and .env.local files
- `validate_dependencies()`: Check for required tools (gh, jq)
- `validate_github_token()`: Verify GitHub authentication
- `create_or_get_label()`: Create labels if they don't exist
- `create_github_issue()`: Create GitHub issues with labels
- `add_issue_to_project()`: Add issues to GitHub projects
- `add_parent_relationship()`: Link child/parent issues

## Configuration

Both scripts require:

1. **GitHub CLI (`gh`)** - Install with `brew install gh` on macOS
2. **jq** - Install with `brew install jq` on macOS
3. **GitHub Token** - Set `GH_TOKEN` in `.env` or environment

**Environment Setup:**

```bash
# In .env or .env.local
GH_TOKEN=your_github_token_here
```

## Integration

The `create-feature.sh` script in the parent directory has been updated to use the shared GitHub functionality from `common.sh`, eliminating code duplication and ensuring consistent behavior across all GitHub operations.

## Project Integration

When using the `--project` option:

- Project names can be specified with or without the `@` prefix
- The script will search for projects by exact name match
- If the project doesn't exist, the script will list available projects
- Issues are automatically added to the specified project

## Parent-Child Relationships

When using the `--parent` option:

- The parent issue must exist (validated before creating child)
- Comments are added to both parent and child issues
- Parent issue gets a comment about the new subtask
- Child issue gets a comment referencing the parent task
- This creates a clear audit trail for task relationships
