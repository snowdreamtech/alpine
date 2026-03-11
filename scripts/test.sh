#!/bin/sh
# scripts/test.sh - Multi-Stack Test Runner
#
# Purpose:
#   Orchestrates test suites (bats, pytest, pester, vitest) for holistic verification.
#   Ensures functional correctness across all supported project components.
#
# Usage:
#   sh scripts/test.sh [OPTIONS] [SUITE_TYPE]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General, Network), Rule 06 (CI/Testing).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Automated test-discovery for all project components.
#   - Cross-platform support (Shell, Python, Node.js, PowerShell).

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Purpose: Displays usage information for the multi-stack test runner.
# Examples:
#   show_help
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

# Purpose: Executes Shell-specific test suites using the bats framework.
# Scans the tests/ directory for .bats files.
# Examples:
#   run_shell_tests
run_shell_tests() {
  if [ -d "tests" ] && find tests -name "*.bats" | grep -q .; then
    log_info "── Running Shell Tests (bats) ──"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_success "DRY-RUN: Would run bats tests in tests/"
    elif command -v bats >/dev/null 2>&1; then
      bats tests/
    elif [ -f "node_modules/.bin/bats" ]; then
      ./node_modules/.bin/bats tests/
    else
      log_warn "Warning: bats not found. Skipping shell tests."
    fi
  else
    log_debug "No .bats files found in tests/. Skipping shell tests."
  fi
}

# Purpose: Executes Python-specific test suites using the pytest framework.
# Detects tests via pytest.ini, pyproject.toml, or test_*.py files.
# Examples:
#   run_python_tests
run_python_tests() {
  if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || find tests -name "test_*.py" | grep -q .; then
    log_info "── Running Python Tests (pytest) ──"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_success "DRY-RUN: Would run pytest on tests/"
    else
      # shellcheck disable=SC2030
      local _VENV_PATH_TST
      _VENV_PATH_TST="${VENV:-.venv}"
      if [ -x "$_VENV_PATH_TST/bin/python3" ]; then
        "$_VENV_PATH_TST/bin/python3" -m pytest --tb=short
      elif command -v pytest >/dev/null 2>&1; then
        pytest --tb=short
      else
        log_warn "Warning: pytest not found. Skipping python tests."
      fi
    fi
  else
    log_debug "No python test indicators found. Skipping python tests."
  fi
}

# Purpose: Executes PowerShell-specific test suites using the Pester framework.
# Scans the tests/ directory for .Tests.ps1 files.
# Examples:
#   run_powershell_tests
run_powershell_tests() {
  if [ -d "tests" ] && find tests -name "*.Tests.ps1" | grep -q .; then
    log_info "── Running PowerShell Tests (Pester) ──"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_success "DRY-RUN: Would run Pester tests in tests/"
    elif command -v pwsh >/dev/null 2>&1; then
      pwsh -NoProfile -Command "Invoke-Pester tests/"
    else
      log_warn "Warning: pwsh not found. Skipping powershell tests."
    fi
  else
    log_debug "No .Tests.ps1 files found in tests/. Skipping powershell tests."
  fi
}

# Purpose: Main entry point for the multi-stack test orchestration engine.
# Params:
#   $@ - Command line arguments and optional suite selection
# Examples:
#   main --verbose python
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _SUITE_TST="all"
  local _arg_tst
  for _arg_tst in "$@"; do
    case "$_arg_tst" in
    shell | python | powershell | all) _SUITE_TST="$_arg_tst" ;;
    -q | --quiet | -v | --verbose | --dry-run | -h | --help) ;;
    esac
  done
  parse_common_args "$@"

  log_info "🧪 Starting Unified Test Runner...\n"

  case "$_SUITE_TST" in
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

  # 5. Standardized Next Actions
  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake audit%b to verify security and licensing compliance.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake commit%b to record your verified changes.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
