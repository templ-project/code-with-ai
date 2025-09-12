#!/bin/bash

# Create New Feature Script
# Follows Google Bash Style Guide: https://google.github.io/styleguide/shellguide.html

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly SPECS_DIR="${REPO_ROOT}/.specs"
readonly TEMPLATES_DIR="${REPO_ROOT}/.cwai/templates"
readonly COUNTER_FILE="${REPO_ROOT}/.specs/.feature_counter"

# Default values
output_json=false
title=""
requirement=""
use_raw=false
use_hld=false
use_lld=false

# Function to display usage
usage() {
    cat << EOF
Usage: $0 --title <title> --requirement <requirement> [OPTIONS]

Required arguments:
  --title <title>         Feature title
  --requirement <req>     Feature requirement description

Optional arguments:
  --json                  Output data as JSON instead of text
  --raw                   Copy raw-design.md template
  --hld                   Copy high-level-design.md template
  --lld                   Copy low-level-design.md template

Examples:
  $0 --title "User Authentication" --requirement "Users need to login" --hld
  $0 --title "Game Design" --requirement "Design game mechanics" --raw --json
EOF
}

# Function to log messages
log() {
    if [[ "${output_json}" == "false" ]]; then
        echo "$@" >&2
    fi
}

# Function to log errors and exit
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to convert title to snake case
title_to_snake_case() {
    local title="$1"
    echo "${title}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g'
}

# Function to extract ID from feature name
extract_feature_id() {
    local name="$1"
    echo "${name}" | grep -o '^[0-9]\{5\}' || echo "0"
}

# Function to get highest existing feature ID
get_highest_existing_id() {
    local max_id=0
    local current_id

    # Check existing feature folders
    if [[ -d "${SPECS_DIR}" ]]; then
        for folder in "${SPECS_DIR}"/[0-9][0-9][0-9][0-9][0-9]-*; do
            if [[ -d "${folder}" ]]; then
                current_id=$(extract_feature_id "$(basename "${folder}")")
                if [[ "${current_id}" -gt "${max_id}" ]]; then
                    max_id="${current_id}"
                fi
            fi
        done
    fi

    # Check existing feature branches (if we're in a git repo)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        while IFS= read -r branch; do
            # Remove leading spaces and asterisk from git branch output
            branch=$(echo "${branch}" | sed 's/^[* ]\+//')
            current_id=$(extract_feature_id "${branch}")
            if [[ "${current_id}" -gt "${max_id}" ]]; then
                max_id="${current_id}"
            fi
        done < <(git branch --all | grep -E '[0-9]{5}-' || true)
    fi

    echo "${max_id}"
}

# Function to get next feature ID
get_next_feature_id() {
    local counter=1
    local highest_existing max_from_counter

    # Get counter from file
    if [[ -f "${COUNTER_FILE}" ]]; then
        max_from_counter=$(cat "${COUNTER_FILE}")
        if [[ "${max_from_counter}" -gt 0 ]]; then
            counter=$((max_from_counter + 1))
        fi
    fi

    # Get highest existing ID from folders and branches
    highest_existing=$(get_highest_existing_id)

    # Use the maximum of counter and highest_existing + 1
    if [[ "${highest_existing}" -ge "${counter}" ]]; then
        counter=$((highest_existing + 1))
        log "⚠️  Found existing feature with ID ${highest_existing}, using ID ${counter} instead"
    fi

    printf "%05d" "${counter}"
}

# Function to save feature ID
save_feature_id() {
    local id="$1"
    mkdir -p "$(dirname "${COUNTER_FILE}")"
    echo "${id}" > "${COUNTER_FILE}"
}

# Function to check current branch
check_current_branch() {
    local current_branch feature_name="$1"

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        error_exit "Not in a git repository"
    fi

    current_branch=$(git branch --show-current)

    # Check if we're in main/master or the feature branch
    if [[ "${current_branch}" != "main" && "${current_branch}" != "master" && "${current_branch}" != "${feature_name}" ]]; then
        error_exit "Current branch '${current_branch}' is not main/master or '${feature_name}'"
    fi

    echo "${current_branch}"
}

# Function to create feature branch if needed
create_feature_branch() {
    local current_branch="$1" feature_name="$2"

    if [[ "${current_branch}" == "main" || "${current_branch}" == "master" ]]; then
        log "Creating new branch: ${feature_name}"
        git checkout -b "${feature_name}"
        return 0
    fi

    return 1
}

