#!/usr/bin/env sh
# Temporal Logic Module

# Purpose: Sets up Temporal environment for project.
setup_temporal() {
  local _T0_TEMPORAL_RT
  _T0_TEMPORAL_RT=$(date +%s)
  _log_setup "Temporal" "temporal"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Workflow Tool" "Temporal" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Temporal: check for temporal.yaml, temporal.json, or workflow code patterns
  if [ -f "temporal.yaml" ] || [ -f "temporal.json" ] || grep -q "Temporal" ./* 2>/dev/null; then
    :
  else
    log_summary "Workflow Tool" "Temporal" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TEMPORAL_RT="✅ Detected"

  local _DUR_TEMPORAL_RT
  _DUR_TEMPORAL_RT=$(($(date +%s) - _T0_TEMPORAL_RT))
  log_summary "Workflow Tool" "Temporal" "$_STAT_TEMPORAL_RT" "-" "$_DUR_TEMPORAL_RT"
}

# Purpose: Checks if Temporal is relevant.
check_runtime_temporal() {
  local _TOOL_DESC_TEMPORAL="${1:-Temporal}"
  if [ -f "temporal.yaml" ] || [ -f "temporal.json" ]; then
    return 0
  fi
  return 1
}
