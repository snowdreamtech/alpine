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
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "🏗️  Starting Project Build...\n"

  # 3. Go build (GoReleaser or native)
  if [ -f ".goreleaser.yaml" ] || [ -f ".goreleaser.yml" ]; then
    _GORELEASER=${GORELEASER:-goreleaser}
    run_build "$_GORELEASER build --snapshot --clean" "GoReleaser snapshot build"
  elif [ -f "go.mod" ]; then
    run_build "go build ./..." "Go build (native)"
  fi

  # 4. Node.js build
  run_npm_script "build"

  # 5. Python build
  if [ -f "pyproject.toml" ]; then
    _VENV=${VENV:-.venv}
    _PYTHON_BIN=""
    if [ -x "$_VENV/bin/python3" ]; then
      _PYTHON_BIN="$_VENV/bin/python3"
    elif command -v python3 >/dev/null 2>&1; then
      _PYTHON_BIN="python3"
    fi

    if [ -n "$_PYTHON_BIN" ]; then
      run_build "$_PYTHON_BIN -m build" "Python build"
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
