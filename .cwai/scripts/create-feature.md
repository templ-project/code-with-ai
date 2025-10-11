# Create Feature Script Documentation

## Overview

The `create-feature.sh` script is an interactive tool for creating and updating feature branches, issues, and specification documents in the CwAI (Code with AI) project. It automates the workflow of setting up new features or updating existing ones with proper issue tracking and documentation templates.

## Purpose

This script helps developers:

- Create new feature branches with proper naming conventions
- Generate feature specification directories with templates
- Track features using either local filesystem or GitHub Issues
- Update existing features with comments and labels
- Maintain consistent project structure and naming

## Requirements

### System Requirements

- Bash 4.0 or later
- Git repository (must be run from within a git repo)
- jq (JSON processor)

### Environment Variables

Must be set (loaded from `.env` or `.env.local`):

- **`CWAI_SPECS_FOLDER`** - Directory for feature specifications (default: `specs`)
- **`CWAI_ISSUE_MANAGER`** - Issue backend: `localfs` or `github` (default: `localfs`)

## Usage

### Basic Syntax

```bash
./create-feature.sh <requirement> [OPTIONS]
```

### Required Arguments

- **`<requirement>`** - Feature requirement description (can be multiple words)

### Optional Arguments

#### `--json`

Output results as JSON instead of key=value text format.

**Example:**

```bash
./create-feature.sh "Add user login" --json
```

#### `--title <title>`

Explicitly set the feature title instead of auto-generating from requirement.

**Example:**

```bash
./create-feature.sh "Users need secure auth" --title "User Authentication System"
```

#### `--template <name>` or `-t <name>`

Specify a template to copy into the feature directory. Can be used multiple times.

**Available Templates:**

- `product-requirement-document` or `prd` - Product requirements
- `high-level-design` or `hld` - High-level architecture design
- `low-level-design` or `lld` - Detailed implementation design
- `game-design` or `game` - Game design document

**Example:**

```bash
./create-feature.sh "Add multiplayer" --template hld --template game-design
```

#### `--labels <label>` or `-l <label>`

Add labels to the issue. Accepts comma-separated values. Can be used multiple times.

**Label Operations:**

- Add label: `--labels security`
- Remove label: `--labels -development` (prefix with `-`)
- Multiple: `--labels security,authentication`

**Example:**

```bash
./create-feature.sh "Add OAuth" --labels security,authentication --labels -draft
```

#### `--help` or `-h`

Display usage information and exit.

## Workflow

### Creating a New Feature

When you provide a requirement that doesn't match any existing feature branch:

1. **Title Generation**
   - If `--title` is provided, uses that
   - Otherwise, extracts first 5 words from requirement
   - Example: "Users need to login securely" → "Users need to login securely"

2. **Slug Creation**
   - Converts title to URL-friendly slug
   - Lowercase, hyphens instead of spaces
   - Example: "User Login Feature" → "user-login-feature"

3. **Issue Creation**
   - Creates issue using configured issue manager (`localfs` or `github`)
   - Assigns sequential feature ID
   - Stores issue metadata

4. **Directory Creation**
   - Creates directory: `{CWAI_SPECS_FOLDER}/{padded_id}-{slug}/`
   - Example: `specs/00042-user-login-feature/`

5. **Branch Creation**
   - Creates and checks out new Git branch with same name as directory
   - Example: `00042-user-login-feature`

6. **Template Copying**
   - Copies specified templates from `.cwai/templates/outline/`
   - Skips if template already exists
   - Logs each copied template

7. **Output Results**
   - Returns feature information in JSON or key=value format

### Updating an Existing Feature

When your requirement contains a reference to an existing feature (format: `00042-feature-name`):

1. **Feature Detection**
   - Searches requirement for pattern: 5 digits, hyphen, alphanumeric+hyphens
   - Validates that Git branch exists
   - Example: "Update 00042-user-login with MFA"

2. **Branch Checkout**
   - Switches to the existing feature branch

