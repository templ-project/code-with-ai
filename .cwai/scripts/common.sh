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
# String utilities
#######################################

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
# # Get GitHub repo path (owner/repo)
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
  local issue_temp_file=$(mktemp)

  local feature_id="$1"
  local feature_name="$2"
  local feature_dir="$3"
  local feature_body="$4"

  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local feature_comment=$(
    echo '{}' | jq \
      --arg author "$(git config --get user.name) <$(git config --get user.email)>" \
      --arg comment "$feature_body" \
      --arg created_at "$now" \
      '{
        author: $author,
        comment: $comment,
        created_at: $created_at
      }'
  )

  jq \
    --argjson comment "${feature_comment/$feature_name /}" \
    --arg updated_at "$now" \
    '.comments += [$comment] | .updated_at = $updated_at' \
    <"$feature_dir/issue.json" \
    >"$issue_temp_file"

  cat "$issue_temp_file" >"$feature_dir/issue.json"

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

  local issue_url
  local gh_label_args=()

  github_create_label "task" "0e8a16" "Task item"
  github_create_label "auto-generated" "bfd4f2" "Automatically generated by script"

  local labels=(${feature_labels//,/ })
  for label in "${labels[@]}"; do
    github_create_label "$label"
    gh_label_args+=(--label "$label")
  done

  gh_label_args+=(--label "task" --label "auto-generated")

  issue_url=$(gh issue create --title "$feature_title" --body "$feature_body" "${gh_label_args[@]}")
  log_info "🏷️ Created GitHub issue: $issue_url"

  feature_id=$(echo "$issue_url" | grep -o '[0-9]\+$')
  export LOCALFS_FEATURE_ID="$feature_id"
  localfs_create_issue "$feature_slug" "$feature_title" "$feature_parent_dir" "$feature_labels" "$feature_body"
  unset LOCALFS_FEATURE_ID
}

github_update_issue() {
  local issue_temp_file=$(mktemp)

  local feature_id="$1"
  local feature_name="$2"
  local feature_dir="$3"
  local feature_body="$4"

  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local feature_comment=$(
    echo '{}' | jq \
      --arg author "$(git config --get user.name) <$(git config --get user.email)>" \
      --arg comment "$feature_body" \
      --arg created_at "$now" \
      '{
        author: $author,
        comment: $comment,
        created_at: $created_at
      }'
  )

  jq \
    --argjson comment "${feature_comment/$feature_name /}" \
    --arg updated_at "$now" \
    '.comments += [$comment] | .updated_at = $updated_at' \
    <"$feature_dir/issue.json" \
    >"$issue_temp_file"

  cat "$issue_temp_file" >"$feature_dir/issue.json"

  rm "$issue_temp_file"
}
