#!/usr/bin/env sh
# dbt Logic Module

# Purpose: Sets up dbt environment for project.
setup_dbt() {
  local _T0_DBT_RT
  _T0_DBT_RT=$(date +%s)
  _log_setup "dbt" "dbt"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "dbt" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect dbt: check for dbt_project.yml
  if [ -f "dbt_project.yml" ]; then
    :
  else
    log_summary "Data Tool" "dbt" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_DBT_RT="✅ Detected"

  local _DUR_DBT_RT
  _DUR_DBT_RT=$(($(date +%s) - _T0_DBT_RT))
  log_summary "Data Tool" "dbt" "$_STAT_DBT_RT" "-" "$_DUR_DBT_RT"
}

# Purpose: Checks if dbt is relevant.
check_runtime_dbt() {
  local _TOOL_DESC_DBT="${1:-dbt}"
  if [ -f "dbt_project.yml" ]; then
    return 0
  fi
  return 1
}
