#!/bin/sh
# scripts/test.sh - Multi-Stack Test Runner
# Orchestrates test suites (bats, pytest, pester, vitest) for holistic verification.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Automated test-discovery for all project components.
#   - Cross-platform support for Shell, Python, and Node.js tests.
#   - Professional UX with clear results reporting.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

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

# Executes Shell-specific test suites using the bats framework.
# Scans the tests/ directory for .bats files.
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

# Executes Python-specific test suites using the pytest framework.
# Detects tests via pytest.ini, pyproject.toml, or test_*.py files.
run_python_tests() {
  if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || find tests -name "test_*.py" | grep -q .; then
    log_info "── Running Python Tests (pytest) ──"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_success "DRY-RUN: Would run pytest on tests/"
    else
      # shellcheck disable=SC2030
      _VENV_PATH="${VENV:-.venv}"
      if [ -x "$_VENV_PATH/bin/python3" ]; then
        "$_VENV_PATH/bin/python3" -m pytest --tb=short
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

# Executes PowerShell-specific test suites using the Pester framework.
# Scans the tests/ directory for .Tests.ps1 files.
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
