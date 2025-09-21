#!/bin/bash

# Read GitHub Issues Script
# Follows Google Bash Style Guide: https://google.github.io/styleguide/shellguide.html

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../common/log.sh"

# Source GitHub common helpers
source "${SCRIPT_DIR}/../common/env.sh"
load_environment "$REPO_ROOT"

source "${SCRIPT_DIR}/../common/strings.sh"
source "${SCRIPT_DIR}/../common/git.sh"
source "${SCRIPT_DIR}/../common/${ISSUE_MANAGER:-github}.sh"

# Initialize environment early to load configuration
validate_dependencies
validate_token

# Default values / flags
output_format="text"
issue_id=""
state="all"
limit=50
show_comments=false
show_labels=true
show_assignees=true

#######################################
# Formats issue data into different output formats.
# Provides a standardized way to format issue information across different scripts.
# Globals:
#   None
# Arguments:
#   $1 - Output format (required): text, json, or markdown
#   $2 - Issue data as JSON (required)
#   $3 - Include comments (optional, boolean: true/false, defaults to false)
#   $4 - Show labels (optional, boolean: true/false, defaults to true)
#   $5 - Show assignees (optional, boolean: true/false, defaults to true)
# Outputs:
#   Formatted issue information to stdout
# Returns:
#   0 on success, non-zero on failure
# Notes:
#   - Handles text, JSON, and markdown output formats
#   - Extensible for future formats and customization
#######################################
format_issue_output() {
  local output_format="$1"
  local issue_data="$2"
  local include_comments="${3:-false}"
  local show_labels="${4:-true}"
  local show_assignees="${5:-true}"

  # Validate format
  if [[ ! "$output_format" =~ ^(text|json|markdown)$ ]]; then
    log_error "Invalid output format: $output_format. Must be one of: text, json, markdown"
    return 1
  fi

  # Extract common fields
  local number title body state created_at updated_at author url
  number=$(echo "$issue_data" | jq -r '.number')
  title=$(echo "$issue_data" | jq -r '.title')
  body=$(echo "$issue_data" | jq -r '.body // ""')
  state=$(echo "$issue_data" | jq -r '.state')
  created_at=$(echo "$issue_data" | jq -r '.createdAt')
  updated_at=$(echo "$issue_data" | jq -r '.updatedAt')
  author=$(echo "$issue_data" | jq -r '.author.login')
  url=$(echo "$issue_data" | jq -r '.url')

  case "$output_format" in
  text)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ISSUE #${number}: ${title}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "State:      $(echo "$state" | tr '[:lower:]' '[:upper:]')"
    echo "Author:     ${author}"
    echo "Created:    ${created_at}"
    echo "Updated:    ${updated_at}"
    echo "URL:        ${url}"

    if [[ "$show_labels" == "true" ]]; then
      local labels
      labels=$(echo "$issue_data" | jq -r '.labels[].name' | tr '\n' ', ' | sed 's/, $//')
      if [[ -n "$labels" ]]; then
        echo "Labels:     ${labels}"
      fi
    fi

    if [[ "$show_assignees" == "true" ]]; then
      local assignees
      assignees=$(echo "$issue_data" | jq -r '.assignees[].login' | tr '\n' ', ' | sed 's/, $//')
      if [[ -n "$assignees" ]]; then
        echo "Assignees:  ${assignees}"
      fi
    fi

    echo ""
    echo "DESCRIPTION:"
    echo "────────────────────────────────────────────────────────────────────────────"
    echo "${body}"

    if [[ "$include_comments" == "true" ]]; then
      echo ""
      echo "COMMENTS:"
      echo "────────────────────────────────────────────────────────────────────────────"
      local comments
      comments=$(echo "$issue_data" | jq -r '.comments[]?')
      if [[ -n "$comments" ]]; then
        echo "$comments" | jq -r 'select(. != null) | "[\(.createdAt)] \(.author.login):\n\(.body)\n"'
      else
        echo "No comments."
      fi
    fi
    echo ""
    ;;

  json)
    echo "$issue_data"
    ;;

  markdown)
    echo "# Issue #${number}: ${title}"
    echo ""
    echo "- **State:** $(echo "$state" | tr '[:lower:]' '[:upper:]')"
    echo "- **Author:** ${author}"
    echo "- **Created:** ${created_at}"
    echo "- **Updated:** ${updated_at}"
    echo "- **URL:** ${url}"

    if [[ "$show_labels" == "true" ]]; then
      local labels
      labels=$(echo "$issue_data" | jq -r '.labels[].name' | tr '\n' ' ')
      if [[ -n "$labels" ]]; then
        echo "- **Labels:** ${labels}"
      fi
    fi

    if [[ "$show_assignees" == "true" ]]; then
      local assignees
      assignees=$(echo "$issue_data" | jq -r '.assignees[].login' | tr '\n' ' ')
      if [[ -n "$assignees" ]]; then
        echo "- **Assignees:** ${assignees}"
      fi
    fi

    echo ""
    echo "## Description"
    echo ""
    echo "${body}"

    if [[ "$include_comments" == "true" ]]; then
      echo ""
      echo "## Comments"
      echo ""
      local comments
      comments=$(echo "$issue_data" | jq -r '.comments[]?')
      if [[ -n "$comments" ]]; then
        echo "$comments" | jq -r 'select(. != null) | "### \(.author.login) - \(.createdAt)\n\n\(.body)\n"'
      else
        echo "No comments."
      fi
    fi
    echo ""
    ;;
  esac
}

