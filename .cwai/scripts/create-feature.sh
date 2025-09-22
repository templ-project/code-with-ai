#!/bin/bash

# Create New Feature Script
# Follows Google Bash Style Guide: https://google.github.io/styleguide/shellguide.html

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly TEMPLATES_DIR="${REPO_ROOT}/.cwai/templates"

source "${SCRIPT_DIR}/common.sh"

load_environment "$REPO_ROOT"

# Default values / flags
output_json=false
requirement=""
templates=()
labels=""
title=""

# Function to display usage
usage() {
  cat <<EOF
Usage: $0 <requirement> [OPTIONS]

Required arguments:
    <requirement>           Feature requirement description

Optional arguments:
  --json                  Output data as JSON instead of text
  --title <title>         Explicit title for the feature (auto-generated from requirement if not provided)
  --template|-t <name>    Template to copy (can be used multiple times)
                          Available: raw-design (raw), high-level-design (hld), low-level-design (lld), game-design (game)
  --labels|-l <label>     Label to add to GitHub issue (comma separated)
                          Use -<label> to remove a label (e.g., -development)

Examples:
    $0 "Users need to login securely" --template high-level-design --label authentication --label security
    $0 "00012-user-authentication Add MFA support" --template low-level-design --label -development --json
    $0 "Add user dashboard" --title "User Dashboard Feature" --template raw-design --template game-design
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
  --json)
    output_json=true
    shift
    ;;
  --title)
    title="$2"
    shift 2
    ;;
  --template | -t)
    templates+=("$2")
    shift 2
    ;;
  --labels | -l)
    labels="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    log_error "Unknown option: $1. Use --help for usage information."
    ;;
  *)
    if [[ -n "$requirement" ]]; then
      requirement="$requirement $1"
    else
      requirement="$1"
    fi
    shift
    ;;
  esac
done

# Validate required arguments
if [[ -z "${requirement}" ]]; then
  log_error "Requirement is required. Provide the requirement as arguments."
fi

# #########################################
# ## Output helpers
# #########################################
# output_feature_results() {
#   local feature_name="$1" feature_dir="$2" current_branch="$3" feature_id="$4" title="$5" requirement="$6" output_json_flag="$7" copied_files="$8"

#   copied_files=${copied_files%,} # Remove trailing comma if any

#   local output="{
#  \"BRANCH_NAME\": \"${current_branch}\",
#  \"FEATURE_FOLDER\": \"${feature_dir}\",
#  \"feature_id\": \"${feature_id}\",
#  \"TITLE\": \"${title}\",
#  \"REQUIREMENT\": \"${requirement}\",
#  \"COPIED_TEMPLATES\": [\"$(echo ${copied_files//,/\",\"})\"]
# }"

#   output_results "$output" "$output_json_flag"
# }

# #########################################
# ## Template helpers
# #########################################
# copy_templates() {
#   local feature_dir="$1"
#   local copied_files=""

#   if [[ ${#templates[@]} -gt 0 ]]; then
#     local template_file
#     while IFS= read -r template; do
#       template_file=$TEMPLATES_DIR/${template}-design.md
#       if [ -f "$template_file" ]; then
#         cp "$template_file" "$feature_dir/" &&
#           copied_files="${copied_files}${template}-design.md," &&
#           log_info "📄 Copied template: ${template}-design.md"
#       else
#         log_warn "Template '${template}' not found in ${TEMPLATES_DIR}"
#       fi
#     done < <(printf '%s\n' "${templates[@]}")
#   else
#     log_info "ℹ️  No templates specified. Only creating directory structure."
#   fi
#   echo "$copied_files"
# }

# Main execution
create_new_feature() {
  local feature_labels="$1"
  local feature_title="${2:-}"
  local feature_body="$3"
  local feature_id feature_padded_id feature_name feature_title feature_slug feature_parent_dir feature_dir

  # Determine title
  if [[ -z "$feature_title" ]]; then
    feature_title=$(requirement_to_title "$feature_body")
  fi

  feature_slug=$(title_to_slug "$feature_title")
  feature_parent_dir="$REPO_ROOT/$CWAI_SPECS_FOLDER"
  mkdir -p "$feature_parent_dir"

  # Create GitHub issue first to get the ID
  feature_id=$("${CWAI_ISSUE_MANAGER}_create_issue" "$feature_slug" "$feature_title" "$feature_parent_dir" "$feature_labels" "$feature_body")
  feature_padded_id=$(padd_feature_id "$feature_id")
  feature_name="$feature_padded_id-$feature_slug"
  feature_dir="$feature_parent_dir/$feature_name"
  log_info "🚀 Created feature: ${feature_name}"

  # Create and switch to feature branch
  git checkout -b "${feature_name}" >/dev/null 2>&1 || log_error "Failed to create branch ${feature_name}"
  log_info "Created new branch: ${feature_name}"

  # # Copy templates if specified
  # local copied_files_csv
  # copied_files_csv=$(copy_templates "${feature_dir}")
  #
  # # Output results
  # output_feature_results "${feature_name}" "${feature_dir}" \
  #   "${feature_name}" "$feature_id" \
  #   "$feature_title" "$req" "${output_json}" "$copied_files_csv"
}

update_existing_feature() {
  local feature_name="$1"
  local req="$2"
  local feature_id feature_padded_id feature_name feature_title feature_slug feature_parent_dir feature_dir

  feature_id=$(extract_feature_id "$feature_name")
  feature_padded_id=$(padd_feature_id "$feature_id")
  feature_slug=${feature_name/$feature_padded_id-/}
  feature_parent_dir="$REPO_ROOT/$CWAI_SPECS_FOLDER"
  feature_dir="$feature_parent_dir/$feature_name"

  if [[ ! -d "${feature_dir}" ]]; then
    log_error "Feature directory '${feature_dir}' not found"
  fi

  git checkout "${feature_name}" >/dev/null 2>&1 || log_error "Failed to switch to branch ${feature_branch}"

  if [[ -z "$feature_id" || "$feature_id" == "0" ]]; then
    log_error "Could not determine issue from branch '${feature_name}'"
  fi

  "${CWAI_ISSUE_MANAGER}_update_issue" "$feature_id" "$feature_name" "$feature_dir" "$req"

  #   # Copy templates if specified
  #   local copied_files_csv
  #   copied_files_csv=$(copy_templates "${feature_dir}")

  #   # Output results
  #   output_feature_results "${feature_branch}" "${feature_dir}" \
  #     "${feature_branch}" "$feature_id" \
  #     "$feature_title" "$requirement" "${output_json}" "$copied_files_csv"
}

main() {
  local feature_name
  feature_name=$(detect_feature_name "${requirement}")

  if [[ -n "${feature_name}" ]]; then
    log_info "Detected existing feature reference: ${feature_name}"
    update_existing_feature "${feature_name}" "${requirement}"
  else
    log_info "No existing feature reference found; creating new feature"
    create_new_feature "$labels" "$title" "${requirement}"
  fi
}

# Run main function
main
