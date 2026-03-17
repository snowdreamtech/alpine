#!/usr/bin/env sh
# ABAP Logic Module

# Purpose: Sets up ABAP environment for project.
setup_abap() {
  local _T0_ABAP_RT
  _T0_ABAP_RT=$(date +%s)
  _log_setup "ABAP" "abap"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Enterprise Tool" "ABAP" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect ABAP: check for *.abap files
  if ! has_lang_files "*.abap"; then
    log_summary "Enterprise Tool" "ABAP" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_ABAP_RT="✅ Detected"

  local _DUR_ABAP_RT
  _DUR_ABAP_RT=$(($(date +%s) - _T0_ABAP_RT))
  log_summary "Enterprise Tool" "ABAP" "$_STAT_ABAP_RT" "-" "$_DUR_ABAP_RT"
}

# Purpose: Checks if ABAP is relevant.
check_runtime_abap() {
  local _TOOL_DESC_ABAP="${1:-ABAP}"
  if has_lang_files "*.abap"; then
    return 0
  fi
  return 1
}
