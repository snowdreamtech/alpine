#!/bin/sh
# scripts/lib/lint-wrapper.sh - Robust wrapper for pre-commit hooks.
# Ensures that optional linters skip gracefully if tools/runtimes are missing.
# Usage: sh scripts/lib/lint-wrapper.sh LINTER_NAME [ARGS...]
# Features: POSIX compliant, Graceful tool detection, Cross-platform runtime checks.

LINTER="$1"
shift

# 1. Resolve Binary Path
# Check .venv/bin (POSIX), .venv/Scripts (Windows), node_modules/.bin, and PATH
VENV_BIN=".venv/bin/${LINTER}"
VENV_SCRIPTS=".venv/Scripts/${LINTER}"
VENV_EXE_BIN=".venv/bin/${LINTER}.exe"
VENV_EXE_SCRIPTS=".venv/Scripts/${LINTER}.exe"
NODE_BIN="node_modules/.bin/${LINTER}"
NODE_CMD="node_modules/.bin/${LINTER}.cmd"

# Load common library for shared helpers (check_runtime, logging)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"

RESOLVED_BIN=""

if [ -x "$VENV_BIN" ]; then
  RESOLVED_BIN="$VENV_BIN"
elif [ -x "$VENV_EXE_BIN" ]; then
  RESOLVED_BIN="$VENV_EXE_BIN"
elif [ -x "$VENV_SCRIPTS" ]; then
  RESOLVED_BIN="$VENV_SCRIPTS"
elif [ -x "$VENV_EXE_SCRIPTS" ]; then
  RESOLVED_BIN="$VENV_EXE_SCRIPTS"
elif [ -x "$NODE_BIN" ]; then
  RESOLVED_BIN="$NODE_BIN"
elif [ -x "$NODE_CMD" ]; then
  RESOLVED_BIN="$NODE_CMD"
elif command -v "$LINTER" >/dev/null 2>&1; then
  RESOLVED_BIN="$LINTER"
fi

# 2. Check Existence
if [ -z "$RESOLVED_BIN" ]; then
  log_warn "⚠️  ${LINTER} not found. Skipping linting for this module."
  log_info "💡 Run 'make setup' to install required tools."
  exit 0
fi

# 3. Special Runtime Checks
case "$LINTER" in
google-java-format | ktlint) check_runtime java "$LINTER" ;;
php-cs-fixer) check_runtime php "$LINTER" ;;
rubocop) check_runtime gem "$LINTER" ;;
dart) check_runtime dart "$LINTER" ;;
gofmt | cargo | goreleaser)
  # cargo and gofmt require their respective toolchains
  _RT="${LINTER}"
  [ "$LINTER" = "cargo" ] && _RT="cargo"
  [ "$LINTER" = "gofmt" ] && _RT="go"
  [ "$LINTER" = "goreleaser" ] && _RT="goreleaser"
  check_runtime "$_RT" "$LINTER"
  ;;
eslint | prettier | stylelint | spectral | sort-package-json | markdownlint-cli2 | taplo | dockerfile-utils | editorconfig-checker | commitlint)
  check_runtime node "$LINTER"
  ;;
swiftformat | swiftlint)
  if [ "$(uname -s)" != "Darwin" ]; then
    log_info "⏭️  ${LINTER} is only supported on macOS. Skipping."
    exit 0
  fi
  ;;
dotnet) check_runtime dotnet "$LINTER" ;;
esac

# 4. Execute Linter
# shellcheck disable=SC2086
exec "$RESOLVED_BIN" "$@"
