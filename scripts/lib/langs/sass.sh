#!/usr/bin/env sh
# Sass Logic Module

# Purpose: Sets up Sass environment for project.
setup_sass() {
  local _T0_SASS_RT
  _T0_SASS_RT=$(date +%s)
  _log_setup "Sass" "sass"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Sass" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Sass: check for *.sass or *.scss
  if ! has_lang_files "*.sass *.scss"; then
    log_summary "Frontend Tool" "Sass" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SASS_RT="✅ Detected"

  local _DUR_SASS_RT
  _DUR_SASS_RT=$(($(date +%s) - _T0_SASS_RT))
  log_summary "Frontend Tool" "Sass" "$_STAT_SASS_RT" "-" "$_DUR_SASS_RT"
}

# Purpose: Checks if Sass is relevant.
check_runtime_sass() {
  local _TOOL_DESC_SASS="${1:-Sass}"
  if has_lang_files "*.sass *.scss"; then
    return 0
  fi
  return 1
}
