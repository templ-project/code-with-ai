#!/bin/bash

# Common helper functions shared by feature scripts.
# Guard against multiple sourcing.

if [[ -n "${COMMON_FEATURE_LIB_LOADED:-}" ]]; then
  return 0
fi
readonly COMMON_FEATURE_LIB_LOADED=1

# NOTE: Do NOT set -euo pipefail here; leave that to caller scripts so they can
# control error handling without unexpected side-effects when sourcing.

# Path initialization (only if not already defined by caller)
: "${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
: "${REPO_ROOT:=$(cd "${SCRIPT_DIR}/../.." && pwd)}"
: "${SPECS_DIR:=${REPO_ROOT}/.specs}"
: "${TEMPLATES_DIR:=${REPO_ROOT}/.cwai/templates}"

########################################
# Logging & errors
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
# Feature / naming helpers
########################################
extract_feature_id() {
  local name="$1"
  echo "${name}" | grep -o '^[0-9]\{5\}' || echo "0"
}

########################################
# Git helpers
########################################
ensure_git_repo() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    error_exit "Not in a git repository"
  fi
}

assert_clean_repo() {
  ensure_git_repo
  if ! git diff --quiet || ! git diff --cached --quiet; then
    error_exit "Working tree has uncommitted changes. Commit or stash before proceeding."
  fi
}

git_branch_exists() {
  local branch="$1"
  git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null 2>&1 || \
    git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1
}

git_checkout_existing_or_remote() {
  local branch="$1"
  if git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null 2>&1; then
    git checkout "${branch}" >/dev/null 2>&1 || error_exit "Failed to checkout branch ${branch}"
  else
    git checkout -t "origin/${branch}" >/dev/null 2>&1 || error_exit "Failed to checkout remote branch ${branch}"
  fi
}

########################################
# Feature branch pattern detection (non-fatal)
# Returns the first detected pattern or empty string.
########################################
detect_feature_branch_from_requirement() {
  local requirement="$1"
  local feature_branch
  feature_branch=$(echo "$requirement" | grep -oE '([0-9]{5}-[a-z0-9][a-z0-9-]*)' | head -n 1 || true)
  echo "$feature_branch"
}

########################################
# Title / slug helpers
########################################
# Derive a provisional title from first five words of requirement
requirement_to_title() {
  local requirement="$1"
  # Extract first five words (alphanumeric + hyphen/apostrophe) then join with space
  echo "$requirement" | \
    tr '\n' ' ' | \
    sed 's/[^A-Za-z0-9_-]/ /g' | \
    awk '{ for(i=1;i<=NF && i<=5;i++){ printf("%s ", $i) } }' | sed 's/ *$//'
}

title_to_slug() {
  local title="$1"
  echo "$title" | tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-\|-$//g'
}

########################################
# ID management
########################################
get_highest_existing_id() {
  local max_id=0 current_id

  if [[ -d "${SPECS_DIR}" ]]; then
    # shellcheck disable=SC2045
    for folder in $(ls -1 "${SPECS_DIR}" 2>/dev/null | grep -E '^[0-9]{5}-'); do
      if [[ -d "${SPECS_DIR}/${folder}" ]]; then
        current_id=$(extract_feature_id "${folder}")
        if [[ "${current_id}" -gt "${max_id}" ]]; then
          max_id="${current_id}"
        fi
      fi
    done
  fi

  if git rev-parse --git-dir >/dev/null 2>&1; then
    while IFS= read -r branch; do
      branch=$(echo "${branch}" | sed 's/^[* ]\+//')
      current_id=$(extract_feature_id "${branch}")
      if [[ "${current_id}" -gt "${max_id}" ]]; then
        max_id="${current_id}"
      fi
    done < <(git branch --all | grep -E '[0-9]{5}-' || true)
  fi

  echo "${max_id}"
}

