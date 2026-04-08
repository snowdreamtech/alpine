#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Protobuf Logic Module

# Purpose: Installs buf for Protobuf linting/management.
# Delegate: Managed by mise (.mise.toml)
install_buf() {
  local _T0_BUF
  _T0_BUF=$(date +%s)
  local _TITLE="Buf"
  local _PROVIDER="${VER_BUF_PROVIDER:-}"
  local _VERSION="${VER_BUF:-}"
  if ! has_lang_files "" "PROTOC"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version buf --version)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Protobuf" "Buf" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Protobuf" "Buf" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_BUF="✅ mise"
  setup_registry_buf
  run_mise install "${_PROVIDER:-}@${_VERSION:-}" || _STAT_BUF="❌ Failed"

  # Atomic verification: ensure tool is fully functional
  if ! verify_tool_atomic "buf" "--version"; then
    _STAT_BUF="❌ Not Executable"
    log_summary "Protobuf" "Buf" "${_STAT_BUF:-}" "-" "$(($(date +%s) - _T0_BUF))"
    [ "${CI:-}" = "true" ] && return 1
    return 0
  fi

  log_summary "Protobuf" "Buf" "${_STAT_BUF:-}" "$(get_version buf --version)" "$(($(date +%s) - _T0_BUF))"
}

# Purpose: Sets up Protobuf environment.
setup_protobuf() {
  install_buf
}
