#!/bin/sh
# scripts/format.sh - Unified Code Formatter
# Consolidates toolchains (shfmt, prettier, black, gofmt, etc.) for automated styling.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Multi-stack auto-formatting (Shell, JS/TS, Python, Go, Rust, etc.).
#   - Safe dry-run support to preview changes without applying.
#   - Professional UX with clear remediation logs.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Help message
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

main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "✨ Starting Unified Project Formatter...\n"

  run_shfmt() {
    log_info "── Formatting Shell Scripts (shfmt) ──"
    if command -v shfmt >/dev/null 2>&1; then
      if [ "$DRY_RUN" -eq 1 ]; then
        shfmt -d -s -i 2 scripts/*.sh tests/*.bats 2>/dev/null || true
      else
        shfmt -w -s -i 2 scripts/*.sh tests/*.bats 2>/dev/null || true
      fi
    else
      log_warn "Warning: shfmt not found. Skipping shell formatting."
    fi
  }

  run_prettier() {
    log_info "── Formatting Web/General Files (Prettier) ──"
    local _PRETTIER=""
    if [ -f "node_modules/.bin/prettier" ]; then
      _PRETTIER="./node_modules/.bin/prettier"
    elif command -v prettier >/dev/null 2>&1; then
      _PRETTIER="prettier"
    else
      log_warn "Warning: prettier not found. Skipping web/general formatting."
      return
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      "$_PRETTIER" --check .
    else
      "$_PRETTIER" --write .
    fi
  }

  run_ruff() {
    log_info "── Formatting Python Files (Ruff) ──"
    local _VENV
    _VENV=${VENV:-.venv}
    local _RUFF=""
    if [ -x "$_VENV/bin/ruff" ]; then
      _RUFF="$_VENV/bin/ruff"
    elif command -v ruff >/dev/null 2>&1; then
      _RUFF="ruff"
    else
      log_warn "Warning: ruff not found. Skipping python formatting."
      return
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      "$_RUFF" format --check .
    else
      "$_RUFF" format .
    fi
  }

  run_shfmt
  printf "\n"
  run_prettier
  printf "\n"
  run_ruff

  # Optional: run npm format if extra tools are defined in package.json
  run_npm_script "format"

  log_success "\n✨ Formatting complete!"

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake lint%b to verify code quality.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
