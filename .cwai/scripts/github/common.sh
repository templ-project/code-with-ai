#!/bin/bash

# GitHub-specific common helper functions
# Guard against multiple sourcing.

if [[ -n "${GITHUB_COMMON_LIB_LOADED:-}" ]]; then
  return 0
fi
readonly GITHUB_COMMON_LIB_LOADED=1

# NOTE: Do NOT set -euo pipefail here; leave that to caller scripts so they can
# control error handling without unexpected side-effects when sourcing.

# Path initialization (only if not already defined by caller)
: "${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
: "${REPO_ROOT:=$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

########################################
# Logging & errors (duplicated for standalone use)
########################################
log() {
  # Expect caller to define output_json; default to false if not.
  local is_json="${output_json:-false}"
  if [[ "${is_json}" == "false" ]]; then
    echo "$@" >&2
  fi
}

error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

########################################
# Environment loading
########################################
load_environment() {
  # Load .env first, then .env.local (local overrides global)
  local env_file
  for env_file in "${REPO_ROOT}/.env" "${REPO_ROOT}/.env.local"; do
    if [[ -f "$env_file" ]]; then
      log "Loading environment from: $env_file"
      set -a # automatically export all variables
      source "$env_file"
      set +a
    fi
  done
}

########################################
# Dependency validation
########################################
validate_dependencies() {
  local missing_deps=()

  # Check for gh CLI
  if ! command -v gh > /dev/null 2>&1; then
    missing_deps+=("gh (GitHub CLI)")
  fi

  # Check for jq
  if ! command -v jq > /dev/null 2>&1; then
    missing_deps+=("jq")
  fi

  if ((${#missing_deps[@]} > 0)); then
    error_exit "Missing required dependencies: ${missing_deps[*]}. Please install them and try again."
  fi
}

########################################
# GitHub authentication validation
########################################
validate_github_token() {
  if [[ -z "${GH_TOKEN:-}" ]]; then
    error_exit "GH_TOKEN not found in environment. Please set it in .env file or environment."
  fi

  # Export GH_TOKEN for gh CLI to use
  export GH_TOKEN

  # Test GitHub authentication
  if ! gh auth status > /dev/null 2>&1; then
    log "⚠️ gh CLI not authenticated, but GH_TOKEN is available. Proceeding..."
  fi
}

########################################
# GitHub issue relationships
########################################
add_parent_relationship() {
  local child_issue="$1"
  local parent_issue="$2"

  log "🔗 Adding parent relationship: #$child_issue -> #$parent_issue"

  # Verify parent issue exists
  if ! gh issue view "$parent_issue" > /dev/null 2>&1; then
    error_exit "Parent issue #$parent_issue does not exist"
  fi

  # Add comment to child issue referencing parent
  gh issue comment "$child_issue" --body "**Parent Task:** #$parent_issue

This task is a subtask of #$parent_issue.

---
*Relationship added via create-issue.sh script*" > /dev/null 2>&1

  # Add comment to parent issue referencing child
  gh issue comment "$parent_issue" --body "**Subtask Created:** #$child_issue

New subtask created and linked to this parent task.

---
*Relationship added via create-issue.sh script*" > /dev/null 2>&1

  log "✅ Parent relationship established between #$child_issue and #$parent_issue"
}
