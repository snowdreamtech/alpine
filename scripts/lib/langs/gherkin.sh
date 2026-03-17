#!/usr/bin/env sh
# Gherkin Logic Module

# Purpose: Sets up Gherkin environment for project.
setup_gherkin() {
  local _T0_GHERKIN_RT
  _T0_GHERKIN_RT=$(date +%s)
  _log_setup "Gherkin" "gherkin"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Gherkin" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Gherkin (BDD) files
  if ! has_lang_files "*.feature"; then
    log_summary "Runtime" "Gherkin" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Gherkin is a specification language, typically run by library-specific runners.
  # We focus on detection and availability of common BDD tools if needed.
  local _STAT_GHERKIN_RT="✅ Detected"

  local _DUR_GHERKIN_RT
  _DUR_GHERKIN_RT=$(($(date +%s) - _T0_GHERKIN_RT))
  log_summary "Runtime" "Gherkin" "$_STAT_GHERKIN_RT" "-" "$_DUR_GHERKIN_RT"
}

# Purpose: Checks if Gherkin files are healthy (place holder for generic check).
check_runtime_gherkin() {
  local _TOOL_DESC_GHERKIN="${1:-Gherkin}"
  if ! has_lang_files "*.feature"; then
    return 1
  fi
  return 0
}
