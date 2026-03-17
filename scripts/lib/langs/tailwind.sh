#!/usr/bin/env sh
# Tailwind CSS Logic Module

# Purpose: Sets up Tailwind CSS environment for project.
setup_tailwind() {
  local _T0_TAILWIND_RT
  _T0_TAILWIND_RT=$(date +%s)
  _log_setup "Tailwind CSS" "tailwind"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "UI Framework" "Tailwind CSS" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Tailwind CSS: check for tailwind.config.js, tailwind.config.ts, or tailwind.config.mjs
  if [ -f "tailwind.config.js" ] || [ -f "tailwind.config.ts" ] || [ -f "tailwind.config.mjs" ]; then
    :
  elif [ -f "package.json" ] && grep -q "tailwindcss" "package.json"; then
    :
  else
    log_summary "UI Framework" "Tailwind CSS" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TAILWIND_RT="✅ Detected"

  # Heuristic version detection: check tailwind version via npx
  local _VER_TAILWIND="-"
  if command -v npx >/dev/null 2>&1; then
    _VER_TAILWIND=$(npx tailwindcss --version 2>/dev/null | awk '{print $NF}' || echo "-")
  fi

  local _DUR_TAILWIND_RT
  _DUR_TAILWIND_RT=$(($(date +%s) - _T0_TAILWIND_RT))
  log_summary "UI Framework" "Tailwind CSS" "$_STAT_TAILWIND_RT" "$_VER_TAILWIND" "$_DUR_TAILWIND_RT"
}

# Purpose: Checks if Tailwind CSS is relevant.
check_runtime_tailwind() {
  local _TOOL_DESC_TAILWIND="${1:-Tailwind CSS}"
  if [ -f "tailwind.config.js" ] || [ -f "tailwind.config.ts" ] || [ -f "tailwind.config.mjs" ]; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q "tailwindcss" "package.json"; then
    return 0
  fi
  return 1
}
