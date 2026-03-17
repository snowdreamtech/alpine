#!/usr/bin/env sh
# Bicep Logic Module

# Purpose: Sets up Bicep environment for project.
setup_bicep() {
  local _T0_BICEP_RT
  _T0_BICEP_RT=$(date +%s)
  _log_setup "Bicep" "bicep"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "IaC Tool" "Bicep" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Bicep files
  if ! has_lang_files "*.bicep"; then
    log_summary "IaC Tool" "Bicep" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Bicep is typically handled by 'az bicep' or the standalone 'bicep' CLI.
  # We focus on detection and availability.
  local _STAT_BICEP_RT="✅ Detected"

  local _DUR_BICEP_RT
  _DUR_BICEP_RT=$(($(date +%s) - _T0_BICEP_RT))
  log_summary "IaC Tool" "Bicep" "$_STAT_BICEP_RT" "-" "$_DUR_BICEP_RT"
}

# Purpose: Checks if Bicep files are present.
check_runtime_bicep() {
  local _TOOL_DESC_BICEP="${1:-Bicep}"
  if ! has_lang_files "*.bicep"; then
    return 1
  fi
  return 0
}
