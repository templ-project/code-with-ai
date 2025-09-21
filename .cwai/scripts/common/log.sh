#!/bin/bash

#######################################
# Logging utilities with colored output
#######################################

# Prevent multiple sourcing
[[ -n "${_LOG_SH_SOURCED:-}" ]] && return 0
readonly _LOG_SH_SOURCED=1

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
