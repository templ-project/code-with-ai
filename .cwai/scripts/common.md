# Common Utilities Documentation

## Overview

The `common.sh` script provides a comprehensive set of utility functions used across the CwAI (Code with AI) project. It includes logging utilities, string manipulation, array operations, path handling, Git integration, and issue management for both local filesystem and GitHub.

## Purpose

This script is designed to be sourced by other bash scripts in the project to provide:

- Consistent logging with colored output
- Environment variable loading
- String and array manipulation utilities
- Issue tracking (local filesystem and GitHub)
- Git repository operations
- Feature management utilities

## Environment Variables

### Required Variables

- **`CWAI_SPECS_FOLDER`** - Directory where feature specifications are stored (default: `specs`)
- **`CWAI_ISSUE_MANAGER`** - Issue management backend to use (default: `localfs`)
  - Valid values: `localfs` (local filesystem), `github` (GitHub Issues)

### Optional Variables

- **`DEBUG`** - When set, enables debug logging output
- **`_ENV_LOADED`** - Internal flag to prevent duplicate environment loading
- **`_COMMON_SOURCED`** - Internal flag to prevent multiple sourcing of this script
- **`LOCALFS_FEATURE_ID`** - Override feature ID when creating local issues

## Core Functions

### Environment Management

#### `load_environment(repo_root)`

Loads environment variables from `.env` and `.env.local` files in the repository root.

**Parameters:**

- `repo_root` - Path to the repository root directory

**Behavior:**

- Exits with error if `repo_root` is not provided
- Loads variables from `.env` if it exists
- Loads variables from `.env.local` if it exists (can override `.env` values)
- Only loads once per script execution (idempotent)
- Uses `set -a` to automatically export all loaded variables

**Example:**

```bash
load_environment "/path/to/repo"
```

## Logging Functions

All logging functions write to standard error (stderr) with color-coded prefixes using the lambda symbol (λ).

### Color Codes

- **Blue** - Debug messages
- **Green** - Informational messages
- **Yellow** - Warning messages
- **Red** - Error messages

### Available Logging Functions

#### `log_debug(message)`

Logs debug messages only when `DEBUG` environment variable is set.

**Parameters:**

- `message` - The debug message to log

#### `log_info(message)`

Logs informational messages in green.

**Parameters:**

- `message` - The informational message to log

#### `log_warn(message)`

Logs warning messages in yellow.

**Parameters:**

- `message` - The warning message to log

#### `log_error(message, [exit_code])`

Logs error messages in red and exits the script.

**Parameters:**

- `message` - The error message to log
- `exit_code` - Optional exit code (default: 1)

**Behavior:**

- Always exits the script after logging
- Default exit code is 1 if not specified

## Array Utilities

### `join_by_comma(items...)`

Joins array elements with commas.

**Parameters:**

- `items...` - Variable number of items to join

**Returns:**

- Comma-separated string of all items

**Example:**

```bash
result=$(join_by_comma "apple" "banana" "cherry")
# Result: "apple,banana,cherry"
```

### `concatenate_arrays(array1_string, array2_string)`

Merges two comma-separated arrays with deduplication and removal support.

**Parameters:**

- `array1_string` - First comma-separated array
- `array2_string` - Second comma-separated array

**Behavior:**

- Items from `array2` prefixed with `-` are treated as removals
- Duplicates are automatically removed
- Order is preserved: items from `array1` first, then new items from `array2`
- Empty items are filtered out

**Returns:**

- Comma-separated string of merged items

**Example:**

```bash
result=$(concatenate_arrays "apple,banana,cherry" "date,-banana,apple")
# Result: "apple,cherry,date"
# (banana removed, apple deduplicated, date added)
```

## String Utilities

### `split_by_comma(input)`

Splits a comma-separated string into individual lines.

**Parameters:**

- `input` - Comma-separated string

**Returns:**

- Each item on a separate line

**Example:**

```bash
split_by_comma "apple,banana,cherry"
# Output:
# apple
# banana
# cherry
```

### `requirement_to_title(requirement)`

Converts a requirement description to a title by extracting the first 5 words.

**Parameters:**

- `requirement` - Full requirement text

**Returns:**

- Title with up to 5 words, non-alphanumeric characters converted to spaces

**Example:**

```bash
result=$(requirement_to_title "Users need to login securely with MFA support")
# Result: "Users need to login securely"
```

### `title_to_slug(title)`

Converts a title to a URL-friendly slug.

**Parameters:**

- `title` - Title text to convert

**Returns:**

- Lowercase slug with hyphens instead of spaces, non-alphanumeric characters removed

**Example:**

```bash
result=$(title_to_slug "User Authentication Feature")
# Result: "user-authentication-feature"
```

### `padd_feature_id(id)`

