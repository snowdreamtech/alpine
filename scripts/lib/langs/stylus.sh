#!/usr/bin/env sh
# Stylus Logic Module

# Purpose: Sets up Stylus environment for project.
setup_stylus() {
  local _T0_STYLUS_RT
  _T0_STYLUS_RT=$(date +%s)
  _log_setup "Stylus" "stylus"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Stylus" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Stylus: check for *.styl
  if ! has_lang_files "*.styl"; then
    log_summary "Frontend Tool" "Stylus" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_STYLUS_RT="✅ Detected"

  local _DUR_STYLUS_RT
  _DUR_STYLUS_RT=$(($(date +%s) - _T0_STYLUS_RT))
  log_summary "Frontend Tool" "Stylus" "$_STAT_STYLUS_RT" "-" "$_DUR_STYLUS_RT"
}

# Purpose: Checks if Stylus is relevant.
check_runtime_stylus() {
  local _TOOL_DESC_STYLUS="${1:-Stylus}"
  if has_lang_files "*.styl"; then
    return 0
  fi
  return 1
}
