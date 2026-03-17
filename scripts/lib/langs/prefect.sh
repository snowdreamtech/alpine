#!/usr/bin/env sh
# Prefect Logic Module

# Purpose: Sets up Prefect environment for project.
setup_prefect() {
  local _T0_PREFECT_RT
  _T0_PREFECT_RT=$(date +%s)
  _log_setup "Prefect" "prefect"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "Prefect" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Prefect: check for 'import prefect' or '@flow' in *.py
  if grep -rq "@flow" . --include="*.py" 2>/dev/null || grep -rq "import prefect" . --include="*.py" 2>/dev/null; then
    :
  else
    log_summary "Data Tool" "Prefect" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PREFECT_RT="✅ Detected"

  local _DUR_PREFECT_RT
  _DUR_PREFECT_RT=$(($(date +%s) - _T0_PREFECT_RT))
  log_summary "Data Tool" "Prefect" "$_STAT_PREFECT_RT" "-" "$_DUR_PREFECT_RT"
}

# Purpose: Checks if Prefect is relevant.
check_runtime_prefect() {
  local _TOOL_DESC_PREFECT="${1:-Prefect}"
  if grep -rq "@flow" . --include="*.py" 2>/dev/null || grep -rq "import prefect" . --include="*.py" 2>/dev/null; then
    return 0
  fi
  return 1
}
