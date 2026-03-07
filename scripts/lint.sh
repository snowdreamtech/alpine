#!/bin/sh
# scripts/lint.sh - Unified Project Linter
# Wraps pre-commit and language-specific linters into a professional CLI.
# Features: POSIX compliant, Execution Guard, CI-optimized, Professional UX.

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=1 # 0: quiet, 1: normal, 2: verbose

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

Unified project linter for Shell, Python, Node.js, and more.

Options:
  --fix            Try to auto-fix linting issues.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# Argument parsing
FIX=""
for arg in "$@"; do
  case "$arg" in
  --fix) FIX="--fix" ;;
  -q | --quiet) VERBOSE=0 ;;
  -v | --verbose) VERBOSE=2 ;;
  -h | --help)
    show_help
    exit 0
    ;;
  esac
done

log_info "🔍 Starting Unified Project Linter...\n"

run_pre_commit() {
  log_info "── Running pre-commit hooks (Pass 1/1) ──"
  VENV=${VENV:-.venv}
  PRE_COMMIT=""

  if [ -x "$VENV/bin/pre-commit" ]; then
    PRE_COMMIT="$VENV/bin/pre-commit"
  elif command -v pre-commit >/dev/null 2>&1; then
    PRE_COMMIT="pre-commit"
  else
    log_error "Error: pre-commit not found. Please run 'make setup' first."
    exit 1
  fi

  # Run on all files
  if [ -n "$FIX" ]; then
    log_info "Running in auto-fix mode..."
    # pre-commit doesn't have a direct --fix flag for everything at once,
    # but many hooks auto-fix by default.
    "$PRE_COMMIT" run --all-files || log_warn "Some hooks modified files or reported errors."
  else
    "$PRE_COMMIT" run --all-files
  fi
}

run_pre_commit

log_success "\n✨ Linting complete!"
