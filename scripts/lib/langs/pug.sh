#!/usr/bin/env sh
# Pug Logic Module

# Purpose: Sets up Pug environment for project.
setup_pug() {
  local _T0_PUG_RT
  _T0_PUG_RT=$(date +%s)
  _log_setup "Pug" "pug"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Pug" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Pug: check for *.pug or *.jade
  if ! has_lang_files "*.pug *.jade"; then
    log_summary "Frontend Tool" "Pug" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PUG_RT="✅ Detected"

  local _DUR_PUG_RT
  _DUR_PUG_RT=$(($(date +%s) - _T0_PUG_RT))
  log_summary "Frontend Tool" "Pug" "$_STAT_PUG_RT" "-" "$_DUR_PUG_RT"
}

# Purpose: Checks if Pug is relevant.
check_runtime_pug() {
  local _TOOL_DESC_PUG="${1:-Pug}"
  if has_lang_files "*.pug *.jade"; then
    return 0
  fi
  return 1
}
