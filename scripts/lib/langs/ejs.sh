#!/usr/bin/env sh
# EJS Logic Module

# Purpose: Sets up EJS environment for project.
setup_ejs() {
  local _T0_EJS_RT
  _T0_EJS_RT=$(date +%s)
  _log_setup "EJS" "ejs"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "EJS" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect EJS: check for *.ejs
  if ! has_lang_files "*.ejs"; then
    log_summary "Frontend Tool" "EJS" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_EJS_RT="✅ Detected"

  local _DUR_EJS_RT
  _DUR_EJS_RT=$(($(date +%s) - _T0_EJS_RT))
  log_summary "Frontend Tool" "EJS" "$_STAT_EJS_RT" "-" "$_DUR_EJS_RT"
}

# Purpose: Checks if EJS is relevant.
check_runtime_ejs() {
  local _TOOL_DESC_EJS="${1:-EJS}"
  if has_lang_files "*.ejs"; then
    return 0
  fi
  return 1
}
