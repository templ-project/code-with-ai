#!/bin/bash

#######################################
# Git Helper Functions
#
# This file contains common Git-related functions that can be used across
# multiple scripts for branch management, feature detection, and repository
# operations.
#
# Follows Google Bash Style Guide: https://google.github.io/styleguide/shellguide.html
#######################################

# Prevent multiple sourcing
[[ -n "${_GIT_SH_SOURCED:-}" ]] && return 0
readonly _GIT_SH_SOURCED=1


if ! command -v log_info >/dev/null 2>&1; then
  echo "log_info function is not available, please import log.sh before git.sh" >&2
  exit 1
fi

if ! command -v extract_feature_id >/dev/null 2>&1; then
  echo "extract_feature_id function is not available, please import strings.sh before git.sh" >&2
  exit 1
fi

# Detects feature ID from current branch (00123-feature-name -> 123)
detect_feature_id() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    return 1
  fi

  local current_branch
  current_branch=$(git branch --show-current 2>/dev/null) || return 1

  if [[ ! "$current_branch" =~ ^[0-9]{5}-[a-z0-9-]+ ]]; then
    log_warn "No feature branch detected.."
    return 1
  fi

  local feature_id
  feature_id=$(extract_feature_id "$current_branch")

  if [[ "$feature_id" != "0" ]]; then
    echo "$feature_id" | sed 's/^0*//'
  else
    return 1
  fi
}

# Ensure we're in a git repository (exits if not)
ensure_git_repo() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: Not in a git repository" >&2
    exit 1
  fi
}

# Check working tree is clean (exits if dirty)
assert_clean_repo() {
  ensure_git_repo
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "ERROR: Working tree has uncommitted changes. Commit or stash before proceeding." >&2
    exit 1
  fi
}

# Check if branch exists (local or remote)
git_branch_exists() {
  local branch="$1"
  git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null 2>&1 ||
    git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1
}

# Get current branch name
get_current_branch() {
  ensure_git_repo
  git branch --show-current 2>/dev/null || return 1
}

# Get GitHub repo path (owner/repo)
get_github_repo_path() {
  ensure_git_repo
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null) || return 1
  echo "$remote_url" | sed 's/.*github.com[:/]\([^.]*\)\.git.*/\1/' || return 1
}

