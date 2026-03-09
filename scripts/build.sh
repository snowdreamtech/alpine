#!/bin/sh
# scripts/build.sh - Unified Project Builder
# Consolidates goreleaser, go, npm, and python build systems into a professional CLI.
# Features: POSIX compliant, Execution Guard, SSoT Architecture, Professional UX.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

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
parse_common_args "$@"

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
run_npm_script "build"

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

log_success "✨ Build completed successfully! Check the 'out/' or 'dist/' directory."

# Next Actions
if [ "$DRY_RUN" -eq 0 ]; then
  printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
  printf "  - Run %bmake release%b to create a new version tag.\n" "${GREEN}" "${NC}"
fi