# Function to copy template files
copy_templates() {
    local feature_dir="$1"
    local copied_files=()

    if [[ "${use_raw}" == "true" ]]; then
        if [[ -f "${TEMPLATES_DIR}/raw-design.md" ]]; then
            cp "${TEMPLATES_DIR}/raw-design.md" "${feature_dir}/"
            copied_files+=("raw-design.md")
        else
            error_exit "Template file raw-design.md not found in ${TEMPLATES_DIR}"
        fi
    fi

    if [[ "${use_hld}" == "true" ]]; then
        if [[ -f "${TEMPLATES_DIR}/high-level-design.md" ]]; then
            cp "${TEMPLATES_DIR}/high-level-design.md" "${feature_dir}/"
            copied_files+=("high-level-design.md")
        else
            error_exit "Template file high-level-design.md not found in ${TEMPLATES_DIR}"
        fi
    fi

    if [[ "${use_lld}" == "true" ]]; then
        if [[ -f "${TEMPLATES_DIR}/low-level-design.md" ]]; then
            cp "${TEMPLATES_DIR}/low-level-design.md" "${feature_dir}/"
            copied_files+=("low-level-design.md")
        else
            error_exit "Template file low-level-design.md not found in ${TEMPLATES_DIR}"
        fi
    fi

    printf '%s\n' "${copied_files[@]}"
}

# Function to output results
output_results() {
    local feature_name="$1" feature_dir="$2" branch_created="$3" current_branch="$4" feature_id="$5"
    shift 5
    local copied_files=("$@")

    if [[ "${output_json}" == "true" ]]; then
        local files_json=""
        if [[ ${#copied_files[@]} -gt 0 ]]; then
            files_json=$(printf '"%s",' "${copied_files[@]}")
            files_json="[${files_json%,}]"
        else
            files_json="[]"
        fi

        cat << EOF
{
  "BRANCH_NAME": "${current_branch}",
  "FEATURE_FOLDER": "${feature_dir}",
  "FEATURE_ID": "${feature_id}"
}
EOF
    else
        echo "✅ Feature created successfully!"
        echo ""
        echo "📁 Feature Details:"
        echo "   Name: ${feature_name}"
        echo "   Directory: ${feature_dir}"
        echo "   Title: ${title}"
        echo "   Requirement: ${requirement}"
        echo ""
        echo "🌿 Git Branch:"
        echo "   Current branch: ${current_branch}"
        if [[ "${branch_created}" == "true" ]]; then
            echo "   ✅ Created new branch: ${feature_name}"
        else
            echo "   ℹ️  Using existing branch"
        fi
        echo ""
        if [[ ${#copied_files[@]} -gt 0 ]]; then
            echo "📄 Copied Templates:"
            for file in "${copied_files[@]}"; do
                echo "   ✅ ${file}"
            done
        else
            echo "📄 No templates copied (use --raw, --hld, or --lld flags)"
        fi
        echo ""
        echo "🔧 Environment Variables:"
        echo "   BRANCH_NAME=${current_branch}"
        echo "   FEATURE_FOLDER=${feature_dir}"
        echo "   FEATURE_ID=${feature_id}"
    fi
}

# Parse command line arguments
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
        --requirement)
            requirement="$2"
            shift 2
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
        *)
            error_exit "Unknown option: $1. Use --help for usage information."
            ;;
    esac
done

# Validate required arguments
if [[ -z "${title}" ]]; then
    error_exit "Title is required. Use --title <title>"
fi

if [[ -z "${requirement}" ]]; then
    error_exit "Requirement is required. Use --requirement <requirement>"
fi

# Validate that at least one template option is provided
if [[ "${use_raw}" == "false" && "${use_hld}" == "false" && "${use_lld}" == "false" ]]; then
    log "⚠️  Warning: No template options specified (--raw, --hld, --lld). Only creating directory structure."
fi

# Main execution
main() {
    local feature_id snake_case_title feature_name feature_dir current_branch branch_created copied_files

    # Generate feature ID and name
    feature_id=$(get_next_feature_id)
    snake_case_title=$(title_to_snake_case "${title}")
    feature_name="${feature_id}-${snake_case_title}"
    feature_dir="${SPECS_DIR}/${feature_name}"

    log "🚀 Creating feature: ${feature_name}"

    # Check current branch
    current_branch=$(check_current_branch "${feature_name}")
    log "📍 Current branch: ${current_branch}"

    # Create feature branch if needed
    branch_created=false
    if create_feature_branch "${current_branch}" "${feature_name}"; then
        branch_created=true
        current_branch="${feature_name}"
    fi

    # Create feature directory
    mkdir -p "${feature_dir}"
    log "📁 Created directory: ${feature_dir}"

    # Copy template files
    mapfile -t copied_files < <(copy_templates "${feature_dir}")

    # Save the feature ID for next time
    save_feature_id "${feature_id#0*}" # Remove leading zeros for storage

    # Output results
    output_results "${feature_name}" "${feature_dir}" "${branch_created}" "${current_branch}" "${feature_id}" "${copied_files[@]}"
}

# Run main function
main
