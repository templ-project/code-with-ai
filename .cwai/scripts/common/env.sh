#!/bin/bash

#######################################
# Environment variable loader
#######################################

# Prevent multiple sourcing
[[ -n "${_ENV_SH_SOURCED:-}" ]] && return 0
readonly _ENV_SH_SOURCED=1

if ! command -v log_info >/dev/null 2>&1; then
  echo "log_info function is not available, please import log.sh before env.sh" >&2
  exit 1
fi

# Load environment variables
load_environment() {
  local repo_root="$1"

  # Prevent multiple loading
  [[ -n "${_ENV_LOADED:-}" ]] && return 0
  readonly _ENV_LOADED=1

  # Fail loudly if no repo root provided
  [[ -z "$repo_root" ]] && { echo "ERROR: Repository root path is required" >&2; exit 1; }

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
