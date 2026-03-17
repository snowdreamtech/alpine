#!/usr/bin/env sh
# VHDL Logic Module

# Purpose: Sets up VHDL environment for project.
setup_vhdl() {
  local _T0_VHDL_RT
  _T0_VHDL_RT=$(date +%s)
  _log_setup "VHDL" "vhdl"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Hardware Tool" "VHDL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect VHDL files
  if ! has_lang_files "*.vhd *.vhdl"; then
    log_summary "Hardware Tool" "VHDL" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # VHDL is typically run by simulators like GHDL.
  # We focus on detection and availability of common tools if needed.
  local _STAT_VHDL_RT="✅ Detected"

  local _DUR_VHDL_RT
  _DUR_VHDL_RT=$(($(date +%s) - _T0_VHDL_RT))
  log_summary "Hardware Tool" "VHDL" "$_STAT_VHDL_RT" "-" "$_DUR_VHDL_RT"
}

# Purpose: Checks if VHDL files are present.
check_runtime_vhdl() {
  local _TOOL_DESC_VHDL="${1:-VHDL}"
  if ! has_lang_files "*.vhd *.vhdl"; then
    return 1
  fi
  return 0
}
