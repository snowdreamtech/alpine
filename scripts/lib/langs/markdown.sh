#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Markdown Logic Module

# Purpose: Installs markdownlint for Markdown linting.
# Delegate: Managed by mise (.mise.toml)
install_markdownlint() {
  local _T0_MD
  _T0_MD=$(date +%s)
  local _TITLE="Markdownlint"
  local _PROVIDER="${VER_MARKDOWNLINT_PROVIDER:-}"
  local _VERSION="${VER_MARKDOWNLINT:-}"

  if ! has_lang_files "" "*.md"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version markdownlint-cli2 "" "markdownlint-cli2")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Docs" "Markdownlint" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Docs" "Markdownlint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_MD="✅ mise"
  if ! run_mise install "${_PROVIDER:-}@${_VERSION:-}"; then
    _STAT_MD="❌ Failed"
    log_summary "Docs" "Markdownlint" "${_STAT_MD:-}" "-" "$(($(date +%s) - _T0_MD))"
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

    if ! verify_tool_atomic "markdownlint-cli2" "${_PROVIDER:-}" "${_TITLE:-}" "--version"; then
      _STAT_MD="❌ Not Usable"
      log_summary "Docs" "Markdownlint" "${_STAT_MD:-}" "-" "$(($(date +%s) - _T0_MD))"
      log_error "${_TITLE:-} installed but failed atomic verification."
      return 1
    fi
  fi

  log_summary "Docs" "Markdownlint" "${_STAT_MD:-}" "$(get_version markdownlint)" "$(($(date +%s) - _T0_MD))"
}

# Purpose: Sets up Markdown environment.
setup_markdown() {
  install_markdownlint
}
