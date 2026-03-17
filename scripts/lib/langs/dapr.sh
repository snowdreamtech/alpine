#!/usr/bin/env sh
# Dapr Logic Module

# Purpose: Sets up Dapr environment for project.
setup_dapr() {
  local _T0_DAPR_RT
  _T0_DAPR_RT=$(date +%s)
  _log_setup "Dapr" "dapr"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Cloud Tool" "Dapr" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Dapr: check for dapr components (YAML with dapr.io) or dapr/ folder
  if [ -d "dapr" ] || grep -rq "dapr.io" . --include="*.yaml" --include="*.yml" 2>/dev/null; then
    :
  else
    log_summary "Cloud Tool" "Dapr" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_DAPR_RT="✅ Detected"

  local _DUR_DAPR_RT
  _DUR_DAPR_RT=$(($(date +%s) - _T0_DAPR_RT))
  log_summary "Cloud Tool" "Dapr" "$_STAT_DAPR_RT" "-" "$_DUR_DAPR_RT"
}

# Purpose: Checks if Dapr is relevant.
check_runtime_dapr() {
  local _TOOL_DESC_DAPR="${1:-Dapr}"
  if [ -d "dapr" ] || grep -rq "dapr.io" . --include="*.yaml" --include="*.yml" 2>/dev/null; then
    return 0
  fi
  return 1
}
