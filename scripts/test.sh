#!/bin/sh
# scripts/test.sh - Unified Project Test Runner
# Consolidates execution of bats, pytest, Pester, and other test suites.
# Features: POSIX compliant, Execution Guard, Auto-discovery, Professional UX.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] [SUITE_TYPE]

Unified project test runner for Shell, Python, PowerShell, and more.

Options:
  --dry-run        Preview test suites that will be executed.
  -q, --quiet      Only show test results/errors.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

Suites (default: all):
  shell            Run bats tests in tests/
  python           Run pytest (requires .venv)
  powershell       Run Pester tests (requires pwsh)
  all              Run all detected test suites

EOF
}

# Argument parsing
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  _SUITE="all"
  for _arg in "$@"; do
    case "$_arg" in
    shell | python | powershell | all) _SUITE="$_arg" ;;
    -q | --quiet | -v | --verbose | --dry-run | -h | --help) ;;
    esac
  done
  parse_common_args "$@"

  log_info "🧪 Starting Unified Test Runner...\n"

  case "$_SUITE" in
  shell) run_shell_tests ;;
  python) run_python_tests ;;
  powershell) run_powershell_tests ;;
  all)
    run_shell_tests
    printf "\n"
    run_python_tests
    printf "\n"
    run_powershell_tests
    ;;
  esac

  # Note: We no longer call run_npm_script "test" here as it creates
  # a redundant (and potentially recursive) loop back to this script.

  log_success "\n✨ All tests passed!"

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake audit%b to check for security vulnerabilities.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake commit%b to finalize your changes.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
