#!/usr/bin/env bash

###############################################################################
# code-with-ai Installer
#
# Purpose:
#   Install the AI development support assets (.cwai and .github/prompts) into
#   another existing project directory.
#
# Behavior:
#   - If executed from inside a local clone (detected via presence of .cwai and
#     .github/prompts) it uses current directory as the source.
#   - Otherwise it clones the official repository into a temporary directory
#     and uses that as the source.
#   - If BOTH target/.cwai and target/.github/prompts already exist, the script
#     will exit and inform the user that a previous installation exists and
#     manual intervention is required (to avoid destructive overwrite).
#   - If only one of them exists, the missing one will be installed (non-
#     destructive). Existing directories/files are not overwritten unless the
#     user passes --force.
#
# Usage:
#   ./install.sh <target-project-path> [--force] [--repo <git-url>]
#
# Options:
#   --force        Overwrite existing files within the individual target
#                  directories (but still refuses if BOTH directories exist
#                  unless --force-all is used)
#   --force-all    Force full overwrite even if both directories already exist.
#   --repo <url>   Override default repository URL.
#   -h|--help      Show help.
#
# Exit Codes:
#   0 Success
#   1 Usage / argument error
#   2 Pre-existing install detected (without force)
#   3 Internal error (clone/copy failure)
###############################################################################

set -euo pipefail
IFS=$'\n\t'

DEFAULT_REPO_URL="https://github.com/templ-project/code-with-ai.git"
SCRIPT_NAME="$(basename "$0")"
# Resolve the directory this script resides in (works even if invoked via relative or absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'
COLOR_CYAN='\033[0;36m'

log() { printf "%b[INFO ]%b %s\n" "${COLOR_CYAN}" "${COLOR_RESET}" "$*"; }
warn() { printf "%b[WARN ]%b %s\n" "${COLOR_YELLOW}" "${COLOR_RESET}" "$*"; }
err()  { printf "%b[ERROR]%b %s\n" "${COLOR_RED}" "${COLOR_RESET}" "$*" 1>&2; }
success() { printf "%b[SUCCESS]%b %s\n" "${COLOR_GREEN}" "${COLOR_RESET}" "$*"; }

usage() {
  cat <<EOF
code-with-ai installer

Installs .cwai and .github/prompts into an existing project.

Usage: $SCRIPT_NAME <target-project-path> [options]

Options:
  --force         Overwrite existing matching files inside an existing directory
  --force-all     Overwrite entire existing .cwai and .github/prompts (destructive)
  --repo <url>    Custom repository URL (default: $DEFAULT_REPO_URL)
  -h, --help      Show this help message

Examples:
  $SCRIPT_NAME ../another-project
  $SCRIPT_NAME ~/dev/project --force
  $SCRIPT_NAME ~/dev/project --repo git@github.com:templ-project/code-with-ai.git
EOF
}

TARGET_DIR=""
REPO_URL="$DEFAULT_REPO_URL"
FORCE=false
FORCE_ALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage; exit 0;;
    --repo)
      shift || { err "--repo requires a value"; exit 1; }
      REPO_URL="$1";;
    --force)
      FORCE=true;;
    --force-all)
      FORCE_ALL=true; FORCE=true;;
    --*)
      err "Unknown option: $1"; usage; exit 1;;
    *)
      if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"
      else
        err "Multiple target directories specified: $TARGET_DIR and $1"; usage; exit 1
      fi;;
  esac
  shift || true
done

if [[ -z "$TARGET_DIR" ]]; then
  err "Target project path is required"; usage; exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  err "Target directory does not exist: $TARGET_DIR"; exit 1
fi

abs_path() {
  # Resolve absolute path (portable)
  local p="$1"
  if [[ -d "$p" ]]; then
    (cd "$p" && pwd)
  else
    (cd "$(dirname "$p")" && printf "%s/%s" "$(pwd)" "$(basename "$p")")
  fi
}

TARGET_DIR="$(abs_path "$TARGET_DIR")"

SOURCE_ROOT=""
TEMP_DIR=""
cleanup() {
  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}" || true
  fi
}
trap cleanup EXIT INT TERM

# Detect if the script itself resides inside a git clone (presence of .git file/dir next to it)
if [[ -e "$SCRIPT_DIR/.git" ]]; then
  # Validate required source directories exist alongside script
  if [[ ! -d "$SCRIPT_DIR/.cwai" || ! -d "$SCRIPT_DIR/.github/prompts" ]]; then
    err "Local git repository missing required directories (.cwai and .github/prompts)."
    exit 3
  fi
  SOURCE_ROOT="$SCRIPT_DIR"
  log "Using local git repository as source: $SOURCE_ROOT"
else
  log "No .git found adjacent to installer; cloning repository..."
  command -v git >/dev/null 2>&1 || { err "git is required but not found in PATH"; exit 3; }
  TEMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t codewithai)"
  log "Cloning $REPO_URL into $TEMP_DIR"
  if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR" >/dev/null 2>&1; then
    err "Failed to clone repository: $REPO_URL"; exit 3
  fi
  if [[ ! -d "$TEMP_DIR/.cwai" || ! -d "$TEMP_DIR/.github/prompts" ]]; then
    err "Repository clone missing required directories (.cwai or .github/prompts)"; exit 3
  fi
  SOURCE_ROOT="$TEMP_DIR"
fi

SRC_CWAI="$SOURCE_ROOT/.cwai"
SRC_PROMPTS="$SOURCE_ROOT/.github/prompts"

DEST_CWAI="$TARGET_DIR/.cwai"
DEST_PROMPTS="$TARGET_DIR/.github/prompts"

if [[ -d "$DEST_CWAI" && -d "$DEST_PROMPTS" && $FORCE_ALL == false ]]; then
  warn "Both .cwai and .github/prompts already exist in target: $TARGET_DIR"
  warn "A previous installation appears to be present."
  warn "Refusing to overwrite without --force-all."
  echo
  echo "Next steps:"
  echo "  1. Review existing directories"
  echo "  2. Backup or remove them if you intend to reinstall"
  echo "  3. Re-run with --force-all to overwrite everything (destructive)"
  exit 2
fi

copy_dir() {
  local src="$1" dest="$2"
  if [[ -d "$dest" ]]; then
    if [[ $FORCE == true ]]; then
      log "Updating existing $(basename "$dest") directory"
    else
      log "Skipping existing directory (no --force): $dest"
      return 0
    fi
  else
    log "Installing $(basename "$dest") directory"
    mkdir -p "$(dirname "$dest")"
  fi

  if command -v rsync >/dev/null 2>&1; then
    # Build option list first to avoid unbound array issues under set -u
    local rsync_opts=(-a)
    if [[ -d "$dest" && $FORCE_ALL == true ]]; then
      rsync_opts+=(--delete)
    fi
    rsync "${rsync_opts[@]}" "$src/" "$dest/"
  else
    if [[ -d "$dest" && $FORCE_ALL == true ]]; then
      rm -rf "$dest"
      mkdir -p "$dest"
    fi
    cp -R "$src/." "$dest/"
  fi
}

copy_dir "$SRC_CWAI" "$DEST_CWAI"
copy_dir "$SRC_PROMPTS" "$DEST_PROMPTS"

success "Installation complete."
echo
echo "Installed components:"
[[ -d "$DEST_CWAI" ]] && echo "  - $DEST_CWAI"
[[ -d "$DEST_PROMPTS" ]] && echo "  - $DEST_PROMPTS"
echo
echo "You may now integrate these assets into your workflow."

exit 0
