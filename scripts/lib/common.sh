#!/bin/sh
# scripts/lib/common.sh - Shared logic for project scripts.
# Unified logging, colors, and utility functions.
# shellcheck disable=SC2034

# Colors (using printf to generate literal ESC characters for maximum compatibility)
BLUE=$(printf '\033[0;34m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
RED=$(printf '\033[0;31m')
NC=$(printf '\033[0m')

# Default verbosity
# shellcheck disable=SC2034
VERBOSE=${VERBOSE:-1} # 0: quiet, 1: normal, 2: verbose
DRY_RUN=${DRY_RUN:-0}

# SSoT Constants (Paths and Files)
CHANGELOG="CHANGELOG.md"
PACKAGE_JSON="package.json"
CARGO_TOML="Cargo.toml"
PYPROJECT_TOML="pyproject.toml"
VERSION_FILE="VERSION"
REQUIREMENTS_TXT="requirements-dev.txt"
VENV="${VENV:-.venv}"
PYTHON="${PYTHON:-python3}"
NPM="${NPM:-pnpm}"
GORELEASER="${GORELEASER:-goreleaser}"
LOCK_DIR=".archival_lock"
DOCS_DIR="docs"
# shellcheck disable=SC2034
ARCHIVE_DIR="${ARCHIVE_DIR:-.}"

# Logging functions
log_info() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%s%b%s\n" "$BLUE" "$1" "$NC"; fi
}
log_success() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%s%b%s\n" "$GREEN" "$1" "$NC"; fi
}
log_warn() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%s%b%s\n" "$YELLOW" "$1" "$NC"; fi
}
log_error() {
  printf "%s%b%s\n" "$RED" "$1" "$NC" >&2
}
log_debug() {
  if [ "$VERBOSE" -ge 2 ]; then printf "[DEBUG] %b\n" "$1"; fi
}

# Execution context guard
guard_project_root() {
  if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
    log_error "Error: This script must be run from the project root."
    exit 1
  fi
}

# Export functions for subshells if needed
# Note: POSIX sh doesn't support export -f

# Standard argument parsing for DRY_RUN and VERBOSE
parse_common_args() {
  for _arg in "$@"; do
    case "$_arg" in
    --dry-run)
      # shellcheck disable=SC2034
      DRY_RUN=1
      log_warn "Running in DRY-RUN mode. No changes will be applied."
      ;;
    -q | --quiet) # shellcheck disable=SC2034
      VERBOSE=0 ;;
    -v | --verbose) # shellcheck disable=SC2034
      VERBOSE=2 ;;
    -h | --help)
      show_help
      exit 0
      ;;
    esac
  done
}
