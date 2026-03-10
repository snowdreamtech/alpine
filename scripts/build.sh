#!/bin/sh
# scripts/build.sh - Unified Project Builder
#
# Purpose:
#   Orchestrates multi-stack build systems (npm, go, python, goreleaser) into a single CLI.
#   Generates production-ready artifacts and distributions for all supported languages.
#
# Usage:
#   sh scripts/build.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Multi-language artifact generation.
#   - Environment-aware build routing.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Purpose: Displays usage information for the project builder.
# Examples:
#   show_help
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Builds project artifacts for all detected language stacks.

Options:
  --dry-run        Preview build commands without executing them.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

Environment Variables:
  GORELEASER       GoReleaser client (default: goreleaser)
  NPM              NPM client (default: pnpm)
  PYTHON           Python executable (default: python3)
  VENV             Virtualenv directory (default: .venv)

EOF
}

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Safe wrapper for executing build commands with logging.
# Params:
#   $1 - Build command to execute
#   $2 - Human-readable description of the build step
# Examples:
#   run_build "go build ./..." "Go build (native)"
run_build() {
  local _CMD_BLD="$1"
  local _DESC_BLD="$2"

  log_info "── Step: $_DESC_BLD ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_success "DRY-RUN: Would run: $_CMD_BLD"
  else
    # shellcheck disable=SC2086
    eval "$_CMD_BLD"
  fi
}

# Purpose: Main entry point for the project building engine.
#          Detects project type and runs appropriate build commands.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --verbose
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "🏗️  Starting Project Build...\n"

  # 3. Go build (GoReleaser or native)
  if [ -f ".goreleaser.yaml" ] || [ -f ".goreleaser.yml" ]; then
    local _GORELEASER_BIN
    _GORELEASER_BIN=${GORELEASER:-goreleaser}
    run_build "$_GORELEASER_BIN build --snapshot --clean" "GoReleaser snapshot build"
  elif [ -f "go.mod" ]; then
    run_build "go build ./..." "Go build (native)"
  fi

  # 4. Node.js build
  run_npm_script "build"

  # 5. Python build
  if [ -f "pyproject.toml" ]; then
    local _VENV_BLD
    _VENV_BLD=${VENV:-.venv}
    local _PYTHON_BLD_BIN=""
    if [ -x "$_VENV_BLD/bin/python3" ]; then
      _PYTHON_BLD_BIN="$_VENV_BLD/bin/python3"
    elif command -v python3 >/dev/null 2>&1; then
      _PYTHON_BLD_BIN="python3"
    fi

    if [ -n "$_PYTHON_BLD_BIN" ]; then
      run_build "$_PYTHON_BLD_BIN -m build" "Python build"
    fi
  fi

  log_success "✨ Build completed successfully! Check the 'out/' or 'dist/' directory."

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake release%b to create a new version tag.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
