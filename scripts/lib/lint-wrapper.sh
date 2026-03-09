#!/bin/sh
# scripts/lib/lint-wrapper.sh - Robust wrapper for pre-commit hooks.
# Ensures that optional linters skip gracefully if tools/runtimes are missing.
# Usage: sh scripts/lib/lint-wrapper.sh LINTER_NAME [ARGS...]
# Features: POSIX compliant, Graceful tool detection, Cross-platform runtime checks.

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"

main() {
  _LINTER="$1"
  [ -z "$_LINTER" ] && return 0
  shift

  # 1. Resolve Binary Path
  # Check .venv/bin (POSIX), .venv/Scripts (Windows), node_modules/.bin, and PATH
  _VENV_BIN=".venv/bin/${_LINTER}"
  _VENV_SCRIPTS=".venv/Scripts/${_LINTER}"
  _VENV_EXE_BIN=".venv/bin/${_LINTER}.exe"
  _VENV_EXE_SCRIPTS=".venv/Scripts/${_LINTER}.exe"
  _NODE_BIN="node_modules/.bin/${_LINTER}"
  _NODE_CMD="node_modules/.bin/${_LINTER}.cmd"

  _RESOLVED_BIN=""

  if [ -x "$_VENV_BIN" ]; then
    _RESOLVED_BIN="$_VENV_BIN"
  elif [ -x "$_VENV_EXE_BIN" ]; then
    _RESOLVED_BIN="$_VENV_EXE_BIN"
  elif [ -x "$_VENV_SCRIPTS" ]; then
    _RESOLVED_BIN="$_VENV_SCRIPTS"
  elif [ -x "$_VENV_EXE_SCRIPTS" ]; then
    _RESOLVED_BIN="$_VENV_EXE_SCRIPTS"
  elif [ -x "$_NODE_BIN" ]; then
    _RESOLVED_BIN="$_NODE_BIN"
  elif [ -x "$_NODE_CMD" ]; then
    _RESOLVED_BIN="$_NODE_CMD"
  elif command -v "$_LINTER" >/dev/null 2>&1; then
    _RESOLVED_BIN="$_LINTER"
  fi

  # 2. Check Existence
  if [ -z "$_RESOLVED_BIN" ]; then
    log_warn "⚠️  ${_LINTER} not found. Skipping linting for this module."
    log_info "💡 Run 'make setup' to install required tools."
    exit 0
  fi

  # 3. Special Runtime Checks
  case "$_LINTER" in
  google-java-format | ktlint) check_runtime java "$_LINTER" ;;
  php-cs-fixer) check_runtime php "$_LINTER" ;;
  rubocop) check_runtime gem "$_LINTER" ;;
  dart) check_runtime dart "$_LINTER" ;;
  gofmt | cargo | goreleaser)
    # cargo and gofmt require their respective toolchains
    _RT="${_LINTER}"
    [ "$_LINTER" = "cargo" ] && _RT="cargo"
    [ "$_LINTER" = "gofmt" ] && _RT="go"
    [ "$_LINTER" = "goreleaser" ] && _RT="goreleaser"
    check_runtime "$_RT" "$_LINTER"
    ;;
  eslint | prettier | stylelint | spectral | sort-package-json | markdownlint-cli2 | taplo | dockerfile-utils | editorconfig-checker | commitlint)
    check_runtime node "$_LINTER"
    ;;
  swiftformat | swiftlint)
    if [ "$(uname -s)" != "Darwin" ]; then
      log_info "⏭️  ${_LINTER} is only supported on macOS. Skipping."
      exit 0
    fi
    ;;
  dotnet) check_runtime dotnet "$_LINTER" ;;
  esac

  # 4. Execute Linter
  # shellcheck disable=SC2086
  exec "$_RESOLVED_BIN" "$@"
}

main "$@"
