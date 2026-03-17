#!/usr/bin/env sh
# Nuxt Logic Module

# Purpose: Sets up Nuxt environment for project.
setup_nuxt() {
  local _T0_NUXT_RT
  _T0_NUXT_RT=$(date +%s)
  _log_setup "Nuxt" "nuxt"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Web Framework" "Nuxt" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Nuxt: check for nuxt.config.js, nuxt.config.ts, or nuxt.config.mjs
  if [ -f "nuxt.config.js" ] || [ -f "nuxt.config.ts" ] || [ -f "nuxt.config.mjs" ]; then
    :
  else
    log_summary "Web Framework" "Nuxt" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_NUXT_RT="✅ Detected"

  local _DUR_NUXT_RT
  _DUR_NUXT_RT=$(($(date +%s) - _T0_NUXT_RT))
  log_summary "Web Framework" "Nuxt" "$_STAT_NUXT_RT" "-" "$_DUR_NUXT_RT"
}

# Purpose: Checks if Nuxt is relevant.
check_runtime_nuxt() {
  local _TOOL_DESC_NUXT="${1:-Nuxt}"
  if [ -f "nuxt.config.js" ] || [ -f "nuxt.config.ts" ] || [ -f "nuxt.config.mjs" ]; then
    return 0
  fi
  return 1
}
