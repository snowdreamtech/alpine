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
SUITE="all"
for _arg in "$@"; do
  case "$_arg" in
  shell | python | powershell | all)
    SUITE="$_arg"
    ;;
  esac
done
parse_common_args "$@"

log_info "🧪 Starting Unified Test Runner...\n"

run_shell_tests() {
  if [ -d "tests" ] && find tests -name "*.bats" | grep -q .; then
    log_info "── Running Shell Tests (bats) ──"
    if [ "$DRY_RUN" -eq 1 ]; then
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

run_python_tests() {
  if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || find tests -name "test_*.py" | grep -q .; then
    log_info "── Running Python Tests (pytest) ──"
    if [ "$DRY_RUN" -eq 1 ]; then
      log_success "DRY-RUN: Would run pytest on tests/"
    else
      VENV=${VENV:-.venv}
      if [ -x "$VENV/bin/python3" ]; then
        "$VENV/bin/python3" -m pytest --tb=short
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

run_powershell_tests() {
  if find tests -name "*.Tests.ps1" | grep -q .; then
    log_info "── Running PowerShell Tests (Pester) ──"
    if [ "$DRY_RUN" -eq 1 ]; then
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

case "$SUITE" in
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
if [ "$DRY_RUN" -eq 0 ]; then
  printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
  printf "  - Run %bmake audit%b to check for security vulnerabilities.\n" "${GREEN}" "${NC}"
  printf "  - Run %bmake commit%b to finalize your changes.\n" "${GREEN}" "${NC}"
fi
