#!/usr/bin/env sh
# Astro Logic Module

# Purpose: Sets up Astro environment for project.
setup_astro() {
  local _T0_ASTRO_RT
  _T0_ASTRO_RT=$(date +%s)
  _log_setup "Astro" "astro"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Astro" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Astro files
  if ! has_lang_files "*.astro"; then
    log_summary "Frontend Tool" "Astro" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Astro is typically managed via npm/vite.
  # We focus on detection and availability.
  local _STAT_ASTRO_RT="✅ Detected"

  local _DUR_ASTRO_RT
  _DUR_ASTRO_RT=$(($(date +%s) - _T0_ASTRO_RT))
  log_summary "Frontend Tool" "Astro" "$_STAT_ASTRO_RT" "-" "$_DUR_ASTRO_RT"
}

# Purpose: Checks if Astro files are present.
check_runtime_astro() {
  local _TOOL_DESC_ASTRO="${1:-Astro}"
  if ! has_lang_files "*.astro"; then
    return 1
  fi
  return 0
}
