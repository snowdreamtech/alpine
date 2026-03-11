#!/bin/sh
# scripts/install.sh - Unified Dependency Orchestrator
#
# Purpose:
#   Consolidates disparate package managers (pnpm, pip, pre-commit) into a single CLI.
#   Ensures all environmental dependencies are installed and properly linked.
#
# Usage:
#   sh scripts/install.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General, Network), Rule 05 (Dependencies), Rule 08 (Dev Env).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Multi-stack dependency resolution and installation.
#   - Virtualenv aware for Python environments.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Extracts and installs Node.js dependencies using pnpm.
# Examples:
#   install_node_deps
install_node_deps() {
  if [ -f "$PACKAGE_JSON" ]; then
    if [ "$IN_INSTALL_SCRIPT" = "1" ]; then
      log_debug "Skipping recursive pnpm install call."
    else
      log_info "── Installing Node.js dependencies ($NPM) ──"
      if command -v "$NPM" >/dev/null 2>&1; then
        export IN_INSTALL_SCRIPT=1
        run_quiet "$NPM" install
      else
        log_warn "Warning: $NPM not found. Skipping Node.js dependencies."
      fi
    fi
  fi
}

# Purpose: Extracts and installs Python dependencies into a virtual environment.
# Examples:
#   install_python_deps
install_python_deps() {
  if [ -f "$REQUIREMENTS_TXT" ] || [ -f "requirements.txt" ] || [ -f "$PYPROJECT_TOML" ]; then
    printf "\n"
    log_info "── Installing Python dependencies ──"

    if [ ! -d "$VENV" ]; then
      log_info "Creating virtual environment in $VENV..."
      "$PYTHON" -m venv "$VENV"
    fi

    local _PIP_INST
    if [ -x "$VENV/bin/pip" ]; then
      _PIP_INST="$VENV/bin/pip"
    elif [ -x "$VENV/Scripts/pip.exe" ]; then
      _PIP_INST="$VENV/Scripts/pip.exe"
    else
      log_error "Error: pip not found in $VENV."
      exit 1
    fi

    if [ -f "$REQUIREMENTS_TXT" ]; then
      "$_PIP_INST" install -r "$REQUIREMENTS_TXT"
    elif [ -f "requirements.txt" ]; then
      "$_PIP_INST" install -r requirements.txt
    fi
  fi
}

# Purpose: Installs pre-commit hooks into the local .git directory.
# Examples:
#   install_git_hooks
install_git_hooks() {
  if [ -d ".git/hooks" ]; then
    local _PRE_COMMIT_BIN=""
    if [ -x "$VENV/bin/pre-commit" ]; then
      _PRE_COMMIT_BIN="$VENV/bin/pre-commit"
    elif [ -x "$VENV/Scripts/pre-commit.exe" ]; then
      _PRE_COMMIT_BIN="$VENV/Scripts/pre-commit.exe"
    elif command -v pre-commit >/dev/null 2>&1; then
      _PRE_COMMIT_BIN="pre-commit"
    fi

    if [ -n "$_PRE_COMMIT_BIN" ]; then
      printf "\n"
      log_info "── Installing pre-commit hooks ──"
      run_quiet "$_PRE_COMMIT_BIN" install
    fi
  fi
}

# Purpose: Main entry point for dependency installation.
#          Detects project type and runs appropriate package managers.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --verbose
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "📦 Installing Project Dependencies...\n"

  # 3. Execution
  install_node_deps
  install_python_deps
  install_git_hooks

  log_success "\n✨ All dependencies installed successfully!"

  # 4. Standardized Next Actions
  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake verify%b to ensure environment and project health.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake test%b to execute the functional test suite.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
