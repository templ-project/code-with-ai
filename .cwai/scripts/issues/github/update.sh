#!/bin/bash

# Update GitHub Issue Script
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
output_json=false
issue_id=""
title=""
labels=""
task_body=""

# Function to display usage
usage() {
  cat <<EOF
Usage: $0 [OPTIONS] --id <issue_number> <task_body>

Update an existing GitHub issue by adding comments with new requirements and optionally updating labels.

Required arguments:
    <task_body>             Additional requirements/comments to add (all remaining arguments after options)

Optional arguments:
    --id|-i <number>        Issue number to update (if not provided, auto-detects from current Git branch)
    --title|-t <title>      Update issue title (optional)
    --labels|-L <labels>    Comma-separated list of labels to add
    --json                  Output data as JSON instead of text
    -h|--help              Show this help message

Examples:
    $0 "Added OAuth2 integration requirement"
    $0 --id 123 "Added OAuth2 integration requirement"
    $0 --id 456 --title "Updated Auth Module" --labels "backend,authentication" "Changed requirements: Use JWT tokens instead of sessions"
    $0 --labels "urgent,bug" --json "Critical security fix needed for user authentication"

Notes:
    - If --id is not provided, automatically detects issue number from current Git branch name
    - Comments are added to the issue with new requirements
    - Labels are added to existing labels (not replaced)
    - Title update is optional - if not provided, title remains unchanged
    - All operations are logged for audit purposes
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --id | -i)
    issue_id="$2"
    shift 2
    ;;
  # --title | -t)
  #   title="$2"
  #   shift 2
  #   ;;
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
    log_error "Unknown option: $1. Use --help for usage information."
    exit 1
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
  log_error "Task body is required. Use --help for usage information."
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

# Update the issue
log_info "🔄 Updating issue #${issue_id}"

# Add comment with new requirements using common function
comment_body="## Updated Requirements

${task_body}

---
*Requirements updated via update-issue.sh script on $(date)*"

issue_add_comment "$issue_id" "$comment_body"

# Add labels if provided using common function
if [[ -n "$labels" ]]; then
  issue_add_labels "$issue_id" "$labels"
fi

# Get updated issue information using common function
issue_info=$(issue_read "$issue_id" false)
updated_title=$(echo "$issue_info" | jq -r '.title')
issue_url=$(echo "$issue_info" | jq -r '.url')
current_labels=$(echo "$issue_info" | jq -r '.labels[].name' | tr '\n' ',' | sed 's/,$//')

log_info "✅ Successfully updated issue #${issue_id}"

# Parse labels into array for JSON output
IFS=',' read -ra label_array <<<"${labels}"
IFS=',' read -ra current_label_array <<<"${current_labels}"

# Output results
output="{
  \"ISSUE_NUMBER\": $issue_id,
  \"ISSUE_TITLE\": \"$updated_title\",
  \"ISSUE_LABELS\": [$(printf '\"%s\",' "${current_label_array[@]}" | sed 's/,$//')],
  \"ADDED_LABELS\": [$(printf '\"%s\",' "${label_array[@]}" | sed 's/,$//')],
  \"COMMENT_ADDED\": true,
  \"TITLE_UPDATED\": $([ -n "$title" ] && echo "true" || echo "false"),
  \"ISSUE_URL\": \"$issue_url\"
}"
output_results "$output" "$output_json"
