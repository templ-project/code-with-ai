# Prevent multiple sourcing
[[ -n "${_COMMON_SOURCED:-}" ]] && return 0
readonly _COMMON_SOURCED=1

#######################################
# Environment variable loader
#######################################

export CWAI_SPECS_FOLDER=${CWAI_SPECS_FOLDER:-specs}
export CWAI_ISSUE_MANAGER=${CWAI_ISSUE_MANAGER:-localfs}

# Load environment variables
load_environment() {
  local repo_root="$1"

  # Prevent multiple loading
  [[ -n "${_ENV_LOADED:-}" ]] && return 0
  readonly _ENV_LOADED=1

  # Fail loudly if no repo root provided
  [[ -z "$repo_root" ]] && {
    echo "ERROR: Repository root path is required" >&2
    exit 1
  }

  # Load .env first, then .env.local (local overrides global)
  for env_file in "${repo_root}/.env" "${repo_root}/.env.local"; do
    if [[ -f "$env_file" ]]; then
      log_info "Loading environment from: $env_file"
      set -a
      export $(grep -v '^#' "$env_file" | xargs)
      set +a
    fi
  done
}

#######################################
# Logging utilities with colored output
#######################################

# Colors
readonly LOG_COLOR_BLUE="\033[0;34m"
readonly LOG_COLOR_RED="\033[0;31m"
readonly LOG_COLOR_GREEN="\033[0;32m"
readonly LOG_COLOR_YELLOW="\033[0;33m"
readonly LOG_COLOR_RESET="\e[0m"
readonly LOG_PREFIX="λ"

log_debug() {
  [[ -n "${DEBUG:-}" ]] && printf "${LOG_COLOR_BLUE}${LOG_PREFIX} DEBUG %s${LOG_COLOR_RESET}\n" "$1" >&2
}

log_info() {
  printf "${LOG_COLOR_GREEN}${LOG_PREFIX} INFO %s${LOG_COLOR_RESET}\n" "$1" >&2
}

log_warn() {
  printf "${LOG_COLOR_YELLOW}${LOG_PREFIX} WARN %s${LOG_COLOR_RESET}\n" "$1" >&2
}

log_error() {
  printf "${LOG_COLOR_RED}${LOG_PREFIX} ERROR %s${LOG_COLOR_RESET}\n" "$1" >&2
  exit "${2:-1}"
}

#######################################
# Array utilities
#######################################

join_by_comma() {
  local IFS=','
  echo "$*"
}

concatenate_arrays() {
  local array1_string="$1"
  local array2_string="$2"

  # Declare associative arrays at the top
  declare -A remove_set
  declare -A seen_set

  # Convert to arrays
  IFS=',' read -r -a array1 <<<"$array1_string"
  IFS=',' read -r -a array2 <<<"$array2_string"

  # Build removal set
  for item in "${array2[@]}"; do
    if [[ "$item" == -* ]]; then
      remove_set["${item#-}"]=1
    fi
  done

  local outlist=()

  # Preserve order from array1 while respecting removals
  for item in "${array1[@]}"; do
    [[ -z "$item" ]] && continue
    if [[ -n "${remove_set[$item]+x}" || -n "${seen_set[$item]+x}" ]]; then
      continue
    fi
    seen_set["$item"]=1
    outlist+=("$item")
  done

  # Append new entries from array2 (excluding removals and negatives)
  for item in "${array2[@]}"; do
    [[ -z "$item" ]] && continue
    if [[ "$item" == -* || -n "${remove_set[$item]+x}" || -n "${seen_set[$item]+x}" ]]; then
      continue
    fi
    seen_set["$item"]=1
    outlist+=("$item")
  done

  IFS=','
  echo "${outlist[*]}"
}

#######################################
# String utilities
#######################################

