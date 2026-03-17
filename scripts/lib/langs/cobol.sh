#!/usr/bin/env sh
# COBOL Logic Module

# Purpose: Sets up COBOL environment for project.
setup_cobol() {
  local _T0_COBOL_RT
  _T0_COBOL_RT=$(date +%s)
  _log_setup "COBOL" "cobol"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Enterprise Tool" "COBOL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect COBOL: check for *.cob, *.cbl, or *.cpy
  if ! has_lang_files "*.cob *.cbl *.cpy"; then
    log_summary "Enterprise Tool" "COBOL" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_COBOL_RT="✅ Detected"

  local _DUR_COBOL_RT
  _DUR_COBOL_RT=$(($(date +%s) - _T0_COBOL_RT))
  log_summary "Enterprise Tool" "COBOL" "$_STAT_COBOL_RT" "-" "$_DUR_COBOL_RT"
}

# Purpose: Checks if COBOL is relevant.
check_runtime_cobol() {
  local _TOOL_DESC_COBOL="${1:-COBOL}"
  if has_lang_files "*.cob *.cbl *.cpy"; then
    return 0
  fi
  return 1
}
