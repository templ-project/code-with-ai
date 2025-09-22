#!/bin/bash

# Create GitHub Issue/Task Script

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../common/log.sh"

# Source GitHub common helpers
source "${SCRIPT_DIR}/../common/env.sh"
load_environment "$REPO_ROOT"

source "${SCRIPT_DIR}/../common/strings.sh"
source "${SCRIPT_DIR}/../common/${ISSUE_MANAGER:-github}.sh"

# Initialize environment early to load configuration
validate_dependencies
validate_token

# Default values / flags
output_json=false
parent_issue=""
title=""
labels=""
task_body=""

# Function to display usage
usage() {
  cat <<EOF
Usage: $0 [OPTIONS] <task_body>

Create a GitHub issue/task with optional parent relationship and project assignment.

Required arguments:
    <task_body>             Task description (all remaining arguments after options)

Optional arguments:
    --parent|-p <number>    Parent issue number to link this task to
    --title|-t <title>      Issue title (auto-generated from body if not provided)
    --labels|-L <labels>    Comma-separated list of labels to add
    --json                  Output data as JSON instead of text
    -h|--help              Show this help message

Examples:
    $0 "Implement user authentication module"
    $0 --title "Auth Module" --labels "backend,authentication" "Implement user authentication with OAuth2"
    $0 --parent 456 --labels "frontend,ui" --json "Design user dashboard layout"

Notes:
    - Project assignment is controlled by GH_PROJECT environment variable
    - Parent relationships create bidirectional comments linking the issues
    - Labels are created automatically if they don't exist
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --parent | -p)
    parent_issue="$2"
    shift 2
    ;;
  --title | -t)
    title="$2"
    shift 2
    ;;
  --labels | -L)
    labels="$2"
    shift 2
    ;;
  --json)
    output_json=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    error_exit "Unknown option: $1. Use --help for usage information."
    ;;
  *)
    # All remaining arguments are part of the task body
    if [[ -n "$task_body" ]]; then
      task_body="$task_body $1"
    else
      task_body="$1"
    fi
    shift
    ;;
  esac
done

# Validate required arguments
if [[ -z "${task_body}" ]]; then
  error_exit "Task body is required. Use --help for usage information."
fi

# Validate parent issue number if provided
if [[ -n "${parent_issue}" ]]; then
  if ! [[ "${parent_issue}" =~ ^[0-9]+$ ]]; then
    error_exit "Parent issue must be a valid issue number"
  fi
fi

# Generate title if not provided
if [[ -z "${title}" ]]; then
  # Extract first 8 words for title
  title=$(echo "${task_body}" | awk '{for(i=1;i<=NF && i<=8;i++) printf "%s ", $i}' | sed 's/ *$//')
  if [[ ${#title} -gt 50 ]]; then
    title="${title:0:47}..."
  fi
fi

# Create GitHub issue
issue_number=$(issue_create "$title" "$task_body" "$labels")

# Validate issue creation succeeded
if [[ -z "$issue_number" || "$issue_number" == "0" ]]; then
  error_exit "Failed to create GitHub issue. Check your authentication and repository access."
fi
log_info "✅ Created GitHub issue (#$issue_number) $title"

# Add to project if specified
if [[ -n "$GH_PROJECT" ]]; then
  issue_ensure_project "$issue_number" "$GH_PROJECT" "$GH_OWNER"
fi

# Add parent relationship if specified
if [[ -n "${parent_issue}" ]]; then
  issue_ensure_parent "$issue_number" "$parent_issue"
fi

# Parse labels into array for JSON output
IFS=',' read -ra label_array <<<"${labels}"

# Output results
output="{
  \"ISSUE_NUMBER\": $issue_number,
  \"ISSUE_TITLE\": \"$title\",
  \"ISSUE_LABELS\": [$(printf '\"%s\",' "${label_array[@]}" | sed 's/,$//')],
  \"ISSUE_PARENT\": \"${parent_issue:-null}\",
  \"ISSUE_PROJECT\": \"${GH_PROJECT:-null}\",
  \"ISSUE_URL\": \"https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\)\.git.*/\1/')/issues/$issue_number\"
}"
output_results "$output" "$output_json"
