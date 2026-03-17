#!/usr/bin/env sh
# PostCSS Logic Module

# Purpose: Sets up PostCSS environment for project.
setup_postcss() {
  local _T0_POSTCSS_RT
  _T0_POSTCSS_RT=$(date +%s)
  _log_setup "PostCSS" "postcss"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "PostCSS" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect PostCSS: check for postcss.config.js, postcss.config.cjs, or postcss in package.json
  if ! has_lang_files "postcss.config.js postcss.config.cjs postcss.config.mjs postcss.config.ts"; then
    if [ -f "package.json" ] && grep -q '"postcss"' package.json; then
      :
    else
      log_summary "Frontend Tool" "PostCSS" "⏭️ Skipped" "-" "0"
      return 0
    fi
  fi

  local _STAT_POSTCSS_RT="✅ Detected"

  local _DUR_POSTCSS_RT
  _DUR_POSTCSS_RT=$(($(date +%s) - _T0_POSTCSS_RT))
  log_summary "Frontend Tool" "PostCSS" "$_STAT_POSTCSS_RT" "-" "$_DUR_POSTCSS_RT"
}

# Purpose: Checks if PostCSS is relevant.
check_runtime_postcss() {
  local _TOOL_DESC_POSTCSS="${1:-PostCSS}"
  if has_lang_files "postcss.config.js postcss.config.cjs postcss.config.mjs postcss.config.ts"; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q '"postcss"' package.json; then
    return 0
  fi
  return 1
}
