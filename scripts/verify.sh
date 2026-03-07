#!/bin/sh
# scripts/verify.sh - Project Pre-flight Verifier
# Orchestrates environment checks, linting, and testing for full validation.
# Features: POSIX compliant, Execution Guard, Orchestration, Professional UX.

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

# 1. Execution Context Guard
if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
  log_error "Error: This script must be run from the project root."
  exit 1
fi

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Run a full project verification suite (env check, linting, and testing).
Commonly used before committing or releasing.

Options:
  -q, --quiet      Suppress verbose orchestration details.
  -v, --verbose    Enable verbose output for all sub-tools.
  -h, --help       Show this help message.

EOF
}

# Argument parsing
SUB_ARGS=""
for arg in "$@"; do
  case "$arg" in
  -q | --quiet)
    VERBOSE=0
    SUB_ARGS="--quiet"
    ;;
  -v | --verbose)
    VERBOSE=2
    SUB_ARGS="--verbose"
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  esac
done

log_info "🚀 Starting Full Project Verification...\n"

run_step() {
  _SCRIPT="$1"
  _MSG="$2"
  log_info "── Step: $_MSG ──"
  if [ -f "$_SCRIPT" ]; then
    sh "$_SCRIPT" $SUB_ARGS || {
      log_error "\n❌ Verification FAILED at Step: $_MSG"
      exit 1
    }
  else
    log_warn "Warning: $_SCRIPT not found. Skipping."
  fi
  printf "\n"
}

# 2. Environment Check
run_step "scripts/check-env.sh" "Environment Health Check"

# 3. Linting
run_step "scripts/lint.sh" "Code Quality (Linting)"

# 4. Testing
run_step "scripts/test.sh" "Core Functionality (Testing)"

log_success "✨ All verification steps passed! Project is healthy."
