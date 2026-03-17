#!/usr/bin/env sh
# Free Pascal (FPC) Logic Module

# Purpose: Installs Free Pascal Compiler (fpc) via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_fpc() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Free Pascal Compiler via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "fpc@${MISE_TOOL_VERSION_FPC}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up FPC environment for project.
setup_fpc() {
  local _T0_FPC_RT
  _T0_FPC_RT=$(date +%s)
  _log_setup "Free Pascal" "fpc"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Free Pascal" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Pascal files
  if ! has_lang_files "" "*.pas *.pp *.inc *.lpr"; then
    log_summary "Runtime" "Free Pascal" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_FPC_RT="✅ Installed"
  install_runtime_fpc || _STAT_FPC_RT="❌ Failed"

  local _DUR_FPC_RT
  _DUR_FPC_RT=$(($(date +%s) - _T0_FPC_RT))
  log_summary "Runtime" "Free Pascal" "$_STAT_FPC_RT" "$(get_version fpc -iV | head -n 1)" "$_DUR_FPC_RT"
}

# Purpose: Checks if FPC is available.
# Examples:
#   check_runtime_fpc "Linter"
check_runtime_fpc() {
  local _TOOL_DESC_FPC="${1:-Free Pascal}"
  if ! command -v fpc >/dev/null 2>&1; then
    log_warn "Required runtime 'fpc' for $_TOOL_DESC_FPC is missing. Skipping."
    return 1
  fi
  return 0
}
