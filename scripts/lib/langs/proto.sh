#!/usr/bin/env sh
# Protobuf Logic Module

# Purpose: Sets up Protobuf environment for project.
setup_proto() {
  local _T0_PROTO_RT
  _T0_PROTO_RT=$(date +%s)
  _log_setup "Protobuf" "proto"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "API Tool" "Protobuf" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Protobuf files
  if ! has_lang_files "*.proto"; then
    log_summary "API Tool" "Protobuf" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Protobuf is typically handled by protoc or buf.
  # We focus on detection and availability.
  local _STAT_PROTO_RT="✅ Detected"

  local _DUR_PROTO_RT
  _DUR_PROTO_RT=$(($(date +%s) - _T0_PROTO_RT))
  log_summary "API Tool" "Protobuf" "$_STAT_PROTO_RT" "-" "$_DUR_PROTO_RT"
}

# Purpose: Checks if Protobuf files are present.
check_runtime_proto() {
  local _TOOL_DESC_PROTO="${1:-Protobuf}"
  if ! has_lang_files "*.proto"; then
    return 1
  fi
  return 0
}
