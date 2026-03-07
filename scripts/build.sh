#!/bin/sh
# scripts/build.sh - Unified Project Builder
# Consolidates goreleaser, go, npm, and python build systems into a professional CLI.
# Features: POSIX compliant, Execution Guard, SSoT Architecture, Professional UX.

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=1 # 0: quiet, 1: normal, 2: verbose
DRY_RUN=0

# Logging functions
log_info() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$BLUE" "$1" "$NC"; fi
}
log_success() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$GREEN" "$1" "$NC"; fi
}
log_warn() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; fi
}
log_error() {
  printf "%b%s%b\n" "$RED" "$1" "$NC" >&2
}
log_debug() {
  if [ "$VERBOSE" -ge 2 ]; then printf "[DEBUG] %s\n" "$1"; fi
}

# 1. Execution Context Guard
if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
  log_error "Error: This script must be run from the project root."
  exit 1
fi

# Help message
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

# Argument parsing
for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=1
    log_warn "Running in DRY-RUN mode. No changes will be applied."
    ;;
  -q | --quiet) VERBOSE=0 ;;
  -v | --verbose) VERBOSE=2 ;;
  -h | --help)
    show_help
    exit 0
    ;;
  esac
done

log_info "🏗️  Starting Project Build...\n"

run_build() {
  _CMD="$1"
  _DESC="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would run $_DESC [$_CMD]"
  else
    log_info "Running $_DESC..."
    eval "$_CMD"
  fi
}

# 2. Go build (GoReleaser or native)
if [ -f ".goreleaser.yaml" ] || [ -f ".goreleaser.yml" ]; then
  GORELEASER=${GORELEASER:-goreleaser}
  run_build "$GORELEASER build --snapshot --clean" "GoReleaser snapshot build"
elif [ -f "go.mod" ]; then
  run_build "go build ./..." "Go build (native)"
fi

# 3. Node.js build
if [ -f "package.json" ]; then
  if grep -q '"build":' package.json; then
    NPM=${NPM:-pnpm}
    run_build "$NPM run build" "Node.js build ($NPM)"
  fi
fi

# 4. Python build
if [ -f "pyproject.toml" ]; then
  VENV=${VENV:-.venv}
  PYTHON_BIN=""
  if [ -x "$VENV/bin/python3" ]; then
    PYTHON_BIN="$VENV/bin/python3"
  elif command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  fi

  if [ -n "$PYTHON_BIN" ]; then
    run_build "$PYTHON_BIN -m build" "Python build"
  fi
fi

log_success "\n✨ Build process finished."
