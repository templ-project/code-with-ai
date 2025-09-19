#!/bin/bash

# Create New Feature Script
# Follows Google Bash Style Guide: https://google.github.io/styleguide/shellguide.html

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly SPECS_DIR="${REPO_ROOT}/.specs"
readonly TEMPLATES_DIR="${REPO_ROOT}/.cwai/templates"

# Source GitHub common helpers
source "${SCRIPT_DIR}/common/env.sh"

load_environment "$REPO_ROOT"

source "${SCRIPT_DIR}/common/log.sh"

ISSUE_MANAGER=${ISSUE_MANAGER:-github}

# Source common helpers
source "${SCRIPT_DIR}/common/strings.sh"
source "${SCRIPT_DIR}/common/git.sh"

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

#########################################
## Output helpers
#########################################
output_feature_results() {
  local feature_name="$1" feature_dir="$2" current_branch="$3" issue_number="$4" title="$5" requirement="$6" output_json_flag="$7" copied_files="$8"

  copied_files=${copied_files%,} # Remove trailing comma if any

  local output="{
 \"BRANCH_NAME\": \"${current_branch}\",
 \"FEATURE_FOLDER\": \"${feature_dir}\",
 \"ISSUE_NUMBER\": \"${issue_number}\",
 \"TITLE\": \"${title}\",
 \"REQUIREMENT\": \"${requirement}\",
 \"COPIED_TEMPLATES\": [\"$(echo ${copied_files//,/\",\"})\"]
}"

  output_results "$output" "$output_json_flag"
}

#########################################
## Template helpers
#########################################
copy_templates() {
  local feature_dir="$1"
  local -n copied_files_ref="$2"
  
  if [[ ${#templates[@]} -gt 0 ]]; then
    local template_file
    while IFS= read -r template; do
      template_file=$TEMPLATES_DIR/${template}-design.md
      [ -f "$template_file" ] && cp "$template_file" "$feature_dir/" &&
        copied_files_ref+=("${template}-design.md") &&
        log_info "📄 Copied template: ${template}-design.md" ||
        log_warn "Template '${template}' not found in ${TEMPLATES_DIR}"
    done < <(printf '%s\n' "${templates[@]}")
  else
    log_info "ℹ️  No templates specified. Only creating directory structure."
  fi
}

# Main execution
create_new_feature() {
  local req="$1"
  local feature_title feature_slug issue_number feature_name feature_dir copied_files=()

  # Determine title
  feature_title="$title"
  if [[ -z "$title" ]]; then
    feature_title=$(requirement_to_title "$req")
  fi

  # Create GitHub issue first to get the ID
  issue_number=$($SCRIPT_DIR/$ISSUE_MANAGER/create-issue.sh --title "$feature_title" --labels "$labels" --json "$req" | jq -r '.ISSUE_NUMBER // ""')

  # Validate issue creation succeeded
  if [[ -z "$issue_number" || "$issue_number" == "0" ]]; then
    log_error "Failed to create GitHub issue. Check your authentication and repository access."
  fi
  log_info "✅ Created GitHub issue #$issue_number"

  # Build feature identifiers using issue number
  feature_slug=$(title_to_slug "$feature_title")
  feature_name=$(printf "%05d" "$issue_number")-${feature_slug}
  feature_dir="${SPECS_DIR}/${feature_name}"
  log_info "🚀 Creating feature: ${feature_name}"

  # Create and switch to feature branch
  git checkout -b "${feature_name}" >/dev/null 2>&1 || log_error "Failed to create branch ${feature_name}"
  log_info "Created new branch: ${feature_name}"

  mkdir -p "${feature_dir}"
  log_info "📁 Directory ensured: ${feature_dir}"

  # Copy templates if specified
  copy_templates "${feature_dir}" copied_files

  # Output results
  output_feature_results "${feature_name}" "${feature_dir}" \
    "${feature_name}" "$issue_number" \
    "$feature_title" "$req" "${output_json}" "$(printf '%s,' "${copied_files[@]}")"
}

update_existing_feature() {
  local feature_branch="$1"
  local issue issue_number feature_dir copied_files=() feature_title

  assert_clean_repo
  if ! git_branch_exists "${feature_branch}"; then
    log_error "Branch '${feature_branch}' does not exist"
  fi

  feature_dir="${SPECS_DIR}/${feature_branch}"
  if [[ ! -d "${feature_dir}" ]]; then
    log_error "Feature directory '${feature_dir}' not found"
  fi

  git checkout "${feature_branch}" >/dev/null 2>&1 || log_error "Failed to switch to branch ${feature_branch}"

  # Extract issue number from branch name
  issue_number=$(extract_feature_id "${feature_branch}")
  issue_number=$(echo "$issue_number" | sed 's/^0*//')

  if [[ -z "$issue_number" || "$issue_number" == "0" ]]; then
    log_error "Could not determine GitHub issue number from branch '${feature_branch}'"
  fi

  # read the entire issue
  issue=$($SCRIPT_DIR/$ISSUE_MANAGER/read-issue.sh $issue_number)

  # Get title from GitHub issue
  feature_title=$(echo "$issue" | jq -r '.title // "Unknown Feature"')

  # Copy templates if specified
  copy_templates "${feature_dir}" copied_files

  # Output results
  output_feature_results "${feature_branch}" "${feature_dir}" \
    "${feature_branch}" "$issue_number" \
    "$feature_title" "$requirement" "${output_json}" "$(printf '%s,' "${copied_files[@]}")"
}

main() {
  local detected
  detected=$(requirement_to_feature_branch "${requirement}")
  if [[ -n "${detected}" ]]; then
    log_info "Detected existing feature reference: ${detected}"
    update_existing_feature "${detected}"
  else
    log_info "No existing feature reference found; creating new feature"
    create_new_feature "${requirement}"
  fi
}

# Run main function
main
