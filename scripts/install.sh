#!/bin/sh
# scripts/install.sh - Unified Dependency Orchestrator
# Consolidates disparate package managers (pnpm, pip, pre-commit) into a single CLI.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Multi-stack dependency resolution and installation.
#   - Virtualenv aware for Python environments.
#   - Professional UX with clear installation metrics.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "📦 Installing Project Dependencies...\n"

  # 2. Node.js dependencies
  if [ -f "$PACKAGE_JSON" ]; then
    if [ "$IN_INSTALL_SCRIPT" = "1" ]; then
      log_debug "Skipping recursive pnpm install call."
    else
      log_info "── Installing Node.js dependencies ($NPM) ──"
      if command -v "$NPM"; then
        export IN_INSTALL_SCRIPT=1
        run_quiet "$NPM" install
      else
        log_warn "Warning: $NPM not found. Skipping Node.js dependencies."
      fi
    fi
  fi

  # 3. Python dependencies
  if [ -f "$REQUIREMENTS_TXT" ] || [ -f "requirements.txt" ] || [ -f "$PYPROJECT_TOML" ]; then
    printf "\n"
    log_info "── Installing Python dependencies ──"

    if [ ! -d "$VENV" ]; then
      log_info "Creating virtual environment in $VENV..."
      "$PYTHON" -m venv "$VENV"
    fi

    if [ -x "$VENV/bin/pip" ]; then
      _PIP="$VENV/bin/pip"
    elif [ -x "$VENV/Scripts/pip.exe" ]; then
      _PIP="$VENV/Scripts/pip.exe"
    else
      log_error "Error: pip not found in $VENV."
      exit 1
    fi

    if [ -f "$REQUIREMENTS_TXT" ]; then
      "$_PIP" install -r "$REQUIREMENTS_TXT"
    elif [ -f "requirements.txt" ]; then
      "$_PIP" install -r requirements.txt
    fi
  fi

  # 4. Git Hooks (if setup script already ran)
  if [ -d ".git/hooks" ] && command -v pre-commit; then
    printf "\n"
    log_info "── Installing pre-commit hooks ──"
    run_quiet pre-commit install
  fi

  log_success "\n✨ All dependencies installed successfully!"

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake verify%b to ensure environment health.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake audit%b to check for security vulnerabilities.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
