#!/usr/bin/env sh
# PL/SQL Logic Module

# Purpose: Sets up PL/SQL environment for project.
setup_plsql() {
  local _T0_PLSQL_RT
  _T0_PLSQL_RT=$(date +%s)
  _log_setup "PL/SQL" "plsql"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Database Tool" "PL/SQL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect PL/SQL: check for *.pkb, *.pks, *.plsql, or *.sql with PL/SQL markers
  if ! has_lang_files "*.pkb *.pks *.plsql"; then
    log_summary "Database Tool" "PL/SQL" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PLSQL_RT="✅ Detected"

  local _DUR_PLSQL_RT
  _DUR_PLSQL_RT=$(($(date +%s) - _T0_PLSQL_RT))
  log_summary "Database Tool" "PL/SQL" "$_STAT_PLSQL_RT" "-" "$_DUR_PLSQL_RT"
}

# Purpose: Checks if PL/SQL is relevant.
check_runtime_plsql() {
  local _TOOL_DESC_PLSQL="${1:-PL/SQL}"
  if has_lang_files "*.pkb *.pks *.plsql"; then
    return 0
  fi
  return 1
}
