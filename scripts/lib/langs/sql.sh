#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# SQL Logic Module

# Purpose: Installs sqlfluff for SQL linting.
# Delegate: Managed by mise (.mise.toml)
install_sqlfluff() {
  local _T0_SQL
  _T0_SQL=$(date +%s)
  local _TITLE="Sqlfluff"
  local _PROVIDER="${VER_SQLFLUFF_PROVIDER:-}"
  local _VERSION="${VER_SQLFLUFF:-}"

  if ! has_lang_files "" "*.sql"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version sqlfluff)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Data" "Sqlfluff" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data" "Sqlfluff" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_SQL="✅ mise"
  run_mise install "${_PROVIDER:-}@${_VERSION:-}" || _STAT_SQL="❌ Failed"
  log_summary "Data" "Sqlfluff" "${_STAT_SQL:-}" "$(get_version sqlfluff)" "$(($(date +%s) - _T0_SQL))"
}

# Purpose: Sets up SQL environment.
setup_sql() {
  install_sqlfluff
}
