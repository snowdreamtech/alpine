#!/usr/bin/env sh
# Thrift Logic Module

# Purpose: Sets up Thrift environment for project.
setup_thrift() {
  local _T0_THRIFT_RT
  _T0_THRIFT_RT=$(date +%s)
  _log_setup "Thrift" "thrift"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "Thrift" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Thrift files
  if ! has_lang_files "*.thrift"; then
    log_summary "Data Tool" "Thrift" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Thrift is a serialization framework. We focus on detection.
  local _STAT_THRIFT_RT="✅ Detected"

  local _DUR_THRIFT_RT
  _DUR_THRIFT_RT=$(($(date +%s) - _T0_THRIFT_RT))
  log_summary "Data Tool" "Thrift" "$_STAT_THRIFT_RT" "-" "$_DUR_THRIFT_RT"
}

# Purpose: Checks if Thrift files are present.
check_runtime_thrift() {
  local _TOOL_DESC_THRIFT="${1:-Thrift}"
  if ! has_lang_files "*.thrift"; then
    return 1
  fi
  return 0
}
