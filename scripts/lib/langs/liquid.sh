#!/usr/bin/env sh
# Liquid Logic Module

# Purpose: Sets up Liquid environment for project.
setup_liquid() {
  local _T0_LIQUID_RT
  _T0_LIQUID_RT=$(date +%s)
  _log_setup "Liquid" "liquid"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Liquid" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Liquid files
  if ! has_lang_files "*.liquid"; then
    log_summary "Frontend Tool" "Liquid" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Liquid is a template language. We focus on detection.
  local _STAT_LIQUID_RT="✅ Detected"

  local _DUR_LIQUID_RT
  _DUR_LIQUID_RT=$(($(date +%s) - _T0_LIQUID_RT))
  log_summary "Frontend Tool" "Liquid" "$_STAT_LIQUID_RT" "-" "$_DUR_LIQUID_RT"
}

# Purpose: Checks if Liquid files are present.
check_runtime_liquid() {
  local _TOOL_DESC_LIQUID="${1:-Liquid}"
  if ! has_lang_files "*.liquid"; then
    return 1
  fi
  return 0
}
