#!/usr/bin/env sh
# Capacitor Logic Module

# Purpose: Sets up Capacitor environment for project.
setup_capacitor() {
  local _T0_CAPACITOR_RT
  _T0_CAPACITOR_RT=$(date +%s)
  _log_setup "Capacitor" "capacitor"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Mobile Tool" "Capacitor" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Capacitor: check for capacitor.config.ts or capacitor.config.json
  if [ -f "capacitor.config.ts" ] || [ -f "capacitor.config.json" ]; then
    :
  else
    log_summary "Mobile Tool" "Capacitor" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_CAPACITOR_RT="✅ Detected"

  local _DUR_CAPACITOR_RT
  _DUR_CAPACITOR_RT=$(($(date +%s) - _T0_CAPACITOR_RT))
  log_summary "Mobile Tool" "Capacitor" "$_STAT_CAPACITOR_RT" "-" "$_DUR_CAPACITOR_RT"
}

# Purpose: Checks if Capacitor is relevant.
check_runtime_capacitor() {
  local _TOOL_DESC_CAPACITOR="${1:-Capacitor}"
  if [ -f "capacitor.config.ts" ] || [ -f "capacitor.config.json" ]; then
    return 0
  fi
  return 1
}
