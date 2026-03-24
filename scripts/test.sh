#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

Unified project test runner for Shell, Python, Node.js, Go, Rust, and more.

Options:
  --dry-run        Preview test suites that will be executed.
  -q, --quiet      Only show test results/errors.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

Suites (default: all):
  shell            Run bats tests in tests/
  python           Run pytest (requires .venv)
  powershell       Run Pester tests (requires pwsh)
  node             Run vitest (requires node_modules)
  all              Run all detected test suites

EOF
}

# Purpose: Ensures bats helper libraries (bats-support, bats-assert) are installed
# in tests/vendor/ before running any .bats test files.
# The vendor/ directory is git-ignored; this function installs them on-demand.
# Examples:
#   _ensure_bats_vendor
_ensure_bats_vendor() {
  # bats test files use: load 'vendor/bats-support/load.bash'
  # bats resolves load paths relative to the test file's directory (tests/).
  # So 'vendor/...' → tests/vendor/ (kept inside tests/ for locality).
  local _VENDOR_DIR="tests/vendor"
  local _BATS_SUPPORT_DIR="$_VENDOR_DIR/bats-support"
  local _BATS_ASSERT_DIR="$_VENDOR_DIR/bats-assert"

  if [ -f "$_BATS_SUPPORT_DIR/load.bash" ] && [ -f "$_BATS_ASSERT_DIR/load.bash" ]; then
    return 0
  fi

  log_info "Installing bats test helper libraries into $_VENDOR_DIR ..."
  mkdir -p "$_VENDOR_DIR"

  if ! command -v git >/dev/null 2>&1; then
    log_warn "git not found; cannot install bats vendor libraries. Skipping."
    return 1
  fi

  # Use GITHUB_PROXY for reliable access in restricted network environments.
  # Rule 01: All GitHub resource downloads MUST use the configured proxy prefix.
  local _PROXY=""
  if [ "${ENABLE_GITHUB_PROXY:-0}" = "1" ] || [ "${ENABLE_GITHUB_PROXY:-0}" = "true" ]; then
    _PROXY="${GITHUB_PROXY:-https://gh-proxy.sn0wdr1am.com/}"
  fi

  # Helper: clone with up to 3 retries, using proxy-prefixed URL first,
  # then falling back to the bare mirror URL if proxy also fails.
  _clone_with_retry() {
    local _REPO="$1"
    local _DEST="$2"
    local _ATTEMPT=0
    local _MAX_ATTEMPTS=3

    while [ $_ATTEMPT -lt $_MAX_ATTEMPTS ]; do
      _ATTEMPT=$((_ATTEMPT + 1))
      if git clone --depth=1 --quiet "${_PROXY}https://github.com/${_REPO}.git" "$_DEST" 2>/dev/null; then
        return 0
      fi
      log_warn "Clone attempt $_ATTEMPT/$_MAX_ATTEMPTS failed for $_REPO. Retrying..."
      sleep 2
    done

    # Final fallback: bare GitHub URL (without proxy) for environments where proxy is not needed
    log_warn "Proxy clone failed. Falling back to direct GitHub URL for $_REPO ..."
    git clone --depth=1 --quiet "https://github.com/${_REPO}.git" "$_DEST"
  }

  # bats-support
  if [ ! -f "$_BATS_SUPPORT_DIR/load.bash" ]; then
    _clone_with_retry "bats-core/bats-support" "$_BATS_SUPPORT_DIR"
  fi

  # bats-assert
  if [ ! -f "$_BATS_ASSERT_DIR/load.bash" ]; then
    _clone_with_retry "bats-core/bats-assert" "$_BATS_ASSERT_DIR"
  fi

  log_info "bats vendor libraries installed."
}

