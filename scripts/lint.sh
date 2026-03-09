#!/bin/sh
# scripts/lint.sh - Unified Quality Orchestrator
# Wraps pre-commit hooks and specialized language linters into a single CLI.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Orchestrated linting for all supported language stacks.
#   - CI-optimized execution with strict error checking.
#   - Professional UX with detailed diagnostic output.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

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
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _FIX=""
  local _arg
  for _arg in "$@"; do
    case "$_arg" in
    --fix) _FIX="--fix" ;;
    -q | --quiet | -v | --verbose | --dry-run | -h | --help) ;;
    esac
  done
  parse_common_args "$@"

  log_info "🔍 Starting Unified Project Linter...\n"

  run_pre_commit() {
    log_info "── Running pre-commit hooks (Pass 1/1) ──"
    local _VENV
    _VENV=${VENV:-.venv}
    local _PRE_COMMIT=""

    if [ -x "$_VENV/bin/pre-commit" ]; then
      _PRE_COMMIT="$_VENV/bin/pre-commit"
    elif command -v pre-commit >/dev/null 2>&1; then
      _PRE_COMMIT="pre-commit"
    else
      log_error "Error: pre-commit not found. Please run 'make setup' first."
      exit 1
    fi

    # Run on all files
    if [ -n "$_FIX" ]; then
      log_info "Running in auto-fix mode..."
      # pre-commit doesn't have a direct --fix flag for everything at once,
      # but many hooks auto-fix by default.
      "$_PRE_COMMIT" run --all-files || log_warn "Some hooks modified files or reported errors."
    else
      "$_PRE_COMMIT" run --all-files
    fi
  }

  run_pre_commit

  log_success "\n✨ Linting complete!"

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake test%b to run the unified test suite.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake verify%b to ensure full project health.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
