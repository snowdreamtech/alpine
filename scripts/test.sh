#!/bin/sh
# scripts/test.sh - Unified Project Test Runner
# Consolidates execution of bats, pytest, Pester, and other test suites.
# Features: POSIX compliant, Execution Guard, Auto-discovery, Professional UX.

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=1 # 0: quiet, 1: normal, 2: verbose

# Logging functions
log_info() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$BLUE" "$1" "$NC"; fi
}
log_success() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$GREEN" "$1" "$NC"; fi
}
log_warn() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; fi
}
log_error() {
  printf "%b%s%b\n" "$RED" "$1" "$NC" >&2
}
log_debug() {
  if [ "$VERBOSE" -ge 2 ]; then printf "[DEBUG] %s\n" "$1"; fi
}

# 1. Execution Context Guard
if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
  log_error "Error: This script must be run from the project root."
  exit 1
fi

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] [SUITE_TYPE]

Unified project test runner for Shell, Python, PowerShell, and more.

Options:
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
for arg in "$@"; do
  case "$arg" in
  -q | --quiet) VERBOSE=0 ;;
  -v | --verbose) VERBOSE=2 ;;
  -h | --help)
    show_help
    exit 0
    ;;
  shell | python | powershell | all)
    SUITE="$arg"
    ;;
  esac
done

log_info "🧪 Starting Unified Test Runner...\n"

run_shell_tests() {
  if [ -d "tests" ] && find tests -name "*.bats" | grep -q .; then
    log_info "── Running Shell Tests (bats) ──"
    if command -v bats >/dev/null 2>&1; then
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
    VENV=${VENV:-.venv}
    if [ -x "$VENV/bin/python3" ]; then
      "$VENV/bin/python3" -m pytest --tb=short
    elif command -v pytest >/dev/null 2>&1; then
      pytest --tb=short
    else
      log_warn "Warning: pytest not found. Skipping python tests."
    fi
  else
    log_debug "No python test indicators found. Skipping python tests."
  fi
}

run_powershell_tests() {
  if find tests -name "*.Tests.ps1" | grep -q .; then
    log_info "── Running PowerShell Tests (Pester) ──"
    if command -v pwsh >/dev/null 2>&1; then
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

log_success "\n✨ Test execution finished."
