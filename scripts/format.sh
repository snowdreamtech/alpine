#!/usr/bin/env sh
# scripts/format.sh - Unified Code Formatter
#
# Purpose:
#   Consolidates toolchains (shfmt, prettier, black, gofmt, etc.) for automated styling.
#   Optimizes code style across all project components using uniform rules.
#
# Usage:
#   sh scripts/format.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 02 (Coding Style).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Multi-stack auto-formatting (Shell, JS/TS, Python, Go, Rust, etc.).
#   - Safe dry-run support to preview changes without applying.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Displays usage information for the unified project formatter.
# Examples:
#   show_help
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Unified project formatter for Shell, Python, Node.js, and more.

Options:
  --dry-run        Check formatting without applying changes.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# Purpose: Formats shell scripts using the shfmt tool.
# Examples:
#   run_shfmt_format
run_shfmt_format() {
  log_info "── Formatting Shell Scripts (shfmt) ──"
  local _SHFMT_BIN
  _SHFMT_BIN=$(resolve_bin "shfmt")

  if [ -n "$_SHFMT_BIN" ]; then
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      "$_SHFMT_BIN" -d -s -i 2 scripts/ tests/ 2>/dev/null || true
    else
      "$_SHFMT_BIN" -w -s -i 2 scripts/ tests/ 2>/dev/null || true
    fi
  else
    log_warn "Warning: shfmt not found. Skipping shell formatting."
  fi
}

# Purpose: Formats web and general files using Prettier.
# Examples:
#   run_prettier_format
run_prettier_format() {
  log_info "── Formatting Web/General Files (Prettier) ──"
  local _PRETTIER_BIN
  _PRETTIER_BIN=$(resolve_bin "prettier")

  if [ -z "$_PRETTIER_BIN" ]; then
    log_warn "Warning: prettier not found. Skipping web/general formatting."
    return
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    "$_PRETTIER_BIN" --check .
  else
    "$_PRETTIER_BIN" --write .
  fi
}

# Purpose: Formats Python files using the Ruff tool.
# Examples:
#   run_ruff_format
run_ruff_format() {
  log_info "── Formatting Python Files (Ruff) ──"
  local _RUFF_FMT_BIN
  _RUFF_FMT_BIN=$(resolve_bin "ruff")

  if [ -z "$_RUFF_FMT_BIN" ]; then
    log_warn "Warning: ruff not found. Skipping python formatting."
    return
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    "$_RUFF_FMT_BIN" format --check .
  else
    "$_RUFF_FMT_BIN" format .
  fi
}

# Purpose: Main entry point for the unified project formatting engine.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --dry-run
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "✨ Starting Unified Project Formatter...\n"

  # 3. Individual Tool Orchestration
  run_shfmt_format
  printf "\n"
  run_prettier_format
  printf "\n"
  run_ruff_format

  # Optional: run format script if defined in package.json
  run_npm_script "format"

  log_success "\n✨ Formatting complete!"

  # 4. Standardized Next Actions
  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake lint%b to verify code quality standards.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake test%b to ensure functional integrity.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
