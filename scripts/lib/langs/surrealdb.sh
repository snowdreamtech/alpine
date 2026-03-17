#!/usr/bin/env sh
# SurrealDB Logic Module

# Purpose: Sets up SurrealDB environment for project.
setup_surrealdb() {
  local _T0_SURREAL_RT
  _T0_SURREAL_RT=$(date +%s)
  _log_setup "SurrealDB" "surrealdb"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "SurrealDB" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect SurrealDB: check for *.surql or SurrealDB in .sql
  if ! has_lang_files "*.surql"; then
    log_summary "Data Tool" "SurrealDB" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SURREAL_RT="✅ Detected"

  local _DUR_SURREAL_RT
  _DUR_SURREAL_RT=$(($(date +%s) - _T0_SURREAL_RT))
  log_summary "Data Tool" "SurrealDB" "$_STAT_SURREAL_RT" "-" "$_DUR_SURREAL_RT"
}

# Purpose: Checks if SurrealDB is relevant.
check_runtime_surrealdb() {
  local _TOOL_DESC_SURREAL="${1:-SurrealDB}"
  if has_lang_files "*.surql"; then
    return 0
  fi
  return 1
}
