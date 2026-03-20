#!/usr/bin/env sh
# scripts/install.sh - Unified Dependency Orchestrator
#
# Purpose:
#   Consolidates disparate package managers (Node.js, pip, pre-commit) into a single CLI.
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

# ── Extension Modules Sourcing ───────────────────────────────────────────────
# Dynamically load all language-specific setup modules.
for _lang_mod in "${SCRIPT_DIR}/lib/langs"/*.sh; do
  if [ -f "$_lang_mod" ]; then
    # shellcheck disable=SC1090
    . "$_lang_mod"
  fi
done
unset _lang_mod

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Extracts and installs Node.js dependencies using the detected manager.
# Examples:
#   install_node_deps
install_node_deps() {
  if [ -f "$PACKAGE_JSON" ]; then
    log_info "── Installing Node.js dependencies ──"
    install_runtime_node
  fi
}

# Purpose: Extracts and installs Python dependencies into a virtual environment.
# Examples:
#   install_python_deps
install_python_deps() {
  if [ -f "$REQUIREMENTS_TXT" ] || [ -f "$PYPROJECT_TOML" ]; then
    printf "\n"
    log_info "── Installing Python dependencies ──"
    install_runtime_python
  fi
}

# Purpose: Installs pre-commit hooks into the local .git directory.
# Examples:
#   install_git_hooks
install_git_hooks() {
  if [ -d ".git" ]; then
    printf "\n"
    log_info "── Installing pre-commit hooks ──"
    install_runtime_hooks
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

  # ── Concurrency Guard (Lockfile) ──
  # Using project-local lock to allow concurrent setup in different clones/test environments
  local _LOCKFILE="${_G_PROJECT_ROOT}/.setup.lock"
  if [ -f "$_LOCKFILE" ]; then
    local _PID
    _PID=$(cat "$_LOCKFILE")
    if ps -p "$_PID" >/dev/null 2>&1; then
      log_error "Setup or installation already in progress (PID: $_PID)."
      log_info "If you are sure no other task is running, you can:"
      log_info "  1. Kill the process: kill -9 $_PID"
      log_info "  2. Remove the lock: rm -f $_LOCKFILE"
      exit 1
    else
      log_warn "Stale lockfile detected (PID: $_PID is dead). Cleaning up..."
      rm -f "$_LOCKFILE"
    fi
  fi
  echo "$$" >"$_LOCKFILE"
  # shellcheck disable=SC2064
  trap "rm -f $_LOCKFILE" EXIT INT TERM

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
