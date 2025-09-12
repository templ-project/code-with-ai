#!/bin/bash

# Create New Feature Script
# Follows Google Bash Style Guide: https://google.github.io/styleguide/shellguide.html

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly SPECS_DIR="${REPO_ROOT}/.specs"
readonly TEMPLATES_DIR="${REPO_ROOT}/.cwai/templates"

# Source common helpers
source "${SCRIPT_DIR}/common.sh"

# Default values / flags
output_json=false
requirement=""
use_raw=false
use_hld=false
use_lld=false

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <requirement> [OPTIONS]

Required arguments:
    <requirement>           Feature requirement description (first 5 words build the title)

Optional arguments:
  --json                  Output data as JSON instead of text
  --raw                   Copy raw-design.md template
  --hld                   Copy high-level-design.md template
  --lld                   Copy low-level-design.md template

Examples:
    $0 "Users need to login securely" --hld
    $0 "00012-user-authentication Add MFA support" --lld --json
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            output_json=true
            shift
            ;;
        --raw)
            use_raw=true
            shift
            ;;
        --hld)
            use_hld=true
            shift
            ;;
        --lld)
            use_lld=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            error_exit "Unknown option: $1. Use --help for usage information."
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
    error_exit "Requirement is required. Provide the requirement as arguments."
fi

# Validate that at least one template option is provided
if [[ "${use_raw}" == "false" && "${use_hld}" == "false" && "${use_lld}" == "false" ]]; then
    log "⚠️  Warning: No template options specified (--raw, --hld, --lld). Only creating directory structure."
fi

# Main execution
create_new_feature() {
    local req="$1" id slug feature_name feature_dir current_branch branch_created copied_files=()
    local title
    title=$(requirement_to_title "${req}")
    id=$(get_next_feature_id)
    slug=$(title_to_slug "${title}")
    feature_name="${id}-${slug}"
    feature_dir="${SPECS_DIR}/${feature_name}"

    log "🚀 Creating feature: ${feature_name}"
    current_branch=$(check_current_branch "${feature_name}")
    branch_created=false
    if create_feature_branch "${current_branch}" "${feature_name}"; then
        branch_created=true
        current_branch="${feature_name}"
    fi

    mkdir -p "${feature_dir}"
    log "📁 Directory ensured: ${feature_dir}"

    while IFS= read -r __line || [[ -n "${__line}" ]]; do
        [[ -n "${__line}" ]] && copied_files+=("${__line}")
    done < <(copy_templates_wrapper "${feature_dir}" "${use_raw}" "${use_hld}" "${use_lld}" || true)

    save_feature_id "${id#0*}"
    if (( ${#copied_files[@]:-0} > 0 )); then
        output_results_create "${feature_name}" "${feature_dir}" "${branch_created}" "${current_branch}" "${id}" "${title}" "${req}" "${output_json}" "${copied_files[@]}"
    else
        output_results_create "${feature_name}" "${feature_dir}" "${branch_created}" "${current_branch}" "${id}" "${title}" "${req}" "${output_json}"
    fi
}

update_existing_feature() {
    local feature_branch="$1"
    assert_clean_repo
    if ! git_branch_exists "${feature_branch}"; then
        error_exit "Branch '${feature_branch}' does not exist"
    fi
    local feature_dir="${SPECS_DIR}/${feature_branch}"
    if [[ ! -d "${feature_dir}" ]]; then
        error_exit "Feature directory '${feature_dir}' not found"
    fi
    log "� Switching to existing feature branch: ${feature_branch}"
    git_checkout_existing_or_remote "${feature_branch}"
    local feature_id
    feature_id=$(extract_feature_id "${feature_branch}")
    local copied=()
    while IFS= read -r __line || [[ -n "${__line}" ]]; do
        [[ -n "${__line}" ]] && copied+=("${__line}")
    done < <(copy_templates_wrapper "${feature_dir}" "${use_raw}" "${use_hld}" "${use_lld}" || true)
    if (( ${#copied[@]:-0} > 0 )); then
        output_results_update "${feature_branch}" "${feature_dir}" "${feature_id}" "${output_json}" "${copied[@]}"
    else
        output_results_update "${feature_branch}" "${feature_dir}" "${feature_id}" "${output_json}"
    fi
}

main() {
    local detected
    detected=$(detect_feature_branch_from_requirement "${requirement}")
    if [[ -n "${detected}" ]]; then
        log "Detected existing feature reference: ${detected}"
        update_existing_feature "${detected}"
    else
        log "No existing feature reference found; creating new feature"
        create_new_feature "${requirement}"
    fi
}

# Run main function
main
