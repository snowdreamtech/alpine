#!/bin/sh
# scripts/lib/lint-wrapper.sh - Robust wrapper for pre-commit hooks.
# Ensures that optional linters skip gracefully if tools/runtimes are missing.
# Usage: sh scripts/lib/lint-wrapper.sh LINTER_NAME [ARGS...]
# Features: POSIX compliant, Graceful tool detection, Cross-platform runtime checks.

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"

# Robust wrapper for individual pre-commit hooks or linters.
# Ensures that optional linters skip gracefully if specialized tools or runtimes are missing.
#
# @param $1 - Linter binary/hook name (e.g., "eslint", "gofmt")
# @param $@ - Arguments passed to the linter
# @returns 0 if linter succeeds or is skipped; otherwise returns linter exit code.
main() {
  local _LINTER_WRAP="$1"
  [ -z "$_LINTER_WRAP" ] && return 0
  shift

  # 1. Resolve Binary Path
  # Check .venv/bin (POSIX), .venv/Scripts (Windows), node_modules/.bin, and PATH
  local _VENV_BIN_WRAP=".venv/bin/${_LINTER_WRAP}"
  local _VENV_SCRIPTS_WRAP=".venv/Scripts/${_LINTER_WRAP}"
  local _VENV_EXE_BIN_WRAP=".venv/bin/${_LINTER_WRAP}.exe"
  local _VENV_EXE_SCRIPTS_WRAP=".venv/Scripts/${_LINTER_WRAP}.exe"
  local _NODE_BIN_WRAP="node_modules/.bin/${_LINTER_WRAP}"
  local _NODE_CMD_WRAP="node_modules/.bin/${_LINTER_WRAP}.cmd"

  local _RESOLVED_BIN_WRAP=""

  if [ -x "$_VENV_BIN_WRAP" ]; then
    _RESOLVED_BIN_WRAP="$_VENV_BIN_WRAP"
  elif [ -x "$_VENV_EXE_BIN_WRAP" ]; then
    _RESOLVED_BIN_WRAP="$_VENV_EXE_BIN_WRAP"
  elif [ -x "$_VENV_SCRIPTS_WRAP" ]; then
    _RESOLVED_BIN_WRAP="$_VENV_SCRIPTS_WRAP"
  elif [ -x "$_VENV_EXE_SCRIPTS_WRAP" ]; then
    _RESOLVED_BIN_WRAP="$_VENV_EXE_SCRIPTS_WRAP"
  elif [ -x "$_NODE_BIN_WRAP" ]; then
    _RESOLVED_BIN_WRAP="$_NODE_BIN_WRAP"
  elif [ -x "$_NODE_CMD_WRAP" ]; then
    _RESOLVED_BIN_WRAP="$_NODE_CMD_WRAP"
  elif command -v "$_LINTER_WRAP" >/dev/null 2>&1; then
    _RESOLVED_BIN_WRAP="$_LINTER_WRAP"
  fi

  # 2. Check Existence
  if [ -z "$_RESOLVED_BIN_WRAP" ]; then
    log_warn "⚠️  ${_LINTER_WRAP} not found. Skipping linting for this module."
    log_info "💡 Run 'make setup' to install required tools."
    exit 0
  fi

  # 3. Special Runtime Checks (Fail-Fast for missing language foundations)
  case "$_LINTER_WRAP" in
  google-java-format | ktlint) check_runtime java "$_LINTER_WRAP" ;;
  php-cs-fixer) check_runtime php "$_LINTER_WRAP" ;;
  rubocop) check_runtime gem "$_LINTER_WRAP" ;;
  dart) check_runtime dart "$_LINTER_WRAP" ;;
  gofmt | cargo | goreleaser)
    # cargo and gofmt require their respective toolchains
    local _RT_WRAP="${_LINTER_WRAP}"
    [ "$_LINTER_WRAP" = "cargo" ] && _RT_WRAP="cargo"
    [ "$_LINTER_WRAP" = "gofmt" ] && _RT_WRAP="go"
    [ "$_LINTER_WRAP" = "goreleaser" ] && _RT_WRAP="goreleaser"
    check_runtime "$_RT_WRAP" "$_LINTER_WRAP"
    ;;
  eslint | prettier | stylelint | spectral | sort-package-json | markdownlint-cli2 | taplo | dockerfile-utils | editorconfig-checker | commitlint)
    check_runtime node "$_LINTER_WRAP"
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
