#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Shell Logic Module

# Purpose: Installs Shfmt.
# Delegate: Managed by mise (.mise.toml)
install_shfmt() {
  local _T0_SHF
  _T0_SHF=$(date +%s)
  local _TITLE="Shfmt"
  local _PROVIDER="shfmt"

  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    return 0
  fi

  # Fast-path: Check version-aware existence (prefix match to handle pkg vs binary diffs)
  local _CUR_VER
  _CUR_VER=$(get_version shfmt)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if [ "${_CUR_VER:-}" != "-" ] && [ -n "${_REQ_VER:-}" ]; then
    case "${_REQ_VER:-}" in "${_CUR_VER:-}"*)
      log_summary "Base" "Shfmt" "✅ Exists" "${_CUR_VER:-}" "0"
      return 0
      ;;
    esac
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Shfmt" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_SHF="✅ mise"
  run_mise install "${_PROVIDER:-}" || _STAT_SHF="❌ Failed"
  log_summary "Base" "Shfmt" "${_STAT_SHF:-}" "$(get_version shfmt)" "$(($(date +%s) - _T0_SHF))"
}

# Purpose: Installs Shellcheck.
# Delegate: Managed by mise (.mise.toml)
install_shellcheck() {
  local _T0_SHC
  _T0_SHC=$(date +%s)
  local _TITLE="Shellcheck"
  local _PROVIDER="shellcheck"

  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version shellcheck)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if [ "${_CUR_VER:-}" != "-" ]; then
    if [ "${_REQ_VER:-}" = "latest" ]; then
      log_summary "Base" "Shellcheck" "✅ Exists" "${_CUR_VER:-}" "0"
      return 0
    fi
    case "${_REQ_VER:-}" in "${_CUR_VER:-}"*)
      log_summary "Base" "Shellcheck" "✅ Exists" "${_CUR_VER:-}" "0"
      return 0
      ;;
    esac
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Shellcheck" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_SHC="✅ mise"
  run_mise install "${_PROVIDER:-}" || _STAT_SHC="❌ Failed"
  log_summary "Base" "Shellcheck" "${_STAT_SHC:-}" "$(get_version shellcheck)" "$(($(date +%s) - _T0_SHC))"
}

# Purpose: Installs Actionlint.
# Delegate: Managed by mise (.mise.toml)
install_actionlint() {
  local _T0_ACT
  _T0_ACT=$(date +%s)
  local _TITLE="Actionlint"
  local _PROVIDER="actionlint"
  if ! has_lang_files ".github/workflows" "*.yml *.yaml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version actionlint)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if [ "${_CUR_VER:-}" != "-" ] && [ -n "${_REQ_VER:-}" ]; then
    case "${_REQ_VER:-}" in "${_CUR_VER:-}"*)
      log_summary "Base" "Actionlint" "✅ Exists" "${_CUR_VER:-}" "0"
      return 0
      ;;
    esac
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Actionlint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_ACT="✅ mise"
  run_mise install "${_PROVIDER:-}" || _STAT_ACT="❌ Failed"
  log_summary "Base" "Actionlint" "${_STAT_ACT:-}" "$(get_version actionlint)" "$(($(date +%s) - _T0_ACT))"
}

# Purpose: Sets up Shell environment.
setup_shell() {
  install_shfmt
  install_shellcheck
  install_actionlint
}
