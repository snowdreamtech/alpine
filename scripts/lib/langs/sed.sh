#!/usr/bin/env sh
# Sed Logic Module

# Purpose: Sets up Sed environment for project.
setup_sed() {
  local _T0_SED_RT
  _T0_SED_RT=$(date +%s)
  _log_setup "Sed" "sed"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Unix Tool" "Sed" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Sed: check for *.sed files
  if ! has_lang_files "*.sed"; then
    log_summary "Unix Tool" "Sed" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SED_RT="✅ Detected"

  local _DUR_SED_RT
  _DUR_SED_RT=$(($(date +%s) - _T0_SED_RT))
  log_summary "Unix Tool" "Sed" "$_STAT_SED_RT" "-" "$_DUR_SED_RT"
}

# Purpose: Checks if Sed is relevant.
check_runtime_sed() {
  local _TOOL_DESC_SED="${1:-Sed}"
  if has_lang_files "*.sed"; then
    return 0
  fi
  return 1
}
