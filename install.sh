#!/usr/bin/env bash

# CwAI (Code with AI) Installation Script
# Follows Google Bash Style Guide and .shellcheckrc requirements
# Compatible with Bash 4.0+

set -euo pipefail
IFS=$'\n\t'

# Script constants
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color constants for output formatting
readonly COLOR_RESET='\033[0m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BLUE='\033[0;34m'

# Global variables
g_selected_ai_client=""
g_install_type=""
g_target_path=""
g_cwai_source_dir="${SCRIPT_DIR}/.cwai"

# Logging functions
log_info() {
  printf "%b[INFO]%b %s\n" "$COLOR_CYAN" "$COLOR_RESET" "$*"
}

log_warn() {
  printf "%b[WARN]%b %s\n" "$COLOR_YELLOW" "$COLOR_RESET" "$*" >&2
}

log_error() {
  printf "%b[ERROR]%b %s\n" "$COLOR_RED" "$COLOR_RESET" "$*" >&2
}

log_success() {
  printf "%b[SUCCESS]%b %s\n" "$COLOR_GREEN" "$COLOR_RESET" "$*"
}

# Display the CwAI logo in ASCII art
show_logo() {
  printf "%b" "$COLOR_BLUE"
  cat <<'EOF'
<<<<<<< HEAD
   _____                _____
  / ____|           _  |_   _|
=======
   _____            _   _____
  / ____|          | | |_   _|
>>>>>>> a0b08b1 (chore: updated how features are created)
 | |     __      _ / \   | |
 | |     \ \ /\ / / / \  | |
 | |____  \ V  V / ____\_| |_
  \_____|  \_/\_/_/    \_____/

            C w A I
          Code with AI
EOF
  printf "%b\n\n" "$COLOR_RESET"
}

# Display usage information
show_usage() {
  cat <<EOF
Code with AI (CwAI) Installation Script

Usage: ${SCRIPT_NAME} [options]

Options:
  -h, --help      Show this help message

This interactive installer will guide you through:
1. Selecting your AI client
2. Choosing installation type (local/global)
3. Setting installation path
4. Handling existing installations
5. Installing CwAI prompts and assets
EOF
}

# Check if Bash version is 4.0 or above
check_bash_version() {
  if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    log_error "Bash 4.0 or newer is required. Current version: ${BASH_VERSION}"
    exit 1
  fi
  log_info "Bash version ${BASH_VERSION} detected - OK"
}

# Validate that required commands are available
ensure_command_exists() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    log_error "Required command '${cmd}' not found in PATH"
    exit 1
  fi
}

# Check system dependencies
check_dependencies() {
  log_info "Checking system dependencies..."
  ensure_command_exists "cp"
  ensure_command_exists "mkdir"
  ensure_command_exists "rm"
  ensure_command_exists "find"
  log_info "All dependencies satisfied"
}

