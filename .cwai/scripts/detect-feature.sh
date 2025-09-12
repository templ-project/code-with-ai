#!/bin/bash

# Detect Existing Feature Script
# Mirrors behavior/flags of create-new-feature.sh for consistency.
# Follows Google Bash Style Guide: https://google.github.io/styleguide/shellguide.html

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly SPECS_DIR="${REPO_ROOT}/.specs"
readonly TEMPLATES_DIR="${REPO_ROOT}/.cwai/templates"

# Source common helpers
source "${SCRIPT_DIR}/common.sh"

# Flags / arguments
output_json=false
use_raw=false
use_hld=false
use_lld=false
feature_name=""

# Usage documentation
usage() {
  cat <<EOF
Usage: $0 --feature <feature-branch-name> [OPTIONS]

Detect & switch to an existing feature branch/folder created previously by create-new-feature.sh
and (optionally) copy missing template files.

Required arguments:
  --feature <name>       Feature branch / folder name (e.g. 00012-user-authentication)

Optional arguments:
  --json                 Output JSON (suppresses human log noise)
  --raw                  Copy raw-design.md template if present
  --hld                  Copy high-level-design.md template if present
  --lld                  Copy low-level-design.md template if present
  -h, --help             Show this help message

Behavior:
  1. Verifies repo is clean (no staged or unstaged changes) BEFORE switching.
  2. Validates the branch exists.
  3. Validates the .specs/<feature> folder exists.
  4. Checks out the branch.
  5. Optionally copies requested templates (does NOT overwrite existing files).
  6. Outputs a summary similar to create-new-feature.sh

Exit codes:
  0 Success
  1 Usage / validation error
EOF
}

copy_templates_wrapper() {
  local feature_dir="$1"
  copy_templates "${feature_dir}" skip "${use_raw}" "${use_hld}" "${use_lld}"
}

output_results() {
  local feature_name="$1" feature_dir="$2" feature_id="$3"
  shift 3
  local copied_files=("$@")
  local current_branch
  current_branch=$(git branch --show-current)

  if [[ "${output_json}" == "true" ]]; then
    local files_json="[]"
    if [[ ${#copied_files[@]} -gt 0 ]]; then
      files_json=$(printf '"%s",' "${copied_files[@]}")
      files_json="[${files_json%,}]"
    fi
    cat <<EOF
{
  "BRANCH_NAME": "${current_branch}",
  "FEATURE_FOLDER": "${feature_dir}",
  "FEATURE_ID": "${feature_id}",
  "COPIED_TEMPLATES": ${files_json}
}
EOF
    return 0
  fi

  echo "✅ Feature detected successfully!"
  echo
  echo "📁 Feature Details:"
  echo "   Name: ${feature_name}"
  echo "   Directory: ${feature_dir}"
  echo "   Feature ID: ${feature_id}"
  echo
  echo "🌿 Git Branch:"
  echo "   Current branch: ${current_branch}"
  echo "   (Switched to existing branch)"
  echo
  if [[ ${#copied_files[@]} -gt 0 ]]; then
    echo "📄 Copied Templates:"
    for f in "${copied_files[@]}"; do
      echo "   ✅ ${f}"
    done
  else
    echo "📄 No templates copied (use --raw, --hld, --lld flags)"
  fi
  echo
  echo "🔧 Environment Variables:"
  echo "   BRANCH_NAME=${current_branch}"
  echo "   FEATURE_FOLDER=${feature_dir}"
  echo "   FEATURE_ID=${feature_id}"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature)
      feature_name="$2"; shift 2 ;;
    --json)
      output_json=true; shift ;;
    --raw)
      use_raw=true; shift ;;
    --hld)
      use_hld=true; shift ;;
    --lld)
      use_lld=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      error_exit "Unknown option: $1. Use --help for usage information." ;;
  esac
done

# Validate required
if [[ -z "${feature_name}" ]]; then
  error_exit "--feature <name> is required"
fi

main() {
  assert_clean_repo

  # Validate branch exists
  if ! git_branch_exists "${feature_name}"; then
    error_exit "Branch '${feature_name}' does not exist"
  fi

  local feature_dir="${SPECS_DIR}/${feature_name}"
  if [[ ! -d "${feature_dir}" ]]; then
    error_exit "Feature directory '${feature_dir}' not found"
  fi

  log "🔍 Switching to feature branch: ${feature_name}"
  git_checkout_existing_or_remote "${feature_name}"

  local feature_id
  feature_id=$(extract_feature_id "${feature_name}")

  # Copy templates if requested (portable for Bash 3.2)
  copied=()
  while IFS= read -r __line || [[ -n "${__line}" ]]; do
    [[ -n "${__line}" ]] && copied+=("${__line}")
  done < <(copy_templates_wrapper "${feature_dir}" || true)

  if (( ${#copied[@]:-0} > 0 )); then
    output_results "${feature_name}" "${feature_dir}" "${feature_id}" "${copied[@]}"
  else
    output_results "${feature_name}" "${feature_dir}" "${feature_id}" 
  fi
}

main "$@"
