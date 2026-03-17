#!/usr/bin/env sh
# DuckDB Logic Module

# Purpose: Installs DuckDB via mise.
install_runtime_duckdb() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install DuckDB via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "duckdb@${MISE_TOOL_VERSION_DUCKDB}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up DuckDB environment for project.
setup_duckdb() {
  local _T0_DUCK_RT
  _T0_DUCK_RT=$(date +%s)
  _log_setup "DuckDB" "duckdb"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "DuckDB" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect SQL/DuckDB files
  if ! has_lang_files "*.sql *.duckdb"; then
    log_summary "Runtime" "DuckDB" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_DUCK_RT="✅ Installed"
  install_runtime_duckdb || _STAT_DUCK_RT="❌ Failed"

  local _DUR_DUCK_RT
  _DUR_DUCK_RT=$(($(date +%s) - _T0_DUCK_RT))
  log_summary "Runtime" "DuckDB" "$_STAT_DUCK_RT" "$(get_version duckdb --version | awk '{print $1}')" "$_DUR_DUCK_RT"
}

# Purpose: Checks if DuckDB is available.
check_runtime_duckdb() {
  local _TOOL_DESC_DUCK="${1:-DuckDB}"
  if ! command -v duckdb >/dev/null 2>&1; then
    log_warn "Required runtime 'duckdb' for $_TOOL_DESC_DUCK is missing. Skipping."
    return 1
  fi
  return 0
}
