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
  local counter=1 highest_existing max_from_counter
  local counter_file="${SPECS_DIR}/.feature_counter"

  if [[ -f "${counter_file}" ]]; then
    max_from_counter=$(cat "${counter_file}" 2>/dev/null || echo 0)
    if [[ "${max_from_counter}" -gt 0 ]]; then
      counter=$((max_from_counter + 1))
    fi
  fi

  highest_existing=$(get_highest_existing_id)
  if [[ "${highest_existing}" -ge "${counter}" ]]; then
    counter=$((highest_existing + 1))
  fi

  printf "%05d" "${counter}"
}

save_feature_id() {
  local id="$1" counter_file="${SPECS_DIR}/.feature_counter"
  mkdir -p "${SPECS_DIR}"
  echo "${id}" > "${counter_file}"
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
  local feature_dir="$1" use_raw="$2" use_hld="$3" use_lld="$4"
  copy_templates "${feature_dir}" skip "${use_raw}" "${use_hld}" "${use_lld}"
}

########################################
# Output helpers
########################################
output_results_create() {
  local feature_name="$1" feature_dir="$2" branch_created="$3" current_branch="$4" feature_id="$5" title="$6" requirement="$7" output_json_flag="$8"
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
  "FEATURE_ID": "${feature_id}",
  "TITLE": "${title}",
  "REQUIREMENT": "${requirement}",
  "COPIED_TEMPLATES": ${files_json}
}
EOF
    return 0
  fi

  echo "✅ Feature created successfully!"; echo
  echo "📁 Feature Details:"; echo "   Name: ${feature_name}"; echo "   Directory: ${feature_dir}"; echo "   Title: ${title}"; echo "   Requirement: ${requirement}"; echo
  echo "🌿 Git Branch:"; echo "   Current branch: ${current_branch}"; if [[ "${branch_created}" == "true" ]]; then echo "   ✅ Created new branch: ${feature_name}"; else echo "   ℹ️  Using existing branch"; fi; echo
  if (( ${#copied_files[@]:-0} > 0 )); then
    echo "📄 Copied Templates:"; for f in "${copied_files[@]}"; do echo "   ✅ ${f}"; done
  else
    echo "📄 No templates copied (use --raw, --hld, or --lld flags)"
  fi; echo
  echo "🔧 Environment Variables:"; echo "   BRANCH_NAME=${current_branch}"; echo "   FEATURE_FOLDER=${feature_dir}"; echo "   FEATURE_ID=${feature_id}";
}

output_results_update() {
  local feature_name="$1" feature_dir="$2" feature_id="$3" output_json_flag="$4"
  shift 4
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
  "COPIED_TEMPLATES": ${files_json}
}
EOF
    return 0
  fi

  echo "✅ Feature detected successfully!"; echo
  echo "📁 Feature Details:"; echo "   Name: ${feature_name}"; echo "   Directory: ${feature_dir}"; echo "   Feature ID: ${feature_id}"; echo
  echo "🌿 Git Branch:"; echo "   Current branch: ${current_branch}"; echo "   (Switched to existing branch)"; echo
  if (( ${#copied_files[@]:-0} > 0 )); then
    echo "📄 Copied Templates:"; for f in "${copied_files[@]}"; do echo "   ✅ ${f}"; done
  else
    echo "📄 No templates copied (use --raw, --hld, --lld flags)"; fi; echo
  echo "🔧 Environment Variables:"; echo "   BRANCH_NAME=${current_branch}"; echo "   FEATURE_FOLDER=${feature_dir}"; echo "   FEATURE_ID=${feature_id}";
}


########################################
# Template copying
# Usage: copy_templates <feature_dir> <mode> <use_raw> <use_hld> <use_lld>
#   mode: overwrite | skip
# Outputs copied filenames (one per line) to stdout for capture via mapfile.
########################################
copy_templates() {
  local feature_dir="$1" mode="$2" use_raw="$3" use_hld="$4" use_lld="$5"
  local copied_files=()

  local want_overwrite=false
  if [[ "${mode}" == "overwrite" ]]; then
    want_overwrite=true
  fi

  do_copy_template() {
    local src="$1" dest_name="$2"
    local dest_path="${feature_dir}/${dest_name}"

    if [[ ! -f "${src}" ]]; then
      error_exit "Template file ${dest_name} not found in ${TEMPLATES_DIR}"
    fi

    if [[ -f "${dest_path}" && "${want_overwrite}" == "false" ]]; then
      log "ℹ️  ${dest_name} already exists; skipping"
      return 0
    fi

    cp "${src}" "${dest_path}"
    copied_files+=("${dest_name}")
  }

  if [[ "${use_raw}" == "true" ]]; then
    do_copy_template "${TEMPLATES_DIR}/raw-design.md" "raw-design.md"
  fi
  if [[ "${use_hld}" == "true" ]]; then
    do_copy_template "${TEMPLATES_DIR}/high-level-design.md" "high-level-design.md"
  fi
  if [[ "${use_lld}" == "true" ]]; then
    do_copy_template "${TEMPLATES_DIR}/low-level-design.md" "low-level-design.md"
  fi

  # Safely print only if any copied (avoid unbound issues under older bash with set -u)
  if (( ${#copied_files[@]:-0} > 0 )); then
    printf '%s\n' "${copied_files[@]}"
  fi
}
