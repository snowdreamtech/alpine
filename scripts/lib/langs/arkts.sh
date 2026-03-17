#!/usr/bin/env sh
# ArkTS Logic Module

# Purpose: Sets up ArkTS environment for project.
setup_arkts() {
  local _T0_ARK_RT
  _T0_ARK_RT=$(date +%s)
  _log_setup "ArkTS" "arkts"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Mobile Tool" "ArkTS" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect ArkTS files
  if ! has_lang_files "*.ets"; then
    log_summary "Mobile Tool" "ArkTS" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # ArkTS is typically handled by DevEco Studio or ohpm.
  # We focus on detection and availability.
  local _STAT_ARK_RT="✅ Detected"

  local _DUR_ARK_RT
  _DUR_ARK_RT=$(($(date +%s) - _T0_ARK_RT))
  log_summary "Mobile Tool" "ArkTS" "$_STAT_ARK_RT" "-" "$_DUR_ARK_RT"
}

# Purpose: Checks if ArkTS files are present.
check_runtime_arkts() {
  local _TOOL_DESC_ARK="${1:-ArkTS}"
  if ! has_lang_files "*.ets"; then
    return 1
  fi
  return 0
}
