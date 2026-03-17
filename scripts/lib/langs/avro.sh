#!/usr/bin/env sh
# Avro Logic Module

# Purpose: Sets up Avro environment for project.
setup_avro() {
  local _T0_AVRO_RT
  _T0_AVRO_RT=$(date +%s)
  _log_setup "Avro" "avro"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "Avro" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Avro files
  if ! has_lang_files "*.avsc"; then
    log_summary "Data Tool" "Avro" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Avro is a serialization framework. We focus on detection.
  local _STAT_AVRO_RT="✅ Detected"

  local _DUR_AVRO_RT
  _DUR_AVRO_RT=$(($(date +%s) - _T0_AVRO_RT))
  log_summary "Data Tool" "Avro" "$_STAT_AVRO_RT" "-" "$_DUR_AVRO_RT"
}

# Purpose: Checks if Avro files are present.
check_runtime_avro() {
  local _TOOL_DESC_AVRO="${1:-Avro}"
  if ! has_lang_files "*.avsc"; then
    return 1
  fi
  return 0
}
