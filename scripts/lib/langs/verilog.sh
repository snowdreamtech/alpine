#!/usr/bin/env sh
# Verilog Logic Module

# Purpose: Sets up Verilog environment for project.
setup_verilog() {
  local _T0_VLOG_RT
  _T0_VLOG_RT=$(date +%s)
  _log_setup "Verilog" "verilog"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Hardware Tool" "Verilog" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Verilog files
  if ! has_lang_files "*.v *.sv"; then
    log_summary "Hardware Tool" "Verilog" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Verilog is typically run by simulators like Icarus Verilog or Verilator.
  # We focus on detection and availability of common tools if needed.
  local _STAT_VLOG_RT="✅ Detected"

  local _DUR_VLOG_RT
  _DUR_VLOG_RT=$(($(date +%s) - _T0_VLOG_RT))
  log_summary "Hardware Tool" "Verilog" "$_STAT_VLOG_RT" "-" "$_DUR_VLOG_RT"
}

# Purpose: Checks if Verilog files are present.
check_runtime_verilog() {
  local _TOOL_DESC_VLOG="${1:-Verilog}"
  if ! has_lang_files "*.v *.sv"; then
    return 1
  fi
  return 0
}
