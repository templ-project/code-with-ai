#!/usr/bin/env bash

# Create New Feature Script

set -euo pipefail

# Require bash v4+
if [[ -z "${BASH_VERSINFO:-}" || ${BASH_VERSINFO[0]} -lt 4 ]]; then
  echo "ERROR: Bash 4 or later is required to run this script." >&2
  exit 1
fi

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

#########################################
## Output helpers
#########################################
output_feature_results() {
  local feature_name="$1"
  local feature_dir="$2"
  local current_branch="$3"
  local feature_id="$4"
  local title="$5"
  local requirement_text="$6"
  local output_json_flag="$7"
  local copied_files_csv="$8"

  local json_output
  json_output=$(jq -n \
    --arg branch "$current_branch" \
    --arg dir "$feature_dir" \
    --arg id "$feature_id" \
    --arg feature_title "$title" \
    --arg requirement "$requirement_text" \
    --arg copied "$copied_files_csv" \
    '{
      BRANCH_NAME: $branch,
      FEATURE_FOLDER: $dir,
      feature_id: $id,
      TITLE: $feature_title,
      REQUIREMENT: $requirement,
      COPIED_TEMPLATES: (if $copied == "" then [] else ($copied | split(",") | map(select(length > 0))) end)
    }')

  output_results "$json_output" "$output_json_flag"
}

#########################################
## Template helpers
#########################################
# TODO: simplify the function based on the todo comments inside; all templates will be found under `.cwai/templates`
copy_templates() {
  local feature_dir="$1"
  local templates_csv="$2"

  local copied_files=()

  if [[ -z "$templates_csv" ]]; then
    log_info "ℹ️  No templates specified. Only creating directory structure."
    echo ""
    return
  fi

  local template
  local IFS=','
  read -r -a template_list <<<"$templates_csv"

  for template in "${template_list[@]}"; do
    local trimmed_template="$template"
    trimmed_template="${trimmed_template#${trimmed_template%%[![:space:]]*}}"
    trimmed_template="${trimmed_template%${trimmed_template##*[![:space:]]}}"
    template="$trimmed_template"
    [[ -z "$template" ]] && continue

    local source_path="${TEMPLATES_DIR}/${template}"
    if [[ ! -f "$source_path" ]]; then
      [[ "$template" == *.md ]] || source_path="${TEMPLATES_DIR}/${template}.md"
    fi

    if [[ ! -f "$source_path" ]]; then
      log_warn "Template '${template}' not found in ${TEMPLATES_DIR}"
      continue
    fi

    mkdir -p "$feature_dir"
    local destination="$feature_dir/$(basename "$source_path")"

    if [[ -e "$destination" ]]; then
      log_warn "Template '$(basename "$destination")' already exists in ${feature_dir}; skipping"
      continue
    fi

    if cp "$source_path" "$destination"; then
      copied_files+=("$(basename "$destination")")
      log_info "📄 Copied template: $(basename "$source_path")"
    else
      log_warn "Failed to copy template '${template}'"
    fi
  done

  if [[ ${#copied_files[@]} -eq 0 ]]; then
    echo ""
    return
  fi

  local IFS=','
  echo "${copied_files[*]}"
}

# Main execution
create_new_feature() {
  local feature_templates="${1:-}"
  local feature_labels="${2:-}"
  local feature_title="${3:-}"
  local feature_body="${4:-Unknown task requirement}"
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

  local copied_files_csv=""
  copied_files_csv=$(copy_templates "${feature_dir}" "$feature_templates")

  output_feature_results "${feature_name}" "${feature_dir}" \
    "${feature_name}" "$feature_id" \
    "$feature_title" "$feature_body" "${output_json}" "$copied_files_csv"
}

update_existing_feature() {
  local feature_templates="${1:-}"
  local feature_labels="${2:-}"
  local feature_name="$3"
  local feature_comment="${4:-}"
  local feature_id feature_padded_id feature_name feature_title feature_slug feature_parent_dir feature_dir

  feature_id=$(extract_feature_id "$feature_name")
  feature_padded_id=$(padd_feature_id "$feature_id")
  feature_slug=${feature_name/$feature_padded_id-/}
  feature_parent_dir="$REPO_ROOT/$CWAI_SPECS_FOLDER"
  feature_dir="$feature_parent_dir/$feature_name"

  if [[ ! -d "${feature_dir}" ]]; then
    log_error "Feature directory '${feature_dir}' not found"
  fi

  git checkout "${feature_name}" >/dev/null 2>&1 || log_error "Failed to switch to branch ${feature_name}"

  if [[ -z "$feature_id" || "$feature_id" == "0" ]]; then
    log_error "Could not determine issue from branch '${feature_name}'"
  fi

  "${CWAI_ISSUE_MANAGER}_update_issue" "$feature_id" "$feature_name" "$feature_dir" "$feature_labels" "$feature_comment"

  local copied_files_csv=""
  copied_files_csv=$(copy_templates "${feature_dir}" "$feature_templates")

  if [[ -z "$feature_title" && -f "${feature_dir}/issue.json" ]]; then
    feature_title=$(jq -r '.title // empty' <"${feature_dir}/issue.json")
  fi
  [[ -z "$feature_title" ]] && feature_title="$feature_name"

  output_feature_results "${feature_name}" "${feature_dir}" \
    "${feature_name}" "$feature_id" \
    "$feature_title" "$feature_comment" "${output_json}" "$copied_files_csv"
}

main() {
  local feature_name="$(detect_feature_name "${requirement}")"
  local templates_csv="$([ "${#templates[@]}" -gt 0 ] && join_by_comma "${templates[@]}" || echo "")"

  if [[ -n "${feature_name}" ]]; then
    log_info "Detected existing feature reference: ${feature_name}"
    update_existing_feature "$templates_csv" "$labels" "${feature_name}" "${requirement}"
  else
    log_info "No existing feature reference found; creating new feature"
    create_new_feature "$templates_csv" "$labels" "$title" "${requirement}"
  fi
}

# Run main function
main
