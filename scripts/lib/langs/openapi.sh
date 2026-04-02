#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# OpenAPI Logic Module

# Purpose: Installs spectral for OpenAPI/AsyncAPI linting.
# Delegate: Managed by mise (.mise.toml)
install_spectral() {
  local _T0_SPEC
  _T0_SPEC=$(date +%s)
  local _TITLE="Spectral"
  local _PROVIDER="${VER_SPECTRAL_PROVIDER:-}"
  local _VERSION="${VER_SPECTRAL:-}"

  if ! has_lang_files "" "openapi.yaml openapi.json asyncapi.yaml asyncapi.json"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version spectral)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary"API" "Spectral" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "API" "Spectral" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_SPEC="✅ mise"
  setup_registry_spectral
  run_mise install "${_PROVIDER:-}@${_VERSION:-}" || _STAT_SPEC="❌ Failed"
  log_summary "API" "Spectral" "${_STAT_SPEC:-}" "$(get_version spectral)" "$(($(date +%s) - _T0_SPEC))"
}

# Purpose: Sets up OpenAPI environment.
setup_openapi() {
  install_spectral
}
