#!/bin/sh
# scripts/format.sh - Unified Project Formatter
# Consolidates formatting tools for Shell, JS/TS, Python, and more.
# Features: POSIX compliant, Execution Guard, Dry-run support, Professional UX.

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=1 # 0: quiet, 1: normal, 2: verbose
DRY_RUN=0

# Logging functions
log_info() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$BLUE" "$1" "$NC"; fi
}
log_success() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$GREEN" "$1" "$NC"; fi
}
log_warn() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; fi
}
log_error() {
  printf "%b%s%b\n" "$RED" "$1" "$NC" >&2
}
log_debug() {
  if [ "$VERBOSE" -ge 2 ]; then printf "[DEBUG] %s\n" "$1"; fi
}

# 1. Execution Context Guard
if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
  log_error "Error: This script must be run from the project root."
  exit 1
fi

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Unified project formatter for Shell, Python, Node.js, and more.

Options:
  --dry-run        Check formatting without applying changes.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# Argument parsing
for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=1
    log_warn "Running in DRY-RUN mode. No changes will be applied."
    ;;
  -q | --quiet) VERBOSE=0 ;;
  -v | --verbose) VERBOSE=2 ;;
  -h | --help)
    show_help
    exit 0
    ;;
  esac
done

log_info "✨ Starting Unified Project Formatter...\n"

run_shfmt() {
  log_info "── Formatting Shell Scripts (shfmt) ──"
  if command -v shfmt >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
      shfmt -d scripts/*.sh tests/*.bats
    else
      shfmt -w scripts/*.sh tests/*.bats
    fi
  else
    log_warn "Warning: shfmt not found. Skipping shell formatting."
  fi
}

run_prettier() {
  log_info "── Formatting Web/General Files (Prettier) ──"
  if [ -f "node_modules/.bin/prettier" ]; then
    PRETTIER="./node_modules/.bin/prettier"
  elif command -v prettier >/dev/null 2>&1; then
    PRETTIER="prettier"
  else
    log_warn "Warning: prettier not found. Skipping web/general formatting."
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    "$PRETTIER" --check .
  else
    "$PRETTIER" --write .
  fi
}

run_ruff() {
  log_info "── Formatting Python Files (Ruff) ──"
  VENV=${VENV:-.venv}
  if [ -x "$VENV/bin/ruff" ]; then
    RUFF="$VENV/bin/ruff"
  elif command -v ruff >/dev/null 2>&1; then
    RUFF="ruff"
  else
    log_warn "Warning: ruff not found. Skipping python formatting."
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    "$RUFF" format --check .
  else
    "$RUFF" format .
  fi
}

run_shfmt
printf "\n"
run_prettier
printf "\n"
run_ruff

log_success "\n✨ Formatting complete!"
