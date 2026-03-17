#!/usr/bin/env sh
# SystemVerilog Logic Module

# Purpose: Sets up SystemVerilog environment for project.
setup_systemverilog() {
  local _T0_SV_RT
  _T0_SV_RT=$(date +%s)
  _log_setup "SystemVerilog" "systemverilog"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Hardware Tool" "SystemVerilog" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect SystemVerilog: check for *.sv or *.svh
  if ! has_lang_files "*.sv *.svh"; then
    log_summary "Hardware Tool" "SystemVerilog" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SV_RT="✅ Detected"

  local _DUR_SV_RT
  _DUR_SV_RT=$(($(date +%s) - _T0_SV_RT))
  log_summary "Hardware Tool" "SystemVerilog" "$_STAT_SV_RT" "-" "$_DUR_SV_RT"
}

# Purpose: Checks if SystemVerilog is relevant.
check_runtime_systemverilog() {
  local _TOOL_DESC_SV="${1:-SystemVerilog}"
  if has_lang_files "*.sv *.svh"; then
    return 0
  fi
  return 1
}
