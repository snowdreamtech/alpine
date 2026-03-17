#!/usr/bin/env sh
# Handlebars Logic Module

# Purpose: Sets up Handlebars environment for project.
setup_handlebars() {
  local _T0_HANDLEBARS_RT
  _T0_HANDLEBARS_RT=$(date +%s)
  _log_setup "Handlebars" "handlebars"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Handlebars" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Handlebars: check for *.hbs or *.handlebars
  if ! has_lang_files "*.hbs *.handlebars"; then
    log_summary "Frontend Tool" "Handlebars" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_HANDLEBARS_RT="✅ Detected"

  local _DUR_HANDLEBARS_RT
  _DUR_HANDLEBARS_RT=$(($(date +%s) - _T0_HANDLEBARS_RT))
  log_summary "Frontend Tool" "Handlebars" "$_STAT_HANDLEBARS_RT" "-" "$_DUR_HANDLEBARS_RT"
}

# Purpose: Checks if Handlebars is relevant.
check_runtime_handlebars() {
  local _TOOL_DESC_HANDLEBARS="${1:-Handlebars}"
  if has_lang_files "*.hbs *.handlebars"; then
    return 0
  fi
  return 1
}
