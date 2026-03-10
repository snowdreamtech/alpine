#!/bin/sh
# scripts/lint.sh - Unified Quality Orchestrator
# Wraps pre-commit hooks and specialized language linters into a single CLI.
#
# Usage:
#   sh scripts/lint.sh [OPTIONS]
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

# Purpose: Displays usage information for the quality orchestrator.
# Examples:
#   show_help
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

# Purpose: Orchestrates pre-commit hooks execution across all files.
# Params:
#   $1 - Optional fix flag (--fix)
# Examples:
#   run_pre_commit_lint "--fix"
run_pre_commit_lint() {
  local _LV_FIX="$1"
  log_info "── Running pre-commit hooks (Pass 1/1) ──"
  local _VENV_LNT
  _VENV_LNT=${VENV:-.venv}
  local _PRE_COMMIT_LNT=""

  if [ -x "$_VENV_LNT/bin/pre-commit" ]; then
    _PRE_COMMIT_LNT="$_VENV_LNT/bin/pre-commit"
  elif [ -x "$_VENV_LNT/Scripts/pre-commit.exe" ]; then
    _PRE_COMMIT_LNT="$_VENV_LNT/Scripts/pre-commit.exe"
  elif command -v pre-commit >/dev/null 2>&1; then
    _PRE_COMMIT_LNT="pre-commit"
  elif [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_warn "DRY-RUN: pre-commit not found. Using placeholder for preview."
    _PRE_COMMIT_LNT="pre-commit"
  else
    log_error "Error: pre-commit not found. Please run 'make setup' first."
    exit 1
  fi

  # Run on all files
  if [ -n "$_LV_FIX" ]; then
    log_info "Running in auto-fix mode..."
    # pre-commit doesn't have a direct --fix flag for everything at once,
    # but many hooks auto-fix by default.
    "$_PRE_COMMIT_LNT" run --all-files || log_warn "Some hooks modified files or reported errors."
  else
    "$_PRE_COMMIT_LNT" run --all-files
  fi
}

# Purpose: Main entry point for the quality orchestration engine.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --fix
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _FIX_LNT=""
  local _arg_lnt
  for _arg_lnt in "$@"; do
    case "$_arg_lnt" in
    --fix) _FIX_LNT="--fix" ;;
    -q | --quiet | -v | --verbose | --dry-run | -h | --help) ;;
    esac
  done
  parse_common_args "$@"

  log_info "🔍 Starting Unified Project Linter...\n"

  run_pre_commit_lint "$_FIX_LNT"

  log_success "\n✨ Linting complete!"

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake test%b to run the unified test suite.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake verify%b to ensure full project health.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