3. **Issue Update**
   - Adds comment to issue (GitHub or local)
   - Updates labels (add/remove as specified)
   - Updates timestamp

4. **Template Addition**
   - Copies any newly specified templates
   - Skips templates that already exist

5. **Output Results**
   - Returns updated feature information

## Feature Naming Convention

Features follow a strict naming pattern:

**Format:** `{padded_id}-{slug}`

**Components:**

- `padded_id` - 5-digit zero-padded number (00001, 00042, 00123)
- `slug` - URL-friendly lowercase identifier with hyphens

**Examples:**

- `00001-user-authentication`
- `00042-payment-processing`
- `00123-email-notifications`

## Issue Tracking

### Local Filesystem Mode (`CWAI_ISSUE_MANAGER=localfs`)

**Storage Location:** `specs/{feature-name}/issue.json`

**Issue Structure:**

```json
{
  "author": "John Doe <john@example.com>",
  "id": 42,
  "title": "User Authentication",
  "description": "Add secure login functionality",
  "labels": ["security", "authentication"],
  "created_at": "2025-10-11T10:30:00Z",
  "updated_at": "2025-10-11T14:20:00Z",
  "comments": [
    {
      "author": "John Doe <john@example.com>",
      "comment": "Added MFA support",
      "created_at": "2025-10-11T14:20:00Z"
    }
  ]
}
```

**Features:**

- Sequential ID assignment based on directory count
- All metadata stored in JSON
- Comments array for updates
- Author extracted from git config

### GitHub Mode (`CWAI_ISSUE_MANAGER=github`)

**Requirements:**

- GitHub CLI (`gh`) installed and authenticated
- Repository must have GitHub remote

**Features:**

- Creates actual GitHub Issues
- Automatically creates labels if they don't exist
- Default labels: `task` (green), `auto-generated` (purple)
- Syncs issue number to local storage
- Comments are posted to GitHub Issue
- Labels can be added/removed through GitHub UI

**Label Colors:**

