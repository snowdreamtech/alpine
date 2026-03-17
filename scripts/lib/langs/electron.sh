#!/usr/bin/env sh
# Electron Logic Module

# Purpose: Sets up Electron environment for project.
setup_electron() {
  local _T0_ELECTRON_RT
  _T0_ELECTRON_RT=$(date +%s)
  _log_setup "Electron" "electron"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Desktop Tool" "Electron" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Electron: check package.json
  if [ ! -f "package.json" ] || ! grep -q '"electron"' package.json; then
    log_summary "Desktop Tool" "Electron" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_ELECTRON_RT="✅ Detected"

  local _DUR_ELECTRON_RT
  _DUR_ELECTRON_RT=$(($(date +%s) - _T0_ELECTRON_RT))
  log_summary "Desktop Tool" "Electron" "$_STAT_ELECTRON_RT" "-" "$_DUR_ELECTRON_RT"
}

# Purpose: Checks if Electron is relevant.
check_runtime_electron() {
  local _TOOL_DESC_ELECTRON="${1:-Electron}"
  if [ -f "package.json" ] && grep -q '"electron"' package.json; then
    return 0
  fi
  return 1
}
