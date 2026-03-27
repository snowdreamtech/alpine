#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Docker Logic Module

# Purpose: Installs hadolint for Dockerfile linting.
# Delegate: Managed by mise (.mise.toml)
install_hadolint() {
  local _T0_HADO
  _T0_HADO=$(date +%s)
  local _TITLE="Hadolint"
  local _PROVIDER="github:hadolint/hadolint"

  if ! has_lang_files "" "Dockerfile docker-compose.yaml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version hadolint)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Docker" "Hadolint" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Docker" "Hadolint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_HADO="✅ mise"
  run_mise install "${_PROVIDER:-}" || _STAT_HADO="❌ Failed"
  log_summary "Docker" "Hadolint" "${_STAT_HADO:-}" "$(get_version hadolint)" "$(($(date +%s) - _T0_HADO))"
}

# Purpose: Installs dockerfile-utils for Dockerfile management.
# Delegate: Managed by mise (.mise.toml)
install_dockerfile_utils() {
  local _T0_DU
  _T0_DU=$(date +%s)
  local _TITLE="Dockerfile Utils"
  local _PROVIDER="npm:dockerfile-utils"

  if ! has_lang_files "" "Dockerfile"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version dockerfile-utils)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Docker" "dockerfile-utils" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Docker" "dockerfile-utils" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_DU="✅ mise"
  run_mise install "${_PROVIDER:-}" || _STAT_DU="❌ Failed"
  log_summary "Docker" "dockerfile-utils" "${_STAT_DU:-}" "$(get_version dockerfile-utils)" "$(($(date +%s) - _T0_DU))"
}

# Purpose: Sets up Docker environment.
setup_docker() {
  install_hadolint
  install_dockerfile_utils
}
