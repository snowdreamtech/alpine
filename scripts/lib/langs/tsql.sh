#!/usr/bin/env sh
# T-SQL Logic Module

# Purpose: Sets up T-SQL environment for project.
setup_tsql() {
  local _T0_TSQL_RT
  _T0_TSQL_RT=$(date +%s)
  _log_setup "T-SQL" "tsql"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Database Tool" "T-SQL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect T-SQL: check for *.tsql or *.sql with T-SQL markers
  if ! has_lang_files "*.tsql"; then
    log_summary "Database Tool" "T-SQL" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TSQL_RT="✅ Detected"

  local _DUR_TSQL_RT
  _DUR_TSQL_RT=$(($(date +%s) - _T0_TSQL_RT))
  log_summary "Database Tool" "T-SQL" "$_STAT_TSQL_RT" "-" "$_DUR_TSQL_RT"
}

# Purpose: Checks if T-SQL is relevant.
check_runtime_tsql() {
  local _TOOL_DESC_TSQL="${1:-T-SQL}"
  if has_lang_files "*.tsql"; then
    return 0
  fi
  return 1
}