get_next_feature_id() {
  local counter=1 highest_existing ref_counter
  
  ensure_git_repo
  
  # Try to get counter from git ref (cross-platform, multi-computer safe)
  # This ref syncs automatically with git push/pull
  if git show-ref --verify --quiet refs/feature-counter; then
    ref_counter=$(git show refs/feature-counter 2>/dev/null | head -1 || echo 0)
    if [[ "$ref_counter" =~ ^[0-9]+$ ]] && [[ "$ref_counter" -gt 0 ]]; then
      counter=$((ref_counter + 1))
    fi
  fi
  
  # Always check existing branches/folders as safety net
  # This handles cases where refs might be out of sync temporarily
  highest_existing=$(get_highest_existing_id)
  if [[ "$highest_existing" -ge "$counter" ]]; then
    counter=$((highest_existing + 1))
  fi
  
  printf "%05d" "$counter"
}

save_feature_id() {
  local id="$1"
  
  ensure_git_repo
  
  # Store in git ref for cross-platform, multi-computer compatibility
  # This ref will sync automatically with git push/pull
  echo "$id" | git hash-object -w --stdin | \
    xargs git update-ref refs/feature-counter
  
  # Optional: Also store locally for immediate fallback (not committed)
  local counter_file="${SPECS_DIR}/.feature_counter"
  mkdir -p "${SPECS_DIR}"
  echo "$id" > "${counter_file}"
  
  log "Feature ID $id saved to git ref (syncs across computers)"
}

########################################
# Branch management for new feature creation
########################################
check_current_branch() {
  local feature_name="$1" current_branch
  ensure_git_repo
  current_branch=$(git branch --show-current)
  if [[ "${current_branch}" != "main" && "${current_branch}" != "master" && "${current_branch}" != "${feature_name}" ]]; then
    error_exit "Current branch '${current_branch}' is not main/master or '${feature_name}'"
  fi
  echo "${current_branch}"
}

create_feature_branch() {
  local current_branch="$1" feature_name="$2"
  if [[ "${current_branch}" == "main" || "${current_branch}" == "master" ]]; then
    log "Creating new branch: ${feature_name}"
    git checkout -b "${feature_name}" >/dev/null 2>&1 || error_exit "Failed to create branch ${feature_name}"
    return 0
  fi
  return 1
}

########################################
# Template wrapper (skip overwrite default)
########################################
copy_templates_wrapper() {
  local feature_dir="$1"
  shift
  local templates=("$@")
  copy_templates "${feature_dir}" skip "${templates[@]}"
}