split_by_comma() {
  local input="$1"
  local arr
  IFS=',' read -a arr <<<"$input"
  echo "${arr[@]}"
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

padd_feature_id() {
  printf "%05d" "$1"
}

# Find feature branch pattern in text, return if exists
detect_feature_name() {
  local req="$1"
  local feature_name
  feature_name=$(echo "$req" | grep -oE '([0-9]{5}-[a-z0-9][a-z0-9-]*)' | head -n 1 || true)

  if [[ -n "$feature_name" ]] && command -v git_branch_exists >/dev/null 2>&1; then
    if git_branch_exists "$feature_name"; then
      echo "$feature_name"
      return 0
    fi
  fi

  echo ""
}

# Extract feature ID from string (00123-name -> 123)
extract_feature_id() {
  local feature_name="$1"
  local feature_id=$(echo "${feature_name}" | grep -o '^[0-9]\{5\}' || echo "0")

  feature_id=$(echo "$feature_id" | sed 's/^0*//')

  [ -n "$feature_id" ] && echo "$feature_id" || echo "0"
}

# # Output JSON or key=value format
# output_results() {
#   local json_result="$1" output_json_flag="$2"
#
#   if [ "$output_json_flag" = "true" ]; then
#     echo "$json_result"
#   else
#     echo "$json_result" |
#       jq -r 'to_entries[] | "\(.key)=\"\(if (.value | type) == "array" then (.value | join(",")) else .value end)\""'
#   fi
# }

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

#######################################
# Git Functions
#######################################

# # Detects feature ID from current branch (00123-feature-name -> 123)
# detect_feature_id() {
#   if ! git rev-parse --git-dir >/dev/null 2>&1; then
#     return 1
#   fi
#
#   local current_branch
#   current_branch=$(git branch --show-current 2>/dev/null) || return 1
#
#   if [[ ! "$current_branch" =~ ^[0-9]{5}-[a-z0-9-]+ ]]; then
#     log_warn "No feature branch detected.."
#     return 1
#   fi
#
#   local feature_id
#   feature_id=$(extract_feature_id "$current_branch")
#
#   if [[ "$feature_id" != "0" ]]; then
#     echo "$feature_id" | sed 's/^0*//'
#   else
#     return 1
#   fi
# }
#
# # Ensure we're in a git repository (exits if not)
# ensure_git_repo() {
#   if ! git rev-parse --git-dir >/dev/null 2>&1; then
#     echo "ERROR: Not in a git repository" >&2
#     exit 1
#   fi
# }
#
# # Check working tree is clean (exits if dirty)
# assert_clean_repo() {
#   ensure_git_repo
#   if ! git diff --quiet || ! git diff --cached --quiet; then
#     echo "ERROR: Working tree has uncommitted changes. Commit or stash before proceeding." >&2
#     exit 1
#   fi
# }

# Check if branch exists (local or remote)
git_branch_exists() {
  local branch="$1"
  git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null 2>&1 ||
    git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1
}
#
# # Get current branch name
# get_current_branch() {
#   ensure_git_repo
#   git branch --show-current 2>/dev/null || return 1
# }
#
# # Get Github repo path (owner/repo)
# get_github_repo_path() {
#   ensure_git_repo
#   local remote_url
#   remote_url=$(git remote get-url origin 2>/dev/null) || return 1
#   echo "$remote_url" | sed 's/.*github.com[:/]\([^.]*\)\.git.*/\1/' || return 1
# }

#######################################
# LocalFs Issue Manager
#######################################

localfs_create_issue() {
  local feature_slug="$1"
  local feature_title="$2"
  local feature_parent_dir="$3"
  local feature_labels="$4"
  local feature_body="$5"
  local feature_dir

  if [ -n "${LOCALFS_FEATURE_ID:-}" ]; then
    feature_id="$LOCALFS_FEATURE_ID"
  else
    existing_count=$(ls "$CWAI_SPECS_FOLDER" 2>/dev/null | wc -l | tr -d ' ')
    feature_id=$((existing_count + 1))
  fi
  feature_padded_id=$(padd_feature_id "$feature_id")

  feature_dir="$feature_parent_dir/$feature_padded_id-$feature_slug"
  mkdir -p "$feature_dir"

  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo '{}' | jq \
    --arg author "$(git config --get user.name) <$(git config --get user.email)>" \
    --arg title "$feature_title" \
    --arg description "$feature_body" \
    --argjson labels "$(echo "$feature_labels" | jq -R 'split(",")')" \
    --arg created_at "$now" \
    --arg updated_at "$now" \
    --argjson id "${feature_id:-0}" \
    '{
      author: $author,
      id: $id,
      title: $title,
      description: $description,
      labels: $labels,
      created_at: $created_at,
      updated_at: $updated_at,
      comments: []
    }' >"$feature_dir/issue.json"

  # Validate issue creation succeeded
  if [[ -z "$feature_id" || "$feature_id" == "0" ]]; then
    log_error "Failed to create issue."
  fi
  log_info "✅ Created Local issue (#$feature_id) $title"

  echo $feature_id
}

