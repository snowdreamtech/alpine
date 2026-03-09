#!/bin/sh
# scripts/verify.sh - Project Pre-flight Verifier
# Orchestrates environment health checks, linting, and unit testing for full validation.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Holistic orchestration of specialized sub-scripts.
#   - Exit status propagation for CI/CD usage.
#   - Professional UX with colored status reporting.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Help message
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

main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  _SUB_ARGS=""
  for _arg in "$@"; do
    case "$_arg" in
    -q | --quiet) _SUB_ARGS="--quiet" ;;
    -v | --verbose) _SUB_ARGS="--verbose" ;;
    esac
  done
  parse_common_args "$@"

  # Pass dry-run to sub-scripts
  if [ "$DRY_RUN" -eq 1 ]; then
    _SUB_ARGS="${_SUB_ARGS} --dry-run"
  fi

  log_info "🚀 Starting Full Project Verification...\n"

  run_step() {
    _SCRIPT="$1"
    _MSG="$2"
    log_info "── Step: $_MSG ──"
    if [ -f "$_SCRIPT" ]; then
      # shellcheck disable=SC2086
      sh "$_SCRIPT" $_SUB_ARGS || {
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