########################################
# Output helpers
########################################
output_results_create() {
  local feature_name="$1" feature_dir="$2" branch_created="$3" current_branch="$4" issue_number="$5" title="$6" requirement="$7" output_json_flag="$8"
  shift 8
  local copied_files=("$@")

  if [[ "${output_json_flag}" == "true" ]]; then
    local files_json="[]"
    if (( ${#copied_files[@]:-0} > 0 )); then
      files_json=$(printf '"%s",' "${copied_files[@]}")
      files_json="[${files_json%,}]"
    fi
    cat <<EOF
{
  "MODE": "create",
  "BRANCH_NAME": "${current_branch}",
  "FEATURE_FOLDER": "${feature_dir}",
  "ISSUE_NUMBER": "${issue_number}",
  "TITLE": "${title}",
  "REQUIREMENT": "${requirement}",
  "COPIED_TEMPLATES": ${files_json}
}
EOF
    return 0
  fi

  echo "✅ Feature created successfully!"; echo
  echo "📁 Feature Details:"; echo "   Name: ${feature_name}"; echo "   Directory: ${feature_dir}"; echo "   Title: ${title}"; echo "   Requirement: ${requirement}"; echo
  echo "🐙 GitHub Issue:"; echo "   Issue #${issue_number}"; echo "   URL: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\)\.git.*/\1/')/issues/${issue_number}"; echo
  echo "🌿 Git Branch:"; echo "   Current branch: ${current_branch}"; if [[ "${branch_created}" == "true" ]]; then echo "   ✅ Created new branch: ${feature_name}"; else echo "   ℹ️  Using existing branch"; fi; echo
  if (( ${#copied_files[@]:-0} > 0 )); then
    echo "📄 Copied Templates:"; for f in "${copied_files[@]}"; do echo "   ✅ ${f}"; done
  else
    echo "📄 No templates copied (use --template flag to copy templates)"
  fi; echo
  echo "🔧 Environment Variables:"; echo "   BRANCH_NAME=${current_branch}"; echo "   FEATURE_FOLDER=${feature_dir}"; echo "   ISSUE_NUMBER=${issue_number}";
}

output_results_update() {
  local feature_name="$1" feature_dir="$2" feature_id="$3" issue_number="$4" output_json_flag="$5"
  shift 5
  local copied_files=("$@")
  local current_branch
  current_branch=$(git branch --show-current)

  if [[ "${output_json_flag}" == "true" ]]; then
    local files_json="[]"
    if (( ${#copied_files[@]:-0} > 0 )); then
      files_json=$(printf '"%s",' "${copied_files[@]}")
      files_json="[${files_json%,}]"
    fi
    cat <<EOF
{
  "MODE": "update",
  "BRANCH_NAME": "${current_branch}",
  "FEATURE_FOLDER": "${feature_dir}",
  "FEATURE_ID": "${feature_id}",
  "ISSUE_NUMBER": "${issue_number}",
  "COPIED_TEMPLATES": ${files_json}
}
EOF
    return 0
  fi

  echo "✅ Feature updated successfully!"; echo
  echo "📁 Feature Details:"; echo "   Name: ${feature_name}"; echo "   Directory: ${feature_dir}"; echo "   Feature ID: ${feature_id}"; echo
  echo "🐙 GitHub Issue:"; echo "   Issue #${issue_number}"; echo "   URL: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\)\.git.*/\1/')/issues/${issue_number}"; echo
  echo "🌿 Git Branch:"; echo "   Current branch: ${current_branch}"; echo "   (Switched to existing branch)"; echo
  if (( ${#copied_files[@]:-0} > 0 )); then
    echo "📄 Copied Templates:"; for f in "${copied_files[@]}"; do echo "   ✅ ${f}"; done
  else
    echo "📄 No templates copied (use --template flag to copy templates)"; fi; echo
  echo "🔧 Environment Variables:"; echo "   BRANCH_NAME=${current_branch}"; echo "   FEATURE_FOLDER=${feature_dir}"; echo "   ISSUE_NUMBER=${issue_number}";
}


########################################
# Template copying
# Usage: copy_templates <feature_dir> <mode> <template1> <template2> ...
#   mode: overwrite | skip
# Outputs copied filenames (one per line) to stdout for capture via mapfile.
########################################
copy_templates() {
  local feature_dir="$1" mode="$2"
  shift 2
  local templates=("$@")
  local copied_files=()

  local want_overwrite=false
  if [[ "${mode}" == "overwrite" ]]; then
    want_overwrite=true
  fi

  do_copy_template() {
    local template_name="$1"
    local src_file dest_file
    
    # Map short names to full filenames
    case "$template_name" in
      "raw-design"|"raw")
        src_file="${TEMPLATES_DIR}/raw-design.md"
        dest_file="raw-design.md"
        ;;
      "high-level-design"|"hld")
        src_file="${TEMPLATES_DIR}/high-level-design.md"
        dest_file="high-level-design.md"
        ;;
      "low-level-design"|"lld")
        src_file="${TEMPLATES_DIR}/low-level-design.md"
        dest_file="low-level-design.md"
        ;;
      "game-design"|"game")
        src_file="${TEMPLATES_DIR}/game-design.md"
        dest_file="game-design.md"
        ;;
      *)
        # Try exact filename match
        src_file="${TEMPLATES_DIR}/${template_name}"
        dest_file="$(basename "$template_name")"
        ;;
    esac
    
    local dest_path="${feature_dir}/${dest_file}"

    if [[ ! -f "${src_file}" ]]; then
      error_exit "Template file '${template_name}' not found. Available: raw-design, high-level-design, low-level-design, game-design"
    fi

    if [[ -f "${dest_path}" && "${want_overwrite}" == "false" ]]; then
      log "ℹ️  ${dest_file} already exists; skipping"
      return 0
    fi

    cp "${src_file}" "${dest_path}"
    copied_files+=("${dest_file}")
  }

  # Copy each requested template
  for template in "${templates[@]}"; do
    do_copy_template "$template"
  done

  # Safely print only if any copied (avoid unbound issues under older bash with set -u)
  if (( ${#copied_files[@]:-0} > 0 )); then
    printf '%s\n' "${copied_files[@]}"
  fi
}
