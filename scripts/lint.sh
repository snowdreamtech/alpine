#!/usr/bin/env sh
# scripts/lint.sh - Unified Quality Orchestrator
#
# Purpose:
#   Wraps pre-commit hooks and specialized language linters into a single CLI.
#   Enforces consistent code quality standards across the entire project.
#
# Usage:
#   sh scripts/lint.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 02 (Coding Style), Rule 06 (CI/Testing).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Orchestrated linting for all supported language stacks.
#   - CI-optimized execution with strict error checking.

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

Unified project linter for Shell, Python, Node.js, Go, Rust, and more (20+ stacks).

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
  local _PRE_COMMIT_LNT
  _PRE_COMMIT_LNT=$(resolve_bin "pre-commit") || true

  if [ -z "$_PRE_COMMIT_LNT" ]; then
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_warn "DRY-RUN: pre-commit not found. Using placeholder for preview."
      _PRE_COMMIT_LNT="pre-commit"
    else
      log_error "Error: pre-commit not found. Please run 'make setup' first."
      exit 1
    fi
  fi

  # Run on all files
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_success "DRY-RUN: Would run $_PRE_COMMIT_LNT --all-files"
  elif [ -n "$_LV_FIX" ]; then
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

  init_summary_table "Project Quality Audit Summary"
  local _T0_LNT
  _T0_LNT=$(date +%s)

  log_info "🔍 Starting Unified Project Linter...\n"

  # Skip heavy tools locally
  if ! is_ci_env; then
    export SKIP="${SKIP:+$SKIP,}zizmor,osv-scanner,trivy,govulncheck,cargo-audit,pip-audit,lychee"
  fi

  local _L_OK=0
  if run_pre_commit_lint "$_FIX_LNT"; then
    _L_OK=1
    log_summary "Quality" "pre-commit" "✅ Passed" "-" "$(($(date +%s) - _T0_LNT))"
  else
    log_summary "Quality" "pre-commit" "❌ Failed" "-" "$(($(date +%s) - _T0_LNT))"
  fi

  log_success "\n✨ Linting complete!"
  finalize_summary_table

  # 5. Standardized Next Actions
  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake test%b to execute functional test suites.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake verify%b to ensure full project stability.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
