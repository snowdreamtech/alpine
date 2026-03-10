#!/bin/sh
# scripts/health.sh - Unified Project Health Dashboard
#
# Purpose:
#   Provides a "Single Pane of Glass" view of the project's health by consolidating
#   results from environment checks, linting, testing, and security auditing.
#
# Usage:
#   sh scripts/health.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 06 (CI/Testing).
#
# Features:
#   - Aggregates multiple quality gates.
#   - Produces a professional Markdown health summary.
#
# shellcheck disable=SC2034

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Purpose: Main entry point for the health dashboard aggregation engine.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --output=health_report.md
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  local _OUTPUT_FILE=""
  local _arg_h
  for _arg_h in "$@"; do
    case "$_arg_h" in
    --output=*) _OUTPUT_FILE="${_arg_h#*=}" ;;
    esac
  done

  # 3. Inform User
  printf "%b🚀 Generating Unified Project Health Dashboard...%b\n\n" "${BLUE}" "${NC}"

  # 4. Define Check Functions
  # Each check returns a Status (Passed/Failed/Skipped) and a brief Detail.

  local _HEALTH_REPORT
  _HEALTH_REPORT="health_report_$(date +%Y%m%d_%H%M%S).md"
  [ -n "$_OUTPUT_FILE" ] && _HEALTH_REPORT="$_OUTPUT_FILE"

  # Temporary report buffer
  local _TMP_REPORT
  _TMP_REPORT="/tmp/project_health_$$.md"

  cat <<EOF >"$_TMP_REPORT"
# Project Health Dashboard

> Generated on: $(date)
> Target OS: $OS_NAME

## 🛡️ Quality Gate Summary

| Check Suite | Status | Detail |
| :--- | :--- | :--- |
EOF

  # --- Check 1: Environment Health ---
  printf "Checking Environment... "
  local _ENV_STATUS="✅ Passed"
  local _ENV_DETAIL="Validated via check-env.sh"
  if ! sh "$SCRIPT_DIR/check-env.sh" >/dev/null 2>&1; then
    _ENV_STATUS="❌ Failed"
    # shellcheck disable=SC2016
    _ENV_DETAIL='Run `make check-env` for details'
  fi
  printf "%s\n" "$_ENV_STATUS"
  # shellcheck disable=SC2016
  printf "| Environment | %s | %s |\n" "$_ENV_STATUS" "$_ENV_DETAIL" >>"$_TMP_REPORT"

  # --- Check 2: Standards (Lint) ---
  printf "Checking Standards... "
  local _LINT_STATUS="✅ Passed"
  local _LINT_DETAIL="All pre-commit hooks passed"
  if ! sh "$SCRIPT_DIR/lint.sh" >/dev/null 2>&1; then
    _LINT_STATUS="❌ Failed"
    # shellcheck disable=SC2016
    _LINT_DETAIL='Run `make lint` to fix issues'
  fi
  printf "%s\n" "$_LINT_STATUS"
  # shellcheck disable=SC2016
  printf "| Standards (Lint) | %s | %s |\n" "$_LINT_STATUS" "$_LINT_DETAIL" >>"$_TMP_REPORT"

  # --- Check 3: Logic (Test) ---
  printf "Checking Logic... "
  local _TEST_STATUS="✅ Passed"
  local _TEST_DETAIL="Unified test suite passed"
  if ! sh "$SCRIPT_DIR/test.sh" >/dev/null 2>&1; then
    _TEST_STATUS="❌ Failed"
    # shellcheck disable=SC2016
    _TEST_DETAIL='Run `make test` for failure logs'
  fi
  printf "%s\n" "$_TEST_STATUS"
  # shellcheck disable=SC2016
  printf "| Logic (Test) | %s | %s |\n" "$_TEST_STATUS" "$_TEST_DETAIL" >>"$_TMP_REPORT"

  # --- Check 4: Security (Audit) ---
  printf "Checking Security... "
  local _AUDIT_STATUS="✅ Passed"
  local _AUDIT_DETAIL="No critical vulnerabilities found"
  if ! sh "$SCRIPT_DIR/audit.sh" >/dev/null 2>&1; then
    _AUDIT_STATUS="⚠️  Warning"
    _AUDIT_DETAIL="Vulnerabilities or leaks detected"
  fi
  printf "%s\n" "$_AUDIT_STATUS"
  printf "| Security (Audit) | %s | %s |\n" "$_AUDIT_STATUS" "$_AUDIT_DETAIL" >>"$_TMP_REPORT"

  cat <<EOF >>"$_TMP_REPORT"

## 🚀 Next Steps

- Review the detailed logs if any check failed.
- Run \`make verify\` for a high-verbosity verification run.
- Keep standardizing and shifting-left!
EOF

  # 5. Result
  if [ "$DRY_RUN" -eq 0 ]; then
    cp "$_TMP_REPORT" "$_HEALTH_REPORT"
    rm "$_TMP_REPORT"
    log_success "\n✨ Health check complete! Report saved to: $_HEALTH_REPORT"

    # Print the table to console
    printf "\n"
    head -n 12 "$_HEALTH_REPORT" | tail -n 5
    printf "\n"
  else
    log_warn "DRY-RUN: Report skipped."
  fi
}

main "$@"
