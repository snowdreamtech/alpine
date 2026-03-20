#!/usr/bin/env sh
# TOML Logic Module

# Purpose: Installs Taplo.
# Delegate: Managed by mise (.mise.toml)
install_taplo() {
  local _T0_TAP
  _T0_TAP=$(date +%s)
  local _TITLE="Taplo"
  local _PROVIDER="npm:@taplo/cli"
  if ! has_lang_files "" "*.toml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version taplo "" "@taplo/cli")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Base" "Taplo" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Taplo" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_TAP="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TAP="❌ Failed"
  log_summary "Base" "Taplo" "$_STAT_TAP" "$(get_version taplo)" "$(($(date +%s) - _T0_TAP))"
}

# Purpose: Sets up TOML environment.
setup_toml() {
  install_taplo
}
