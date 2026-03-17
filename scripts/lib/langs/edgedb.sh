#!/usr/bin/env sh
# EdgeDB Logic Module

# Purpose: Sets up EdgeDB environment for project.
setup_edgedb() {
  local _T0_EDGEDB_RT
  _T0_EDGEDB_RT=$(date +%s)
  _log_setup "EdgeDB" "edgedb"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "EdgeDB" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect EdgeDB: check for edgedb.toml or *.esdl
  if ! has_lang_files "edgedb.toml" "*.esdl"; then
    log_summary "Data Tool" "EdgeDB" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_EDGEDB_RT="✅ Detected"

  local _DUR_EDGEDB_RT
  _DUR_EDGEDB_RT=$(($(date +%s) - _T0_EDGEDB_RT))
  log_summary "Data Tool" "EdgeDB" "$_STAT_EDGEDB_RT" "-" "$_DUR_EDGEDB_RT"
}

# Purpose: Checks if EdgeDB is relevant.
check_runtime_edgedb() {
  local _TOOL_DESC_EDGEDB="${1:-EdgeDB}"
  if has_lang_files "edgedb.toml" "*.esdl"; then
    return 0
  fi
  return 1
}
