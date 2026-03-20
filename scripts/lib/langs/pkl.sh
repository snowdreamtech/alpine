#!/usr/bin/env sh
# Pkl Logic Module

# Purpose: Installs Pkl via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_pkl() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Pkl via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "pkl@$(get_mise_tool_version pkl)"
}

# Purpose: Sets up Pkl environment for project.
setup_pkl() {
  if ! has_lang_files "PklProject" "*.pkl"; then
    return 0
  fi

  local _T0_PKL_RT
  _T0_PKL_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version pkl)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "pkl")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Pkl" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "Pkl" "pkl"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Pkl" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_PKL_RT="✅ Installed"
  install_runtime_pkl || _STAT_PKL_RT="❌ Failed"

  local _DUR_PKL_RT
  _DUR_PKL_RT=$(($(date +%s) - _T0_PKL_RT))
  log_summary "Runtime" "Pkl" "$_STAT_PKL_RT" "$(get_version pkl --version)" "$_DUR_PKL_RT"
}

# Purpose: Checks if Pkl is available.
# Examples:
#   check_runtime_pkl "Linter"
check_runtime_pkl() {
  local _TOOL_DESC_PKL="${1:-Pkl}"
  if ! command -v pkl >/dev/null 2>&1; then
    log_warn "Required runtime 'pkl' for $_TOOL_DESC_PKL is missing. Skipping."
    return 1
  fi
  return 0
}
