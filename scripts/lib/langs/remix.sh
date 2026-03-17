#!/usr/bin/env sh
# Remix Logic Module

# Purpose: Sets up Remix environment for project.
setup_remix() {
  local _T0_REMIX_RT
  _T0_REMIX_RT=$(date +%s)
  _log_setup "Remix" "remix"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Web Framework" "Remix" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Remix: check for remix.config.js or remix.config.ts
  if [ -f "remix.config.js" ] || [ -f "remix.config.ts" ]; then
    :
  elif [ -f "package.json" ] && grep -q "@remix-run/" "package.json"; then
    :
  else
    log_summary "Web Framework" "Remix" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_REMIX_RT="✅ Detected"

  local _DUR_REMIX_RT
  _DUR_REMIX_RT=$(($(date +%s) - _T0_REMIX_RT))
  log_summary "Web Framework" "Remix" "$_STAT_REMIX_RT" "-" "$_DUR_REMIX_RT"
}

# Purpose: Checks if Remix is relevant.
check_runtime_remix() {
  local _TOOL_DESC_REMIX="${1:-Remix}"
  if [ -f "remix.config.js" ] || [ -f "remix.config.ts" ]; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q "@remix-run/" "package.json"; then
    return 0
  fi
  return 1
}
