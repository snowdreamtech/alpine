#!/usr/bin/env sh
# scripts/lib/lint-wrapper.sh - Robust wrapper for pre-commit hooks.
#
# Purpose:
#   Ensures that optional linters skip gracefully if specialized tools
#   or runtimes are missing, maintaining cross-platform integrity.
#
# Usage:
#   sh scripts/lib/lint-wrapper.sh LINTER_NAME [ARGS...]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 02 (Coding Style).
#
# Features:
#   - Dynamic binary resolution (.venv, node_modules, PATH).
#   - Native runtime detection (Java, Ruby, Node, Dart, DOTNET).
#   - OS-specific guards (Apple Swift).
set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Main entry point for the linter delegation engine.
#          Resolves the linter binary path and performs language-specific checks.
# Params:
#   $1 - Linter binary/hook name (e.g., "eslint", "gofmt")
#   $@ - Arguments passed to the linter
# Examples:
#   main eslint --fix path/to/file.js
main() {
  local _LINTER_WRAP="$1"
  [ -z "$_LINTER_WRAP" ] && return 0
  shift

  # 1. Resolve Binary Path
  local _LINTER_BIN="$_LINTER_WRAP"
  case "$_LINTER_WRAP" in
  psscriptanalyzer) _LINTER_BIN="pwsh" ;;
  esac

  local _RESOLVED_BIN_WRAP
  _RESOLVED_BIN_WRAP=$(resolve_bin "$_LINTER_BIN")

  # 2. Check Existence
  if [ -z "$_RESOLVED_BIN_WRAP" ]; then
    log_warn "⚠️  ${_LINTER_WRAP} not found. Skipping linting for this module."
    log_info "💡 Run 'make setup' to install required tools."
    exit 0
  fi

  # 3. Special Runtime Checks (Fail-Fast for missing language foundations)
  case "$_LINTER_WRAP" in
  rubocop) check_runtime ruby "$_LINTER_WRAP" ;;
  dart) check_runtime dart "$_LINTER_WRAP" ;;
  mix) check_runtime elixir "$_LINTER_WRAP" ;;
  scalafmt | google-java-format | ktlint) check_runtime java "$_LINTER_WRAP" ;;
  ormolu)
    if [ "$_G_OS" = "windows" ]; then
      log_info "⏭️  ormolu (Haskell) is skipped on Windows CI due to GHC candidate availability. Skipping."
      exit 0
    fi
    check_runtime haskell "$_LINTER_WRAP"
    ;;
  eslint | prettier | stylelint | spectral | sort-package-json | markdownlint-cli2 | taplo | dockerfile-utils | commitlint)
    check_runtime node "$_LINTER_WRAP"
    ;;
  psscriptanalyzer)
    # Binary is pwsh, but check_runtime can use pwsh direct or a module if we had one
    check_runtime pwsh "$_LINTER_WRAP"
    ;;
  swiftformat | swiftlint)
    if [ "$(uname -s)" != "Darwin" ]; then
      log_info "⏭️  ${_LINTER_WRAP} is only supported on macOS. Skipping."
      exit 0
    fi
    check_runtime swift "$_LINTER_WRAP"
    ;;
  dotnet) check_runtime dotnet "$_LINTER_WRAP" ;;
  gofmt) check_runtime go "$_LINTER_WRAP" ;;
  cargo) check_runtime rust "$_LINTER_WRAP" ;;
  *)
    # Generic fallback for other binary tools (typos, yamllint, etc.)
    # If a module exists for the tool name, it will be used.
    check_runtime "$_LINTER_WRAP" "$_LINTER_WRAP"
    ;;
  esac

  # 4. Execute Linter
  # shellcheck disable=SC2086
  exec "$_RESOLVED_BIN_WRAP" "$@"
}

main "$@"
