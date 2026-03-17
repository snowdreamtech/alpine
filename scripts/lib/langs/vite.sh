#!/usr/bin/env sh
# Vite Logic Module

# Purpose: Sets up Vite environment for project.
setup_vite() {
  local _T0_VITE_RT
  _T0_VITE_RT=$(date +%s)
  _log_setup "Vite" "vite"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Build Tool" "Vite" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Vite: check for vite.config.js, vite.config.ts, or vite.config.mjs
  if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ] || [ -f "vite.config.mjs" ]; then
    :
  elif [ -f "package.json" ] && grep -q "vite" "package.json"; then
    :
  else
    log_summary "Build Tool" "Vite" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_VITE_RT="✅ Detected"

  # Heuristic version detection: check vite version via npx
  local _VER_VITE="-"
  if command -v npx >/dev/null 2>&1; then
    _VER_VITE=$(npx vite --version 2>/dev/null | awk '{print $NF}' || echo "-")
  fi

  local _DUR_VITE_RT
  _DUR_VITE_RT=$(($(date +%s) - _T0_VITE_RT))
  log_summary "Build Tool" "Vite" "$_STAT_VITE_RT" "$_VER_VITE" "$_DUR_VITE_RT"
}

# Purpose: Checks if Vite is relevant.
check_runtime_vite() {
  local _TOOL_DESC_VITE="${1:-Vite}"
  if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ] || [ -f "vite.config.mjs" ]; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q "vite" "package.json"; then
    return 0
  fi
  return 1
}