# Function to display usage
usage() {
  cat <<EOF
Usage: $0 [OPTIONS] [issue_number]

Read and display GitHub issue information in CLI format optimized for AI consumption.

Optional arguments:
    [issue_number]          Specific issue number to read (if not provided, auto-detects from Git branch or lists multiple issues)
    --format|-f <format>    Output format: text, json, or markdown (default: text)
    --state|-s <state>      Issue state filter: open, closed, or all (default: all)
    --limit|-l <number>     Maximum number of issues to display when listing (default: 50)
    --comments|-c           Include comments in output (default: false)
    --no-labels             Don't show labels in output
    --no-assignees          Don't show assignees in output
    -h|--help              Show this help message

Examples:
    $0                                          # Auto-detect issue from Git branch or list all recent issues
    $0 123                                      # Show detailed info for issue #123
    $0 --format json --state open              # List open issues in JSON format
    $0 456 --comments --format markdown        # Show issue #456 with comments in markdown
    $0 --state closed --limit 10               # Show last 10 closed issues

Output formats:
    text     - Human-readable text format (default)
    json     - Structured JSON format
    markdown - Markdown format suitable for documentation

Notes:
    - When no issue number is specified, attempts to auto-detect from current Git branch
    - If auto-detection fails, shows a list of issues instead
    - Comments are only included when explicitly requested (--comments flag)
    - All times are displayed in ISO 8601 format for consistency
    - AI-friendly output includes structured data and clear formatting
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --format | -f)
    output_format="$2"
    shift 2
    ;;
  --state | -s)
    state="$2"
    shift 2
    ;;
  --limit | -l)
    limit="$2"
    shift 2
    ;;
  --comments | -c)
    show_comments=true
    shift
    ;;
  --no-labels)
    show_labels=false
    shift
    ;;
  --no-assignees)
    show_assignees=false
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    log_error "Unknown option: $1. Use --help for usage information."
    exit 1
    ;;
  *)
    # First positional argument is issue number
    if [[ -z "$issue_id" ]]; then
      issue_id="$1"
    else
      log_error "Too many arguments. Use --help for usage information."
      exit 1
    fi
    shift
    ;;
  esac
done

# Validate output format
if [[ ! "$output_format" =~ ^(text|json|markdown)$ ]]; then
  log_error "Invalid output format: $output_format. Must be one of: text, json, markdown"
fi

# Validate state
if [[ ! "$state" =~ ^(open|closed|all)$ ]]; then
  log_error "Invalid state: $state. Must be one of: open, closed, all"
fi

# Validate limit
if ! [[ "$limit" =~ ^[0-9]+$ ]] || [ "$limit" -lt 1 ] || [ "$limit" -gt 1000 ]; then
  log_error "Limit must be a number between 1 and 1000"
fi

if [ -z "$issue_id" ]; then
  log_info "🔍 No issue ID provided, attempting to auto-detect from current Git branch..."
  issue_id=$(detect_feature_id 2>/dev/null || echo "")
  if [ -n "$issue_id" ]; then
    log_info "✅ Detected issue ID: #${issue_id}"
  fi
fi

if [ -z "$issue_id" ]; then
  log_error "No issue ID provided and could not auto-detect from current Git branch. Please provide an issue number."
fi

# Validate issue ID if provided using common function
if [[ -n "$issue_id" ]] && ! [[ "$issue_id" =~ ^[0-9]+$ ]]; then
  log_error "Issue ID must be a valid issue number"
fi

# Verify issue exists using common function
if ! issue_exists "$issue_id"; then
  log_error "No issue detected with id $issue_id..."
fi

# Get issue data using common function
issue_data=$(issue_read "$issue_id" "$show_comments")

# Format output using common function
format_issue_output "$output_format" "$issue_data" "$show_comments" "$show_labels" "$show_assignees"