Pads a feature ID to 5 digits with leading zeros.

**Parameters:**

- `id` - Numeric feature ID

**Returns:**

- Zero-padded 5-digit string

**Example:**

```bash
result=$(padd_feature_id 42)
# Result: "00042"
```

### `detect_feature_name(requirement)`

Searches for a feature branch pattern in text and validates it exists in Git.

**Parameters:**

- `requirement` - Text to search for feature pattern

**Returns:**

- Feature name (format: `00123-feature-name`) if found and branch exists
- Empty string if not found or branch doesn't exist

**Pattern:**

- Matches: 5 digits followed by hyphen and alphanumeric characters with hyphens
- Example: `00123-user-authentication`

**Example:**

```bash
result=$(detect_feature_name "Update 00042-user-auth with new requirements")
# Result: "00042-user-auth" (if branch exists)
```

### `extract_feature_id(feature_name)`

Extracts the numeric ID from a feature name.

**Parameters:**

- `feature_name` - Feature name with ID prefix (e.g., `00123-feature-name`)

**Returns:**

- Numeric ID with leading zeros removed
- Returns "0" if no valid ID found

**Example:**

```bash
result=$(extract_feature_id "00042-user-authentication")
# Result: "42"
```

### `output_results(json_result, output_json_flag)`

Formats output as either JSON or key=value pairs.

**Parameters:**

- `json_result` - JSON string to output
- `output_json_flag` - "true" for JSON output, anything else for key=value format

**Behavior:**

- JSON mode: Outputs the JSON string as-is
- Key=value mode: Converts JSON to `KEY="value"` format
  - Arrays are joined with commas
  - Objects are output as JSON strings
  - Strings are quoted

**Example:**

```bash
json='{"name":"test","labels":["bug","feature"]}'
output_results "$json" "false"
# Output:
# name="test"
# labels="bug,feature"
```

### `generate_hex_color()`

Generates a random 6-character hex color code.

**Returns:**

- 6-character uppercase hex color (without `#` prefix)

**Behavior:**

- Tries to use `/dev/urandom` with `od` command first
- Falls back to `$RANDOM` variable if `od` is unavailable
- Final fallback: returns default blue color "1F77B4"

**Example:**

```bash
color=$(generate_hex_color)
# Result: "3FA5C2" (random)
```

## Git Functions

### `git_branch_exists(branch)`

Checks if a Git branch exists locally or on remote.

**Parameters:**

- `branch` - Branch name to check

**Returns:**

- Exit code 0 if branch exists
- Exit code 1 if branch doesn't exist

**Behavior:**

- Checks local branches first (`refs/heads/`)
- Falls back to checking remote branches (`refs/remotes/origin/`)

**Example:**

```bash
if git_branch_exists "feature-123"; then
  echo "Branch exists"
fi
```

## Local Filesystem Issue Manager

The local filesystem issue manager stores issues as JSON files in the specs directory.

### `localfs_create_issue(feature_slug, feature_title, feature_parent_dir, feature_labels, feature_body)`

Creates a new issue in the local filesystem.

**Parameters:**

- `feature_slug` - URL-friendly feature identifier
- `feature_title` - Human-readable feature title
- `feature_parent_dir` - Parent directory where feature folder will be created
- `feature_labels` - Comma-separated list of labels
- `feature_body` - Full issue description

**Behavior:**

- Determines next available feature ID by counting existing directories
- Can be overridden by setting `LOCALFS_FEATURE_ID` environment variable
- Creates directory: `{parent_dir}/{padded_id}-{slug}/`
- Creates `issue.json` file with metadata:
  - Author (from git config)
  - ID, title, description
  - Labels array
  - Created/updated timestamps
  - Empty comments array

**Returns:**

- Feature ID (numeric)

**Example:**

```bash
id=$(localfs_create_issue "user-auth" "User Authentication" "specs" "security,auth" "Add login feature")
# Creates: specs/00001-user-auth/issue.json
# Returns: 1
```

### `localfs_update_issue(feature_id, feature_name, feature_dir, feature_labels, feature_comment)`

Updates an existing local filesystem issue.

**Parameters:**

- `feature_id` - Numeric feature ID
- `feature_name` - Full feature name (e.g., `00042-user-auth`)
- `feature_dir` - Path to feature directory
- `feature_labels` - Comma-separated labels to add/remove (prefix with `-` to remove)
- `feature_comment` - Comment to add to the issue

**Behavior:**

- Reads existing labels from `issue.json`
- Merges new labels with existing (using `concatenate_arrays`)
- Adds new comment with author and timestamp
- Updates `updated_at` timestamp
- Preserves all existing data

**Example:**

