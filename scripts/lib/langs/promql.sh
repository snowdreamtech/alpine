#!/usr/bin/env sh
# PromQL Logic Module

# Purpose: Sets up PromQL environment for project.
setup_promql() {
  local _T0_PROM_RT
  _T0_PROM_RT=$(date +%s)
  _log_setup "PromQL" "promql"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Observability Tool" "PromQL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect PromQL files
  if ! has_lang_files "*.promql"; then
    log_summary "Observability Tool" "PromQL" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # PromQL is typically audited by promtool.
  # We focus on detection and availability.
  local _STAT_PROM_RT="✅ Detected"

  local _DUR_PROM_RT
  _DUR_PROM_RT=$(($(date +%s) - _T0_PROM_RT))
  log_summary "Observability Tool" "PromQL" "$_STAT_PROM_RT" "-" "$_DUR_PROM_RT"
}

# Purpose: Checks if PromQL files are present.
check_runtime_promql() {
  local _TOOL_DESC_PROM="${1:-PromQL}"
  if ! has_lang_files "*.promql"; then
    return 1
  fi
  return 0
}