- `task` - Green (#0e8a16)
- `auto-generated` - Purple (#bfd4f2)
- Custom labels - Random colors (auto-generated)

## Template System

### Template Location

Templates are stored in: `.cwai/templates/outline/`

### Template Naming

Templates can be referenced by:

- Full filename: `product-requirement-document.md`
- Filename without extension: `product-requirement-document`
- Short alias: `prd`, `hld`, `lld`, `game`

### Template Processing

1. Script looks for template in `.cwai/templates/outline/`
2. If not found with exact name, tries adding `.md` extension
3. If still not found, logs warning and continues
4. If found, copies to feature directory
5. If destination exists, skips with warning

### Adding Custom Templates

To add a new template:

1. Create markdown file in `.cwai/templates/outline/`
2. Reference by filename in `--template` argument

## Output Format

### Key=Value Format (Default)

```bash
BRANCH_NAME="00042-user-authentication"
FEATURE_FOLDER="/path/to/specs/00042-user-authentication"
feature_id="42"
TITLE="User Authentication"
REQUIREMENT="Users need to login securely"
COPIED_TEMPLATES="hld.md,lld.md"
```

### JSON Format (With `--json`)

```json
{
  "BRANCH_NAME": "00042-user-authentication",
  "FEATURE_FOLDER": "/path/to/specs/00042-user-authentication",
  "feature_id": "42",
  "TITLE": "User Authentication",
  "REQUIREMENT": "Users need to login securely",
  "COPIED_TEMPLATES": ["hld.md", "lld.md"]
}
```

## Examples

### Example 1: Create New Feature with Templates

```bash
./create-feature.sh "Users need to login securely" \
  --template high-level-design \
  --template low-level-design \
  --labels security,authentication
```

**Result:**

- Creates `specs/00001-users-need-to-login/`
- Creates issue #1 with labels: security, authentication
- Creates branch `00001-users-need-to-login`
- Copies `high-level-design.md` and `low-level-design.md`
- Checks out new branch

### Example 2: Update Existing Feature

```bash
./create-feature.sh "00001-users-need-to-login Add MFA support" \
  --labels mfa,security \
  --labels -draft \
  --template game-design
```

**Result:**

- Switches to branch `00001-users-need-to-login`
- Adds comment "Add MFA support" to issue
- Adds labels: mfa, security
- Removes label: draft
- Copies `game-design.md` (if not already present)

### Example 3: Create Feature with Custom Title

```bash
./create-feature.sh "Add oauth google fb github" \
  --title "OAuth Integration" \
  --template prd \
  --json
```

**Result:**

- Creates feature with title "OAuth Integration" (not auto-generated)
- Creates slug: `oauth-integration`
- Returns JSON output

### Example 4: Simple Feature (No Templates)

```bash
./create-feature.sh "Fix password reset bug" \
  --labels bug,urgent
```

**Result:**

- Creates feature directory structure
- No templates copied (directory exists but is empty except issue.json)
- Creates branch and issue with bug and urgent labels

## Error Handling

### Common Errors

#### "Requirement is required"

- Cause: No requirement text provided
- Solution: Provide requirement as argument

#### "Template 'xyz' not found"

- Cause: Template doesn't exist in `.cwai/templates/outline/`
- Solution: Check template name, or template file exists

#### "Failed to create branch"

- Cause: Branch with that name already exists
- Solution: Branch may have been created manually; use update syntax instead

#### "Could not determine issue from branch"

- Cause: Branch name doesn't match feature pattern
- Solution: Ensure branch follows `00000-name` format

#### "Feature directory not found"

- Cause: Trying to update feature whose directory was deleted
- Solution: Re-create feature or fix directory

### Bash Version Check

The script requires Bash 4.0+. If older version detected:

```text
ERROR: Bash 4 or later is required to run this script.
```

## Integration with Git

### Branch Operations

The script performs these Git operations:

- `git checkout -b <feature-name>` - Create and checkout new branch
- `git checkout <feature-name>` - Switch to existing branch
- `git config --get user.name` - Get author name
- `git config --get user.email` - Get author email
- `git rev-parse --verify` - Check if branch exists

### Working Tree Requirements

- Script doesn't require clean working tree
- Creates branches from current HEAD
- No automatic commits (user must commit changes)

## Best Practices

### Naming Features

- Use descriptive requirement text
- First 5 words become the title
- Keep requirements concise but clear
- Example: "Add user authentication with OAuth" better than "Users"

### Using Templates

- Start with `prd` for new features
- Add `hld` when ready to design
- Add `lld` before implementation
- Use `game` for game-specific features

### Label Strategy

- Use consistent label names across features
- Remove draft/temporary labels when done: `--labels -draft`
- Add status labels: `in-progress`, `review`, `done`

### Workflow Tips

1. Create feature with requirement and templates
2. Fill in template documents
3. Commit changes to feature branch
4. Update feature as work progresses with comments
5. Add/remove labels to reflect status

## Script Structure

### Main Functions

1. **`parse_args()`** - Parses command-line arguments
2. **`copy_templates()`** - Copies template files to feature directory
3. **`create_new_feature()`** - Creates new feature with issue and branch
4. **`update_existing_feature()`** - Updates existing feature
5. **`output_feature_results()`** - Formats and outputs results
6. **`main()`** - Orchestrates workflow based on requirement

### Dependencies

The script sources and uses functions from:

- `common.sh` - Utility functions, logging, issue management
- Git commands - Branch and config operations
- jq - JSON processing
- Standard Unix tools - mkdir, cp, basename, etc.

## Notes

- Script must be run from repository root or subdirectory
- Creates parent directories as needed
- All operations are logged with colored output
- Templates are optional; directory structure is always created
- Issue IDs are assigned sequentially for local mode
- GitHub issue numbers are used for GitHub mode
- Script is idempotent for template copying (skips existing)
