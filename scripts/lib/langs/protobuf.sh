#!/usr/bin/env sh
# Protobuf Logic Module

# Purpose: Installs buf for Protobuf linting/management.
# Delegate: Managed by mise (.mise.toml)
install_buf() {
  local _T0_BUF
  _T0_BUF=$(date +%s)
  local _TITLE="Buf"
  local _PROVIDER="github:bufbuild/buf"
  if ! has_lang_files "" "PROTOC"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version buf --version)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Protobuf" "Buf" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Protobuf" "Buf" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_BUF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_BUF="❌ Failed"
  log_summary "Protobuf" "Buf" "$_STAT_BUF" "$(get_version buf --version)" "$(($(date +%s) - _T0_BUF))"
}

# Purpose: Sets up Protobuf environment.
setup_protobuf() {
  install_buf
}
