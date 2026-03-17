#!/usr/bin/env sh
# ClickHouse Logic Module

# Purpose: Sets up ClickHouse environment for project.
setup_clickhouse() {
  local _T0_CH_RT
  _T0_CH_RT=$(date +%s)
  _log_setup "ClickHouse" "clickhouse"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Database" "ClickHouse" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect ClickHouse: check for .clickhouse directory or config files
  if [ -d ".clickhouse" ] || [ -f "clickhouse-config.xml" ] || [ -f "clickhouse-user-config.xml" ]; then
    :
  else
    log_summary "Database" "ClickHouse" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_CH_RT="✅ Detected"

  local _DUR_CH_RT
  _DUR_CH_RT=$(($(date +%s) - _T0_CH_RT))
  log_summary "Database" "ClickHouse" "$_STAT_CH_RT" "-" "$_DUR_CH_RT"
}

# Purpose: Checks if ClickHouse is relevant.
check_runtime_clickhouse() {
  local _TOOL_DESC_CH="${1:-ClickHouse}"
  if [ -d ".clickhouse" ] || [ -f "clickhouse-config.xml" ] || [ -f "clickhouse-user-config.xml" ]; then
    return 0
  fi
  return 1
}
