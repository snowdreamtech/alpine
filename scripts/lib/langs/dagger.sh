#!/usr/bin/env sh
# Dagger Logic Module

# Purpose: Sets up Dagger environment for project.
setup_dagger() {
  local _T0_DAGGER_RT
  _T0_DAGGER_RT=$(date +%s)
  _log_setup "Dagger" "dagger"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "CI Tool" "Dagger" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Dagger: check for dagger.json or .dagger/ directory
  if [ -f "dagger.json" ] || [ -d ".dagger" ]; then
    :
  else
    log_summary "CI Tool" "Dagger" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_DAGGER_RT="✅ Detected"

  local _DUR_DAGGER_RT
  _DUR_DAGGER_RT=$(($(date +%s) - _T0_DAGGER_RT))
  log_summary "CI Tool" "Dagger" "$_STAT_DAGGER_RT" "-" "$_DUR_DAGGER_RT"
}

# Purpose: Checks if Dagger is relevant.
check_runtime_dagger() {
  local _TOOL_DESC_DAGGER="${1:-Dagger}"
  if [ -f "dagger.json" ] || [ -d ".dagger" ]; then
    return 0
  fi
  return 1
}
