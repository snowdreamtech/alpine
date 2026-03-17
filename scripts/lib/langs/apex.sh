#!/usr/bin/env sh
# Apex Logic Module

# Purpose: Sets up Apex environment for project.
setup_apex() {
  local _T0_APEX_RT
  _T0_APEX_RT=$(date +%s)
  _log_setup "Apex" "apex"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Enterprise Tool" "Apex" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Apex files
  if ! has_lang_files "*.cls *.trigger"; then
    log_summary "Enterprise Tool" "Apex" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Apex is typically run via Salesforce CLI (sf).
  # We focus on detection and availability.
  local _STAT_APEX_RT="✅ Detected"

  local _DUR_APEX_RT
  _DUR_APEX_RT=$(($(date +%s) - _T0_APEX_RT))
  log_summary "Enterprise Tool" "Apex" "$_STAT_APEX_RT" "-" "$_DUR_APEX_RT"
}

# Purpose: Checks if Apex files are present.
check_runtime_apex() {
  local _TOOL_DESC_APEX="${1:-Apex}"
  if ! has_lang_files "*.cls *.trigger"; then
    return 1
  fi
  return 0
}