# Get absolute path of a file or directory
get_absolute_path() {
  local path_input="$1"

  # Expand tilde
  if [[ "${path_input}" == ~* ]]; then
    path_input="${HOME}${path_input:1}"
  fi

  if [[ -d "${path_input}" ]]; then
    (cd "${path_input}" && pwd)
  elif [[ -e "${path_input}" ]]; then
    local dir_part
    dir_part="$(dirname "${path_input}")"
    local base_part
    base_part="$(basename "${path_input}")"
    printf "%s/%s\n" "$(cd "${dir_part}" && pwd)" "${base_part}"
  else
    # Path doesn't exist, construct absolute path
    if [[ "${path_input}" == /* ]]; then
      printf "%s\n" "${path_input}"
    else
      printf "%s/%s\n" "$(pwd)" "${path_input}"
    fi
  fi
}

# Validate that path exists
validate_path_exists() {
  local path="$1"
  local path_type="$2"

  if [[ ! -e "${path}" ]]; then
    log_error "${path_type} path does not exist: ${path}"
    return 1
  fi

  if [[ ! -d "${path}" ]]; then
    log_error "${path_type} path is not a directory: ${path}"
    return 1
  fi

  return 0
}

# Ask user which AI Client they want to install CwAI for
select_ai_client() {
  printf "\nWhat AI Client do you want to install CwAI for?\n"
  printf "  1) VSCode Copilot\n"
  printf "  2) Claude\n"
  printf "  3) Gemini\n"

  while true; do
    printf "Enter your choice (1-3): "
    local choice
    if ! read -r choice; then
      log_error "Failed to read input"
      exit 1
    fi

    case "${choice}" in
      1)
        g_selected_ai_client="VSCode Copilot"
        break
        ;;
      2)
        g_selected_ai_client="Claude"
        break
        ;;
      3)
        g_selected_ai_client="Gemini"
        break
        ;;
      *)
        log_warn "Invalid choice. Please enter 1, 2, or 3."
        ;;
    esac
  done

  log_info "Selected AI Client: ${g_selected_ai_client}"
}

# Check if AI Client supports multiple install paths
ai_client_supports_multiple_paths() {
  local client="$1"
  case "${client}" in
    "VSCode Copilot"|"Claude"|"Gemini")
      return 0  # Supports both local and global
      ;;
    *)
      return 1
      ;;
  esac
}

# Ask user how they want to install CwAI (local vs global)
select_install_type() {
  local client="$1"

  if ai_client_supports_multiple_paths "${client}"; then
    printf "\nHow do you want to install CwAI?\n"
    printf "  1) Locally (in project)\n"
    printf "  2) Globally\n"

    while true; do
      printf "Enter your choice (1-2): "
      local choice
      if ! read -r choice; then
        log_error "Failed to read input"
        exit 1
      fi

      case "${choice}" in
        1)
          g_install_type="local"
          break
          ;;
        2)
          g_install_type="global"
          break
          ;;
        *)
          log_warn "Invalid choice. Please enter 1 or 2."
          ;;
      esac
    done
  else
    # Set automatically based on client capabilities
    g_install_type="global"
    log_info "Install type set to: ${g_install_type} (only option for ${client})"
  fi
}

# Get project path from user for local installation
get_project_path() {
  while true; do
    printf "\nPlease provide the path to the project: "
    local project_path
    if ! read -r project_path; then
      log_error "Failed to read input"
      exit 1
    fi

    if [[ -z "${project_path}" ]]; then
      log_warn "Path cannot be empty. Please try again."
      continue
    fi

    project_path="$(get_absolute_path "${project_path}")"

    if validate_path_exists "${project_path}" "Project"; then
      g_target_path="${project_path}"
      log_info "Project path: ${g_target_path}"
      break
    fi

    log_warn "Please provide a valid existing directory path."
  done
}

# Determine global install path for AI Client
get_global_install_path() {
  local client="$1"
  local install_path=""

  case "${client}" in
    "VSCode Copilot")
      if [[ "$(uname)" == "Darwin" ]]; then
        install_path="${HOME}/Library/Application Support/Code/User/globalStorage/github.copilot"
      else
        install_path="${HOME}/.vscode/extensions/github.copilot"
      fi
      ;;
    "Claude")
      install_path="${HOME}/.config/claude"
      ;;
    "Gemini")
      install_path="${HOME}/.config/gemini"
      ;;
    *)
      log_error "Unknown AI client: ${client}"
      exit 1
      ;;
  esac

  g_target_path="${install_path}"
  log_info "Global install path: ${g_target_path}"
}

# Check if folders already exist and ask how to proceed
check_existing_installation() {
  local existing_paths=()

  # Check for client-specific installation paths
  case "${g_selected_ai_client}" in
    "VSCode Copilot")
      if [[ -d "${g_target_path}/.github/prompts" ]]; then
        existing_paths+=("${g_target_path}/.github/prompts")
      fi
      ;;
    "Claude")
      if [[ -d "${g_target_path}/prompts" ]]; then
        existing_paths+=("${g_target_path}/prompts")
      fi
      ;;
    "Gemini")
      if [[ -d "${g_target_path}/templates" ]]; then
        existing_paths+=("${g_target_path}/templates")
      fi
      ;;
    *)
      # Unknown client - no specific paths to check
      ;;
  esac

  # Also check for .cwai folder
  if [[ -d "${g_target_path}/.cwai" ]]; then
    existing_paths+=("${g_target_path}/.cwai")
  fi

  if [[ ${#existing_paths[@]} -gt 0 ]]; then
    printf "\nExisting CwAI installation detected at:\n"
    for path in "${existing_paths[@]}"; do
      printf "  - %s\n" "${path}"
    done
    printf "How should we proceed?\n"
    printf "  1) Copy Over Existing\n"
    printf "  2) Remove folders and copy again\n"

    while true; do
      printf "Enter your choice (1-2): "
      local choice
      if ! read -r choice; then
        log_error "Failed to read input"
        exit 1
      fi

      case "${choice}" in
        1)
          log_info "Will copy over existing installation"
          return 0
          ;;
        2)
          log_info "Will remove existing installation and copy again"
          for path in "${existing_paths[@]}"; do
            if ! rm -rf "${path}"; then
              log_error "Failed to remove existing directory: ${path}"
              exit 1
            fi
            log_info "Removed: ${path}"
          done
          return 0
          ;;
        *)
          log_warn "Invalid choice. Please enter 1 or 2."
          ;;
      esac
    done
  fi
}

# Install prompts from .cwai/prompts as required for each AI Client
install_prompts() {
  local src_prompts="${g_cwai_source_dir}/prompts"

  if [[ ! -d "${src_prompts}" ]]; then
    log_error "Source prompts directory not found: ${src_prompts}"
    exit 1
  fi

  case "${g_selected_ai_client}" in
    "VSCode Copilot")
      install_vscode_prompts "${src_prompts}"
      ;;
    "Claude")
      install_claude_prompts "${src_prompts}"
      ;;
    "Gemini")
      install_gemini_prompts "${src_prompts}"
      ;;
    *)
      log_error "Unknown AI client: ${g_selected_ai_client}"
      exit 1
      ;;
  esac

  log_success "Prompts installed successfully for ${g_selected_ai_client}"
}

# Install prompts for VSCode Copilot (.github/prompts/*.prompt.md)
install_vscode_prompts() {
  local src_prompts="$1"
  local dest_dir="${g_target_path}/.github/prompts"

  log_info "Installing VSCode Copilot prompts to ${dest_dir}"

  # Create destination directory
  if ! mkdir -p "${dest_dir}"; then
    log_error "Failed to create VSCode prompts directory: ${dest_dir}"
    exit 1
  fi

  # Convert and copy each prompt file to .prompt.md format
  for prompt_file in "${src_prompts}"/*.md; do
    if [[ -f "${prompt_file}" ]]; then
      local base_name
      base_name="$(basename "${prompt_file}" .md)"
      local dest_file="${dest_dir}/${base_name}.prompt.md"

      if ! cp "${prompt_file}" "${dest_file}"; then
        log_error "Failed to copy prompt: ${prompt_file}"
        exit 1
      fi

      log_info "Installed: ${base_name}.prompt.md"
    fi
  done
}



# Install prompts for Claude (as custom prompts in ~/.config/claude/prompts/)
install_claude_prompts() {
  local src_prompts="$1"
  local dest_dir="${g_target_path}/prompts"

  log_info "Installing Claude prompts to ${dest_dir}"

  # Create destination directory
  if ! mkdir -p "${dest_dir}"; then
    log_error "Failed to create Claude prompts directory: ${dest_dir}"
    exit 1
  fi

  # Copy prompt files
  for prompt_file in "${src_prompts}"/*.md; do
    if [[ -f "${prompt_file}" ]]; then
      local base_name
      base_name="$(basename "${prompt_file}")"
      local dest_file="${dest_dir}/${base_name}"

      if ! cp "${prompt_file}" "${dest_file}"; then
        log_error "Failed to copy prompt: ${prompt_file}"
        exit 1
      fi

      log_info "Installed: ${base_name}"
    fi
  done
}

# Install prompts for Gemini (as custom templates in ~/.config/gemini/templates/)
install_gemini_prompts() {
  local src_prompts="$1"
  local dest_dir="${g_target_path}/templates"

  log_info "Installing Gemini prompts to ${dest_dir}"

  # Create destination directory
  if ! mkdir -p "${dest_dir}"; then
    log_error "Failed to create Gemini templates directory: ${dest_dir}"
    exit 1
  fi

  # Copy prompt files as templates
  for prompt_file in "${src_prompts}"/*.md; do
    if [[ -f "${prompt_file}" ]]; then
      local base_name
      base_name="$(basename "${prompt_file}")"
      local dest_file="${dest_dir}/${base_name}"

      if ! cp "${prompt_file}" "${dest_file}"; then
        log_error "Failed to copy prompt: ${prompt_file}"
        exit 1
      fi

      log_info "Installed: ${base_name}"
    fi
  done
}

# Copy .cwai folder to the target path
install_cwai_folder() {
  local src_cwai="${g_cwai_source_dir}"
  local dest_cwai="${g_target_path}/.cwai"

  if [[ ! -d "${src_cwai}" ]]; then
    log_error "Source .cwai directory not found: ${src_cwai}"
    exit 1
  fi

  log_info "Installing .cwai folder from ${src_cwai} to ${dest_cwai}"

  # Create target directory if it doesn't exist
  if ! mkdir -p "${g_target_path}"; then
    log_error "Failed to create target directory: ${g_target_path}"
    exit 1
  fi

  # Copy .cwai folder
  if ! cp -r "${src_cwai}" "${dest_cwai}"; then
    log_error "Failed to copy .cwai folder"
    exit 1
  fi

  log_success ".cwai folder installed successfully"
}

# Parse command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown argument: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

# Main installation function following the install.md requirements
main() {
  # Parse command line arguments first
  parse_arguments "$@"

  # Print the project logo using ASCII
  show_logo

  # Check bash version to ensure it's 4.0 or above
  check_bash_version

  # Check system dependencies
  check_dependencies

  # Validate that source .cwai directory exists
  if [[ ! -d "${g_cwai_source_dir}" ]]; then
    log_error "Source .cwai directory not found: ${g_cwai_source_dir}"
    log_error "Please run this script from the code-with-ai project root directory."
    exit 1
  fi

  # Ask what AI Client the user wants to install CwAI for (1-4)
  select_ai_client

  # Ask user how they want to install CwAI (1-2) if multiple paths supported
  select_install_type "${g_selected_ai_client}"

  # Get the target path based on install type
  if [[ "${g_install_type}" == "local" ]]; then
    # Ask user to provide the path to the project and validate it exists
    get_project_path
  else
    # Determine the global install path for the picked AI Client
    get_global_install_path "${g_selected_ai_client}"
  fi

  # Check if folders already exist and ask how to proceed (1-2)
  check_existing_installation

  # Install prompts from .cwai/prompts as required for AI Client
  install_prompts

  # Copy .cwai folder to the target path for reference
  install_cwai_folder

  # Installation complete
  printf "\n"
  log_success "CwAI installation completed successfully!"
  printf "\nInstallation Summary:\n"
  printf "  AI Client: %s\n" "${g_selected_ai_client}"
  printf "  Install Type: %s\n" "${g_install_type}"
  printf "  Target Path: %s\n" "${g_target_path}"
  printf "  CwAI Assets: %s/.cwai\n" "${g_target_path}"

  # Show client-specific installation paths
  case "${g_selected_ai_client}" in
    "VSCode Copilot")
      printf "  Prompts: %s/.github/prompts/*.prompt.md\n" "${g_target_path}"
      ;;
    "Claude")
      printf "  Prompts: %s/prompts/*.md\n" "${g_target_path}"
      ;;
    "Gemini")
      printf "  Templates: %s/templates/*.md\n" "${g_target_path}"
      ;;
    *)
      ;;
  esac

  printf "\nYou can now start using CwAI with your %s!\n" "${g_selected_ai_client}"
}

# Execute main function with all arguments
main "$@"
