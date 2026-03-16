#!/bin/sh
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
  rubocop) check_runtime gem "$_LINTER_WRAP" ;;
  dart) check_runtime dart "$_LINTER_WRAP" ;;
  gofmt | cargo | goreleaser | actionlint | yamllint | typos | zig | cue | jsonnetfmt | buf | deno | hadolint | zizmor | task | dvc)
    # Binary tools delegated to lint-wrapper for path resolution and runtime guards.
    local _RT_CHECK="${_LINTER_WRAP}"
    [ "$_LINTER_WRAP" = "cargo" ] && _RT_CHECK="cargo"
    [ "$_LINTER_WRAP" = "gofmt" ] && _RT_CHECK="go"
    [ "$_LINTER_WRAP" = "goreleaser" ] && _RT_CHECK="goreleaser"
    [ "$_LINTER_WRAP" = "zig" ] && _RT_CHECK="zig"
    [ "$_LINTER_WRAP" = "cue" ] && _RT_CHECK="cue"
    [ "$_LINTER_WRAP" = "jsonnetfmt" ] && _RT_CHECK="jsonnet"
    [ "$_LINTER_WRAP" = "buf" ] && _RT_CHECK="buf"
    [ "$_LINTER_WRAP" = "deno" ] && _RT_CHECK="deno"
    [ "$_LINTER_WRAP" = "hadolint" ] && _RT_CHECK="hadolint"
    [ "$_LINTER_WRAP" = "zizmor" ] && _RT_CHECK="zizmor"
    [ "$_LINTER_WRAP" = "actionlint" ] && _RT_CHECK="actionlint"
    [ "$_LINTER_WRAP" = "yamllint" ] && _RT_CHECK="yamllint"
    [ "$_LINTER_WRAP" = "typos" ] && _RT_CHECK="typos"
    [ "$_LINTER_WRAP" = "task" ] && _RT_CHECK="task"
    [ "$_LINTER_WRAP" = "dvc" ] && _RT_CHECK="dvc"
    check_runtime "$_RT_CHECK" "$_LINTER_WRAP"
    ;;
  mix) check_runtime elixir "$_LINTER_WRAP" ;;
  scalafmt | google-java-format | ktlint) check_runtime java "$_LINTER_WRAP" ;;
  ormolu)
    if [ "$_G_OS" = "windows" ]; then
      log_info "⏭️  ormolu (Haskell) is skipped on Windows CI due to GHC candidate availability. Skipping."
      exit 0
    fi
    check_runtime ghc "$_LINTER_WRAP"
    ;;
  eslint | prettier | stylelint | spectral | sort-package-json | markdownlint-cli2 | taplo | dockerfile-utils | commitlint)
    check_runtime node "$_LINTER_WRAP"
    ;;
  psscriptanalyzer)
    check_runtime pwsh "$_LINTER_WRAP"
    ;;
  swiftformat | swiftlint)
    if [ "$(uname -s)" != "Darwin" ]; then
      log_info "⏭️  ${_LINTER_WRAP} is only supported on macOS. Skipping."
      exit 0
    fi
    ;;
  dotnet) check_runtime dotnet "$_LINTER_WRAP" ;;
  esac

  # 4. Execute Linter
  # shellcheck disable=SC2086
  exec "$_RESOLVED_BIN_WRAP" "$@"
}

main "$@"
