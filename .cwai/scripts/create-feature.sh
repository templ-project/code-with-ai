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

# shellcheck source=.cwai/scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

load_environment "$REPO_ROOT"

: "${CWAI_SPECS_FOLDER:?Environment variable CWAI_SPECS_FOLDER is required}"
: "${CWAI_ISSUE_MANAGER:?Environment variable CWAI_ISSUE_MANAGER is required}"

# Default values / flags
output_json=false
declare -a templates=()
declare -a label_entries=()
declare -a requirement_words=()
title=""
labels_csv=""
requirement=""

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

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        output_json=true
        shift
        ;;
      --title)
        if [[ $# -lt 2 ]]; then
          log_error "--title requires an argument"
        fi
        title="$2"
        shift 2
        ;;
      --template|-t)
        if [[ $# -lt 2 ]]; then
          log_error "--template requires a template name"
        fi
        templates+=("$2")
        shift 2
        ;;
      --labels|-l)
        if [[ $# -lt 2 ]]; then
          log_error "--labels requires a value"
        fi
        local -a parsed_labels=()
        IFS=',' read -r -a parsed_labels <<<"$2"
        local label_value
        local trimmed_label
        for label_value in "${parsed_labels[@]}"; do
          trimmed_label="$label_value"
          trimmed_label="${trimmed_label#"${trimmed_label%%[![:space:]]*}"}"
          trimmed_label="${trimmed_label%"${trimmed_label##*[![:space:]]}"}"
          if [[ -n "$trimmed_label" ]]; then
            label_entries+=("$trimmed_label")
          fi
        done
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        log_error "Unknown option: $1. Use --help for usage information."
        ;;
      *)
        requirement_words+=("$1")
        shift
        ;;
    esac
  done
}

parse_args "$@"

if ((${#requirement_words[@]} > 0)); then
  requirement="${requirement_words[*]}"
else
  requirement=""
fi

if ((${#label_entries[@]} > 0)); then
  labels_csv="$(join_by_comma "${label_entries[@]}")"
else
  labels_csv=""
fi

# Validate required arguments
if [[ -z "$requirement" ]]; then
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
  shift
  local -a requested_templates=("$@")
  local -a copied_files=()

  if ((${#requested_templates[@]} == 0)); then
    log_info "ℹ️  No templates specified. Only creating directory structure."
    printf '%s\n' ""
    return
  fi

  local template
  for template in "${requested_templates[@]}"; do
    local trimmed_template="$template"
    trimmed_template="${trimmed_template#"${trimmed_template%%[![:space:]]*}"}"
    trimmed_template="${trimmed_template%"${trimmed_template##*[![:space:]]}"}"
    if [[ -z "$trimmed_template" ]]; then
      continue
    fi

    local source_path="${TEMPLATES_DIR}/${trimmed_template}"
    if [[ ! -f "$source_path" && "$trimmed_template" != *.md ]]; then
      source_path="${TEMPLATES_DIR}/${trimmed_template}.md"
    fi

    if [[ ! -f "$source_path" ]]; then
      log_warn "Template '${trimmed_template}' not found in ${TEMPLATES_DIR}"
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
      log_warn "Failed to copy template '${trimmed_template}'"
    fi
  done

  if [[ ${#copied_files[@]} -eq 0 ]]; then
    printf '%s\n' ""
    return
  fi

  printf '%s\n' "$(join_by_comma "${copied_files[@]}")"
}

# Main execution
create_new_feature() {
  local feature_labels="$1"
  local explicit_title="$2"
  local feature_body="${3:-Unknown task requirement}"

  local feature_title="$explicit_title"
  if [[ -z "$feature_title" ]]; then
    feature_title=$(requirement_to_title "$feature_body")
  fi

  local feature_slug
  feature_slug=$(title_to_slug "$feature_title")
  local feature_parent_dir="$REPO_ROOT/$CWAI_SPECS_FOLDER"
  mkdir -p "$feature_parent_dir"

  local feature_id
  feature_id=$("${CWAI_ISSUE_MANAGER}_create_issue" "$feature_slug" "$feature_title" "$feature_parent_dir" "$feature_labels" "$feature_body")
  local feature_padded_id
  feature_padded_id=$(padd_feature_id "$feature_id")
  local feature_name="$feature_padded_id-$feature_slug"
  local feature_dir="$feature_parent_dir/$feature_name"
  log_info "🚀 Created feature: ${feature_name}"

  if ! git checkout -b "$feature_name" >/dev/null 2>&1; then
    log_error "Failed to create branch ${feature_name}"
  fi
  log_info "Created new branch: ${feature_name}"

  local copied_files_csv=""
  copied_files_csv=$(copy_templates "$feature_dir" "${templates[@]}")

  output_feature_results "$feature_name" "$feature_dir" \
    "$feature_name" "$feature_id" \
    "$feature_title" "$feature_body" "$output_json" "$copied_files_csv"
}

update_existing_feature() {
  local feature_labels="$1"
  local feature_name="$2"
  local feature_comment="${3:-}"

  local feature_id
  feature_id=$(extract_feature_id "$feature_name")
  local feature_padded_id
  feature_padded_id=$(padd_feature_id "$feature_id")
  local feature_parent_dir="$REPO_ROOT/$CWAI_SPECS_FOLDER"
  local feature_dir="$feature_parent_dir/$feature_name"

  if [[ ! -d "$feature_dir" ]]; then
    log_error "Feature directory '${feature_dir}' not found"
  fi

  if ! git checkout "$feature_name" >/dev/null 2>&1; then
    log_error "Failed to switch to branch ${feature_name}"
  fi

  if [[ -z "$feature_id" || "$feature_id" == "0" ]]; then
    log_error "Could not determine issue from branch '${feature_name}'"
  fi

  "${CWAI_ISSUE_MANAGER}_update_issue" "$feature_id" "$feature_name" "$feature_dir" "$feature_labels" "$feature_comment"

  local copied_files_csv=""
  copied_files_csv=$(copy_templates "$feature_dir" "${templates[@]}")

  local feature_title=""
  if [[ -f "$feature_dir/issue.json" ]]; then
    feature_title=$(jq -r '.title // empty' <"$feature_dir/issue.json")
  fi
  if [[ -z "$feature_title" ]]; then
    feature_title="$feature_name"
  fi

  output_feature_results "$feature_name" "$feature_dir" \
    "$feature_name" "$feature_id" \
    "$feature_title" "$feature_comment" "$output_json" "$copied_files_csv"
}

main() {
  local feature_name
  feature_name="$(detect_feature_name "$requirement")"

  if [[ -n "$feature_name" ]]; then
    log_info "Detected existing feature reference: ${feature_name}"
    update_existing_feature "$labels_csv" "$feature_name" "$requirement"
  else
    log_info "No existing feature reference found; creating new feature"
    create_new_feature "$labels_csv" "$title" "$requirement"
  fi
}

# Run main function
main
