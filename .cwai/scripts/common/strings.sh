#!/bin/bash

# Prevent multiple sourcing
[[ -n "${_STRINGS_SH_SOURCED:-}" ]] && return 0
readonly _STRINGS_SH_SOURCED=1

# Extract feature ID from string (00123-name -> 123)
extract_feature_id() {
  local name="$1"
  local feature_id=$(echo "${name}" | grep -o '^[0-9]\{5\}' || echo "0")
  feature_id=$(echo "$feature_id" | sed 's/^0*//')
  [ -n "$feature_id" ] && echo "$feature_id" || echo "0"
}

# Get first 5 words from requirement as title
requirement_to_title() {
  local requirement="$1"
  echo "$requirement" |
    tr '\n' ' ' |
    sed 's/[^A-Za-z0-9_-]/ /g' |
    awk '{ for(i=1;i<=NF && i<=5;i++){ printf("%s ", $i) } }' | sed 's/ *$//'
}

# Convert title to URL-friendly slug
title_to_slug() {
  local title="$1"
  echo "$title" | tr '[:upper:]' '[:lower:]' |
    sed 's/[^a-z0-9]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-\|-$//g'
}

padded_feature_id() {
  printf "%05d" "$1"
}

# Output JSON or key=value format
output_results() {
  local json_result="$1" output_json_flag="$2"

  if [ "$output_json_flag" = "true" ]; then
    echo "$json_result"
  else
    echo "$json_result" |
      jq -r 'to_entries[] | "\(.key)=\"\(if (.value | type) == "array" then (.value | join(",")) else .value end)\""'
  fi
}

# Find feature branch pattern in text, return if exists
requirement_to_feature_branch() {
  local requirement="$1"
  local feature_branch
  feature_branch=$(echo "$requirement" | grep -oE '([0-9]{5}-[a-z0-9][a-z0-9-]*)' | head -n 1 || true)

  if [[ -n "$feature_branch" ]] && command -v git_branch_exists >/dev/null 2>&1; then
    if git_branch_exists "$feature_branch"; then
      echo "$feature_branch"
      return 0
    fi
  fi

  echo ""
}

# Generate random hex color (returns 6-char hex without #)
generate_hex_color() {
  # Try to generate random hex color using /dev/urandom
  if command -v od >/dev/null 2>&1; then
    # Generate 3 bytes (RGB) and convert to hex
    local hex_color
    hex_color=$(od -An -N3 -tx1 /dev/urandom 2>/dev/null | tr -d ' ' | tr '[:lower:]' '[:upper:]')

    # Ensure we got exactly 6 characters
    if [[ ${#hex_color} -eq 6 ]]; then
      echo "$hex_color"
      return 0
    fi
  fi

  # Fallback: use RANDOM variable if available
  if [[ -n "${RANDOM:-}" ]]; then
    printf "%06X" $((RANDOM * RANDOM % 16777216))
    return 0
  fi

  # Final fallback: return default blue color
  echo "1F77B4"
}