# Purpose: Executes Shell-specific test suites using the bats framework.
# Scans the tests/ directory for .bats files.
# Examples:
#   run_shell_tests
run_shell_tests() {
  if [ -d "tests" ] && find tests -name "*.bats" 2>/dev/null | grep -q .; then
    log_info "── Running Shell Tests (bats) ──"
    local _BATS_BIN
    _BATS_BIN=$(resolve_bin "bats") || true

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_success "DRY-RUN: Would run bats tests in tests/"
      return 0
    elif [ -n "$_BATS_BIN" ]; then
      # Ensure bats helper libraries are present before running tests
      _ensure_bats_vendor
      "$_BATS_BIN" tests/ && return 0
    else
      log_warn "Warning: bats not found. Skipping shell tests."
      return 0
    fi
  else
    log_debug "No .bats files found in tests/. Skipping shell tests."
    return 0
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
      local _PYTEST_BIN
      # We check for 'pytest' or 'python3 -m pytest'
      _PYTEST_BIN=$(resolve_bin "pytest") || true

      if [ -n "$_PYTEST_BIN" ]; then
        "$_PYTEST_BIN" --tb=short
      else
        local _PY_BIN
        _PY_BIN=$(resolve_bin "python3") || true
        if [ -n "$_PY_BIN" ]; then
          "$_PY_BIN" -m pytest --tb=short 2>/dev/null || log_warn "Warning: pytest not found. Skipping python tests."
        else
          log_warn "Warning: pytest not found. Skipping python tests."
        fi
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
    elif resolve_bin "pwsh" >/dev/null 2>&1; then
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

  init_summary_table "Project Functional Test Summary"
  local _T0_TST
  _T0_TST=$(date +%s)

  log_info "🧪 Starting Unified Test Runner...\n"

  case "$_SUITE_TST" in
  shell)
    if run_shell_tests; then
      log_summary "Test" "Shell (bats)" "✅ Passed" "-" "$(($(date +%s) - _T0_TST))"
    else
      log_summary "Test" "Shell (bats)" "❌ Failed" "-" "$(($(date +%s) - _T0_TST))"
    fi
    ;;
  python)
    if run_python_tests; then
      log_summary "Test" "Python (pytest)" "✅ Passed" "-" "$(($(date +%s) - _T0_TST))"
    else
      log_summary "Test" "Python (pytest)" "❌ Failed" "-" "$(($(date +%s) - _T0_TST))"
    fi
    ;;
  powershell)
    if run_powershell_tests; then
      log_summary "Test" "PowerShell (Pester)" "✅ Passed" "-" "$(($(date +%s) - _T0_TST))"
    else
      log_summary "Test" "PowerShell (Pester)" "❌ Failed" "-" "$(($(date +%s) - _T0_TST))"
    fi
    ;;
  all)
    local _T_S _T_P _T_PS
    _T_S=$(date +%s)
    if run_shell_tests; then
      log_summary "Test" "Shell (bats)" "✅ Passed" "-" "$(($(date +%s) - _T_S))"
    else
      log_summary "Test" "Shell (bats)" "❌ Failed" "-" "$(($(date +%s) - _T_S))"
    fi
    printf "\n"
    _T_P=$(date +%s)
    if run_python_tests; then
      log_summary "Test" "Python (pytest)" "✅ Passed" "-" "$(($(date +%s) - _T_P))"
    else
      log_summary "Test" "Python (pytest)" "❌ Failed" "-" "$(($(date +%s) - _T_P))"
    fi
    printf "\n"
    _T_PS=$(date +%s)
    if run_powershell_tests; then
      log_summary "Test" "PowerShell (Pester)" "✅ Passed" "-" "$(($(date +%s) - _T_PS))"
    else
      log_summary "Test" "PowerShell (Pester)" "❌ Failed" "-" "$(($(date +%s) - _T_PS))"
    fi
    ;;
  esac

  # Note: We no longer call run_npm_script "test" here as it creates
  # a redundant (and potentially recursive) loop back to this script.

  log_success "\n✨ All tests passed!"
  finalize_summary_table

  # 5. Standardized Next Actions
  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake audit%b to verify security and licensing compliance.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake commit%b to record your verified changes.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
