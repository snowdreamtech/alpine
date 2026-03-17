#!/usr/bin/env sh
# Less Logic Module

# Purpose: Sets up Less environment for project.
setup_less() {
  local _T0_LESS_RT
  _T0_LESS_RT=$(date +%s)
  _log_setup "Less" "less"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Less" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Less: check for *.less
  if ! has_lang_files "*.less"; then
    log_summary "Frontend Tool" "Less" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_LESS_RT="✅ Detected"

  local _DUR_LESS_RT
  _DUR_LESS_RT=$(($(date +%s) - _T0_LESS_RT))
  log_summary "Frontend Tool" "Less" "$_STAT_LESS_RT" "-" "$_DUR_LESS_RT"
}

# Purpose: Checks if Less is relevant.
check_runtime_less() {
  local _TOOL_DESC_LESS="${1:-Less}"
  if has_lang_files "*.less"; then
    return 0
  fi
  return 1
}
