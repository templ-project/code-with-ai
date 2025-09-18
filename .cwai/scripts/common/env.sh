#######################################
# Loads environment variables from .env and .env.local files.
# Processes files in order: .env first, then .env.local (local overrides global).
# Automatically exports all loaded variables to make them available to child processes.
# Globals:
#   None
# Arguments:
#   $1 - Repository root directory path (required)
# Outputs:
#   Log messages indicating which environment files are being loaded
# Returns:
#   0 on success
# Notes:
#   - Skips comment lines (starting with #) in environment files
#   - Uses set -a/set +a to automatically export variables during sourcing
#   - Silently skips files that don't exist
#   - Repository root path should be an absolute path
#######################################
load_environment() {
  local repo_root="$1"

  # Validate required parameter
  if [[ -z "$repo_root" ]]; then
    echo "Repository root path is required" >&2
    return 1
  fi

  # Load .env first, then .env.local (local overrides global)
  local env_file
  for env_file in "${repo_root}/.env" "${repo_root}/.env.local"; do
    if [[ -f "$env_file" ]]; then
      echo "Loading environment from: $env_file" >&2
      set -a # automatically export all variables
      export $(cat "$env_file" | grep -v '#')
      set +a
    fi
  done
}
