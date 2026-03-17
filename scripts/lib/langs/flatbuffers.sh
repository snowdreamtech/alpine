#!/usr/bin/env sh
# FlatBuffers Logic Module

# Purpose: Sets up FlatBuffers environment for project.
setup_flatbuffers() {
  local _T0_FBS_RT
  _T0_FBS_RT=$(date +%s)
  _log_setup "FlatBuffers" "flatbuffers"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "FlatBuffers" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect FlatBuffers: check for *.fbs
  if ! has_lang_files "*.fbs"; then
    log_summary "Data Tool" "FlatBuffers" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_FBS_RT="✅ Detected"

  local _DUR_FBS_RT
  _DUR_FBS_RT=$(($(date +%s) - _T0_FBS_RT))
  log_summary "Data Tool" "FlatBuffers" "$_STAT_FBS_RT" "-" "$_DUR_FBS_RT"
}

# Purpose: Checks if FlatBuffers is relevant.
check_runtime_flatbuffers() {
  local _TOOL_DESC_FBS="${1:-FlatBuffers}"
  if has_lang_files "*.fbs"; then
    return 0
  fi
  return 1
}
