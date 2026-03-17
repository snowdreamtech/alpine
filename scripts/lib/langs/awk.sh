#!/usr/bin/env sh
# AWK Logic Module

# Purpose: Sets up AWK environment for project.
setup_awk() {
  local _T0_AWK_RT
  _T0_AWK_RT=$(date +%s)
  _log_setup "AWK" "awk"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Unix Tool" "AWK" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect AWK: check for *.awk files
  if ! has_lang_files "*.awk"; then
    log_summary "Unix Tool" "AWK" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_AWK_RT="✅ Detected"

  local _DUR_AWK_RT
  _DUR_AWK_RT=$(($(date +%s) - _T0_AWK_RT))
  log_summary "Unix Tool" "AWK" "$_STAT_AWK_RT" "-" "$_DUR_AWK_RT"
}

# Purpose: Checks if AWK is relevant.
check_runtime_awk() {
  local _TOOL_DESC_AWK="${1:-AWK}"
  if has_lang_files "*.awk"; then
    return 0
  fi
  return 1
}
