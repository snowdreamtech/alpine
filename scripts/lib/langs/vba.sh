#!/usr/bin/env sh
# VBA Logic Module

# Purpose: Sets up VBA environment for project.
setup_vba() {
  local _T0_VBA_RT
  _T0_VBA_RT=$(date +%s)
  _log_setup "VBA" "vba"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Enterprise Tool" "VBA" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect VBA files
  if ! has_lang_files "*.vba *.bas *.cls"; then
    log_summary "Enterprise Tool" "VBA" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # VBA is embedded in Office documents. Standalone .bas/.cls files are common in repos.
  # We focus on detection.
  local _STAT_VBA_RT="✅ Detected"

  local _DUR_VBA_RT
  _DUR_VBA_RT=$(($(date +%s) - _T0_VBA_RT))
  log_summary "Enterprise Tool" "VBA" "$_STAT_VBA_RT" "-" "$_DUR_VBA_RT"
}

# Purpose: Checks if VBA files are present.
check_runtime_vba() {
  local _TOOL_DESC_VBA="${1:-VBA}"
  if ! has_lang_files "*.vba *.bas *.cls"; then
    return 1
  fi
  return 0
}
