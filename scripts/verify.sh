#!/bin/sh
# scripts/verify.sh - Project Pre-flight Verifier
# Orchestrates environment checks, linting, and testing for full validation.
# Features: POSIX compliant, Execution Guard, Orchestration, Professional UX.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

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
for _arg in "$@"; do
  case "$_arg" in
  -q | --quiet) SUB_ARGS="--quiet" ;;
  -v | --verbose) SUB_ARGS="--verbose" ;;
  esac
done
parse_common_args "$@"

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
