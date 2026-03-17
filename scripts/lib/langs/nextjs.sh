#!/usr/bin/env sh
# Next.js Logic Module

# Purpose: Sets up Next.js environment for project.
setup_nextjs() {
  local _T0_NEXTJS_RT
  _T0_NEXTJS_RT=$(date +%s)
  _log_setup "Next.js" "nextjs"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Web Framework" "Next.js" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Next.js: check for next.config.js, next.config.ts, or next.config.mjs
  if [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
    :
  else
    log_summary "Web Framework" "Next.js" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_NEXTJS_RT="✅ Detected"

  local _DUR_NEXTJS_RT
  _DUR_NEXTJS_RT=$(($(date +%s) - _T0_NEXTJS_RT))
  log_summary "Web Framework" "Next.js" "$_STAT_NEXTJS_RT" "-" "$_DUR_NEXTJS_RT"
}

# Purpose: Checks if Next.js is relevant.
check_runtime_nextjs() {
  local _TOOL_DESC_NEXTJS="${1:-Next.js}"
  if [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
    return 0
  fi
  return 1
}