localfs_update_issue() {
  local feature_id="$1"
  local feature_name="$2"
  local feature_dir="$3"
  local feature_labels="$4"
  local feature_comment="$5"

  local feature_existing_labels
  local feature_updated_labels
  local issue_temp_file

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local comment_json
  comment_json=$(
    echo '{}' | jq \
      --arg author "$(git config --get user.name) <$(git config --get user.email)>" \
      --arg comment "${feature_comment/$feature_name/}" \
      --arg created_at "$now" \
      '{
        author: $author,
        comment: $comment,
        created_at: $created_at
      }'
  )

  # Read existing labels from issue.json
  feature_existing_labels="$(jq -r '.labels // [] | join(",")' <"$feature_dir/issue.json")"
  # Compose new labels array
  feature_updated_labels=$(concatenate_arrays "$feature_existing_labels" "$feature_labels")

  issue_temp_file=$(mktemp)

  jq \
    --argjson comment "$comment_json" \
    --arg labels "$feature_updated_labels" \
    --arg updated_at "$now" \
    '.comments += [$comment]
     | .labels = (if $labels == "" then [] else ($labels | split(",") | map(select(length > 0))) end)
     | .updated_at = $updated_at' \
    <"$feature_dir/issue.json" \
    >"$issue_temp_file"

  cat "$issue_temp_file" >"$feature_dir/issue.json"

  log_info "💬 Updated Local issue (#$feature_id) $feature_name"

  rm "$issue_temp_file"
}

#######################################
# Github Issue Manager
#######################################

github_create_label() {
  local label_name="$1"
  local label_color="${2:-}"
  local label_description="${3:-}"

  if [ -z "$label_color" ]; then
    label_color=$(generate_hex_color)
  fi

  if gh label list --json name --jq ".[].name" | grep -q "^${label_name}$"; then
    return 0
  fi

  log_info "🏷️ Creating label: $label_name"
  if [[ -n "$label_description" ]]; then
    gh label create "$label_name" --color "$label_color" --description "$label_description" >/dev/null 2>&1
  else
    gh label create "$label_name" --color "$label_color" >/dev/null 2>&1
  fi
}

github_create_issue() {
  local feature_slug="$1"
  local feature_title="$2"
  local feature_parent_dir="$3"
  local feature_labels="$4"
  local feature_body="$5"
  local feature_id
  local labels
  local gh_label_args=()

  # Ensure required labels exist
  github_create_label "task" "0e8a16" "Task item"
  github_create_label "auto-generated" "bfd4f2" "Automatically generated by script"

  # Create any additional labels if needed and build label args
  if [[ -n "$feature_labels" ]]; then
    OLD_IFS="$IFS"
    IFS=','
    for label in $feature_labels; do
      github_create_label "$label"
      gh_label_args+=(--label "$label")
    done
    IFS="$OLD_IFS"
  fi

  gh_label_args+=(--label "task" --label "auto-generated")

  local issue_url
  issue_url=$(gh issue create --title "$feature_title" --body "$feature_body" "${gh_label_args[@]}")
  log_info "🏷️ Created Github issue: $issue_url"

  feature_id=$(awk -F/ '{print $NF}' <<<"$issue_url")
  export LOCALFS_FEATURE_ID="$feature_id"
  localfs_create_issue "$feature_slug" "$feature_title" "$feature_parent_dir" "$feature_labels" "$feature_body"
  unset LOCALFS_FEATURE_ID
}

github_update_issue() {
  local feature_id="$1"
  local feature_name="$2"
  local feature_dir="$3"
  local feature_labels="$4"
  local feature_comment="$5"

  local issue_add_labels=()
  local issue_remove_labels=()

  local labels=(${feature_labels//,/ })
  for label in "${labels[@]}"; do
    if [[ $label != -* ]]; then
      issue_add_labels+=("$label")
      github_create_label "$label"
    else
      issue_remove_labels+=("${label#-}")
    fi
  done

  if [[ ${#issue_add_labels[@]} -gt 0 ]]; then
    local add_labels_csv
    local IFS=','
    add_labels_csv="${issue_add_labels[*]}"
    gh issue edit "$feature_id" --add-label "$add_labels_csv" 1>&2
    log_info "🏷️ Added labels to issue #${feature_id}: ${issue_add_labels[*]}"
  fi
  if [[ ${#issue_remove_labels[@]} -gt 0 ]]; then
    local remove_labels_csv
    local IFS=','
    remove_labels_csv="${issue_remove_labels[*]}"
    gh issue edit "$feature_id" --remove-label "$remove_labels_csv" 1>&2
    log_info "🏷️ Removed labels from issue #${feature_id}: ${issue_remove_labels[*]}"
  fi

  gh issue comment "$feature_id" --body "$feature_comment" >/dev/null 2>&1
  log_info "💬 Added comment to Github issue #${feature_id}"

  localfs_update_issue "$feature_id" "$feature_name" "$feature_dir" "$feature_labels" "$feature_comment"
}
