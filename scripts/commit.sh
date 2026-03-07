#!/bin/sh
# scripts/commit.sh - Structured Committer Script
# Professional CLI wrapper for Commitizen and pre-commit health checks.
# Features: POSIX compliant, Execution Guard, SSoT Architecture, Professional UX.

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

Starts the interactive Commitizen CLI to create a structured commit message.
Performs a quick environment check before starting.

Options:
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

Environment Variables:
  NPM              NPM client (default: pnpm)

EOF
}

# Argument parsing
for arg in "$@"; do
  case "$arg" in
  -q | --quiet) VERBOSE=0 ;;
  -v | --verbose) VERBOSE=2 ;;
  -h | --help)
    show_help
    exit 0
    ;;
  esac
done

log_info "📝 Starting Structured Commit Guide...\n"

# 2. Pre-check: Environment
if command -v sh >/dev/null 2>&1 && [ -f "scripts/check-env.sh" ]; then
  log_info "Running quick environment check..."
  sh scripts/check-env.sh --quiet || {
    log_warn "Warning: Environment check found issues. Committing anyway..."
  }
fi

# 3. Check for dependencies
NPM=${NPM:-pnpm}
if ! command -v "$NPM" >/dev/null 2>&1; then
  log_error "Error: $NPM client not found."
  exit 1
fi

# 4. Launch Commitizen
log_info "Launching interactive CLI..."
if [ -f "package.json" ] && grep -q '"commit":' package.json; then
  "$NPM" run commit
else
  # Fallback to direct npx if script not found
  "$NPM" exec cz
fi
