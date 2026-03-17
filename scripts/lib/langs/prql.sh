#!/usr/bin/env sh
# PRQL Logic Module

# Purpose: Sets up PRQL environment for project.
setup_prql() {
  local _T0_PRQL_RT
  _T0_PRQL_RT=$(date +%s)
  _log_setup "PRQL" "prql"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "PRQL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect PRQL: check for *.prql files
  if ! has_lang_files "*.prql"; then
    log_summary "Data Tool" "PRQL" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PRQL_RT="✅ Detected"

  local _DUR_PRQL_RT
  _DUR_PRQL_RT=$(($(date +%s) - _T0_PRQL_RT))
  log_summary "Data Tool" "PRQL" "$_STAT_PRQL_RT" "-" "$_DUR_PRQL_RT"
}

# Purpose: Checks if PRQL is relevant.
check_runtime_prql() {
  local _TOOL_DESC_PRQL="${1:-PRQL}"
  if has_lang_files "*.prql"; then
    return 0
  fi
  return 1
}