```bash
localfs_update_issue "42" "00042-user-auth" "specs/00042-user-auth" "testing,-development" "Added tests"
# Adds "testing" label, removes "development" label, adds comment
```

## GitHub Issue Manager

The GitHub issue manager uses the GitHub CLI (`gh`) to interact with GitHub Issues.

### `github_create_label(label_name, [label_color], [label_description])`

Creates a GitHub label if it doesn't already exist.

**Parameters:**

- `label_name` - Name of the label
- `label_color` - Optional hex color (6 characters, no `#`). Auto-generated if not provided
- `label_description` - Optional label description

**Behavior:**

- Checks if label exists before creating
- Generates random color if not provided
- Creates label using `gh label create`
- Idempotent - safe to call multiple times

**Example:**

```bash
github_create_label "security" "FF0000" "Security-related issues"
```

### `github_create_issue(feature_slug, feature_title, feature_parent_dir, feature_labels, feature_body)`

Creates a GitHub issue and corresponding local issue.

**Parameters:**

- `feature_slug` - URL-friendly feature identifier
- `feature_title` - Human-readable feature title
- `feature_parent_dir` - Parent directory for local storage
- `feature_labels` - Comma-separated list of labels
- `feature_body` - Full issue description

**Behavior:**

- Ensures default labels exist: `task` (green) and `auto-generated` (purple)
- Creates any additional labels specified
- Creates GitHub issue with title, body, and all labels
- Extracts issue number from created issue URL
- Creates corresponding local issue using `localfs_create_issue`
- Links GitHub issue number to local issue

**Returns:**

- Feature ID (matches GitHub issue number)

**Example:**

```bash
id=$(github_create_issue "user-auth" "User Authentication" "specs" "security,auth" "Add login feature")
# Creates GitHub issue #42 and specs/00042-user-auth/issue.json
# Returns: 42
```

### `github_update_issue(feature_id, feature_name, feature_dir, feature_labels, feature_comment)`

Updates a GitHub issue and corresponding local issue.

**Parameters:**

- `feature_id` - GitHub issue number
- `feature_name` - Full feature name (e.g., `00042-user-auth`)
- `feature_dir` - Path to feature directory
- `feature_labels` - Comma-separated labels to add/remove (prefix with `-` to remove)
- `feature_comment` - Comment to add to the issue

**Behavior:**

- Parses labels to determine additions and removals
- Creates any new labels that don't exist
- Adds labels to GitHub issue using `gh issue edit --add-label`
- Removes labels from GitHub issue using `gh issue edit --remove-label`
- Adds comment to GitHub issue using `gh issue comment`
- Updates corresponding local issue using `localfs_update_issue`

**Example:**

```bash
github_update_issue "42" "00042-user-auth" "specs/00042-user-auth" "tested,-in-progress" "Tests completed"
# Adds "tested" label, removes "in-progress" label, adds comment to GitHub and local issue
```

## Usage Patterns

### Sourcing the Script

Always source this script at the beginning of your bash scripts:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

load_environment "$REPO_ROOT"
```

### Issue Management Pattern

The script uses a pluggable issue manager pattern:

```bash
# Set issue manager (localfs or github)
export CWAI_ISSUE_MANAGER="localfs"  # or "github"

# Create issue (automatically uses configured manager)
feature_id=$("${CWAI_ISSUE_MANAGER}_create_issue" \
  "feature-slug" "Feature Title" "specs" "label1,label2" "Description")

# Update issue
"${CWAI_ISSUE_MANAGER}_update_issue" \
  "$feature_id" "00042-feature-slug" "specs/00042-feature-slug" \
  "new-label,-old-label" "Update comment"
```

### Label Management Pattern

When working with labels:

- Add labels: `"label1,label2,label3"`
- Remove labels: `"-label1,-label2"`
- Mix operations: `"add-this,-remove-that,add-another"`

## Error Handling

- All functions use `set -euo pipefail` for strict error handling
- `log_error()` always exits the script
- Functions return appropriate exit codes for validation checks
- JSON operations use `jq` with proper error handling

## Dependencies

### Required Commands

- `bash` (version 4.0+)
- `jq` - JSON processing
- `git` - Version control operations
- `date` - Timestamp generation
- `find` - File system operations
- `grep`, `sed`, `awk` - Text processing

### Optional Commands

- `gh` - GitHub CLI (required only for `CWAI_ISSUE_MANAGER=github`)
- `od` - Random number generation (has fallbacks)

## Notes

- The script prevents multiple sourcing using `_COMMON_SOURCED` flag
- Environment loading is idempotent (only loads once)
- All timestamps are in UTC ISO 8601 format
- Feature IDs are always padded to 5 digits (00001, 00042, etc.)
- The script writes logs to stderr to keep stdout clean for piping
- Colors use ANSI escape codes and may not work in all terminals
