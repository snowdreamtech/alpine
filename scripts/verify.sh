#!/bin/sh
# scripts/verify.sh - Project Pre-flight Verifier
#
# Purpose:
#   Orchestrates environment health checks, linting, and unit testing for full validation.
#   Acts as the final quality gate before commits or releases.
#
# Usage:
#   sh scripts/verify.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 06 (CI/Testing).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Holistic orchestration of specialized sub-scripts.
#   - Exit status propagation for CI/CD usage.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Purpose: Displays usage information for the project verifier.
# Examples:
#   show_help
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Run a full project verification suite (env check, linting, and testing).
Commonly used before committing or releasing.

Options:
  --dry-run        Preview verification steps without execution.
  -q, --quiet      Suppress verbose orchestration details.
  -v, --verbose    Enable verbose output for all sub-tools.
  -h, --help       Show this help message.

EOF
}

# Purpose: Safely executes a verification sub-script.
# Params:
#   $1 - Path to the script to execute (absolute or relative)
#   $2 - Human-readable description of the step (for logging)
#   $3 - Optional sub-arguments (passed to the sub-script)
# Examples:
#   run_verify_step "scripts/lint.sh" "Code Quality" "--fix"
run_verify_step() {
  local _SRV_SCRIPT="$1"
  local _SRV_MSG="$2"
  local _SRV_ARGS="$3"

  log_info "── Step: $_SRV_MSG ──"
  if [ -f "$_SRV_SCRIPT" ]; then
    # shellcheck disable=SC2086
    sh "$_SRV_SCRIPT" $_SRV_ARGS || {
      log_error "\n❌ Verification FAILED at Step: $_SRV_MSG"
      exit 1
    }
  else
    log_warn "Warning: $_SRV_SCRIPT not found. Skipping."
  fi
  printf "\n"
}

# Purpose: Main entry point for the project verification engine.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --verbose
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _SUB_PAR_ARGS=""
  local _arg_vfy
  for _arg_vfy in "$@"; do
    case "$_arg_vfy" in
    -q | --quiet) _SUB_PAR_ARGS="--quiet" ;;
    -v | --verbose) _SUB_PAR_ARGS="--verbose" ;;
    esac
  done
  parse_common_args "$@"

  # Pass dry-run to sub-scripts
  if [ "$DRY_RUN" -eq 1 ]; then
    _SUB_PAR_ARGS="${_SUB_PAR_ARGS} --dry-run"
  fi

  log_info "🚀 Starting Full Project Verification...\n"

  # 2. Environment Check
  run_verify_step "scripts/check-env.sh" "Environment Health Check" "$_SUB_PAR_ARGS"

  # 3. Linting
  run_verify_step "scripts/lint.sh" "Code Quality (Linting)" "$_SUB_PAR_ARGS"

  # 4. Testing
  run_verify_step "scripts/test.sh" "Core Functionality (Testing)" "$_SUB_PAR_ARGS"

  # Optional: run npm verify if defined
  run_npm_script "verify"

  log_success "✨ All verification steps passed! Project is healthy."

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake audit%b to check for security vulnerabilities.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake commit%b to finalize your changes.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
