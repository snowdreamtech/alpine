#!/usr/bin/env sh
# F# Logic Module

# Purpose: F# leverages the Dotnet runtime.
install_runtime_fsharp() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would verify Dotnet runtime for F#."
    return 0
  fi

  # Delegate to dotnet module if available, or just check dotnet
  if command -v dotnet >/dev/null 2>&1; then
    return 0
  fi

  # If dotnet is missing, we might need to install it via setup.sh dotnet call
  # For this module, we'll just report it as missing and let setup.sh handle the flow
  log_warn "Dotnet runtime required for F# is missing. Please run './setup.sh dotnet' first."
  return 1
}

# Purpose: Sets up F# environment for project.
setup_fsharp() {
  local _T0_FSH_RT
  _T0_FSH_RT=$(date +%s)
  _log_setup "F#" "dotnet"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "F#" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect F# files
  if ! has_lang_files "" "*.fs *.fsi *.fsx *.fsproj"; then
    log_summary "Runtime" "F#" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_FSH_RT="✅ Available"
  install_runtime_fsharp || _STAT_FSH_RT="⚠️ Missing"

  local _DUR_FSH_RT
  _DUR_FSH_RT=$(($(date +%s) - _T0_FSH_RT))

  local _FSH_VER="-"
  if command -v dotnet >/dev/null 2>&1; then
    _FSH_VER=$(dotnet --version)
  fi

  log_summary "Runtime" "F#" "$_STAT_FSH_RT" "$_FSH_VER" "$_DUR_FSH_RT"
}

# Purpose: Checks if F# is available (via dotnet).
check_runtime_fsharp() {
  local _TOOL_DESC_FSH="${1:-F#}"
  if ! command -v dotnet >/dev/null 2>&1; then
    log_warn "Required runtime 'dotnet' for $_TOOL_DESC_FSH is missing. Skipping."
    return 1
  fi
  return 0
}
