#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# TOML Logic Module

# Purpose: Installs Taplo.
# Delegate: Managed by mise (.mise.toml)
install_taplo() {
  local _T0_TAP
  _T0_TAP=$(date +%s)
  local _TITLE="Taplo"
  local _PROVIDER="${VER_TAPLO_PROVIDER:-}"
  local _VERSION="${VER_TAPLO:-}"
  if ! has_lang_files "" "*.toml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version taplo "" "@taplo/cli")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Base" "Taplo" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Taplo" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_TAP="✅ mise"
  if ! run_mise install "${_PROVIDER:-}@${_VERSION:-}"; then
    _STAT_TAP="❌ Failed"
    log_summary "Base" "Taplo" "${_STAT_TAP:-}" "-" "$(($(date +%s) - _T0_TAP))"
    if is_ci_env; then
      log_error "Failed to install ${_TITLE:-} in CI."
      return 1
    else
      log_warn "Failed to install ${_TITLE:-}. Continuing..."
      return 0
    fi
  fi

  # Atomic verification: Ensure tool is fully usable
  if is_ci_env; then
    log_debug "Performing atomic verification for ${_TITLE:-}..."
    mise reshim 2>/dev/null || true
    sleep 1

    if ! verify_tool_atomic "taplo" "${_PROVIDER:-}" "${_TITLE:-}" "--version"; then
      _STAT_TAP="❌ Not Usable"
      log_summary "Base" "Taplo" "${_STAT_TAP:-}" "-" "$(($(date +%s) - _T0_TAP))"
      log_error "${_TITLE:-} installed but failed atomic verification."
      return 1
    fi
  fi

  log_summary "Base" "Taplo" "${_STAT_TAP:-}" "$(get_version taplo)" "$(($(date +%s) - _T0_TAP))"
}

# Purpose: Sets up TOML environment.
setup_toml() {
  install_taplo
}
