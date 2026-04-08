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
  local _PROVIDER="${VER_SHFMT_PROVIDER:-}"
  local _VERSION="${VER_SHFMT:-}"

  # In CI, always install (required by pre-commit hooks)
  # Locally, only install if shell files exist
  if ! is_ci_env && ! has_lang_files "" "*.sh *.bash *.bats"; then
    log_info "⏭️  Skipping Shfmt: No shell files detected (FORCE_SETUP=${FORCE_SETUP:-0})"
    log_summary "Base" "Shfmt" "⏭️ Skipped" "-" "0"
    return 0
  fi

  log_debug "Shell files detected or CI environment, proceeding with Shfmt installation"

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version shfmt)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    # In CI, verify the tool is actually executable, not just registered in mise
    if is_ci_env; then
      if ! command -v shfmt >/dev/null 2>&1 && ! mise exec "${_PROVIDER:-}" -- shfmt --version >/dev/null 2>&1; then
        log_warn "Shfmt is registered in mise but not executable. Force reinstalling..."
        # Force reinstall by removing from mise first
        mise uninstall "${_PROVIDER:-}" 2>/dev/null || true
      else
        log_summary "Base" "Shfmt" "✅ Exists" "${_CUR_VER:-}" "0"
        return 0
      fi
    else
      log_summary "Base" "Shfmt" "✅ Exists" "${_CUR_VER:-}" "0"
      return 0
    fi
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Shfmt" '⚖️ Previewed' "-" '0'
    return 0
  fi

  local _STAT_SHF="✅ mise"
  if ! run_mise install "${_PROVIDER:-}@${_VERSION:-}"; then
    _STAT_SHF="❌ Failed"
    log_summary "Base" "Shfmt" "${_STAT_SHF:-}" "-" "$(($(date +%s) - _T0_SHF))"
    if is_ci_env; then
      log_error "Failed to install ${_TITLE:-} in CI."
      return 1
    else
      log_warn "Failed to install ${_TITLE:-}. Continuing..."
      return 0
    fi
  fi
  log_summary "Base" "Shfmt" "${_STAT_SHF:-}" "$(get_version shfmt)" "$(($(date +%s) - _T0_SHF))"
}

# Purpose: Installs Shellcheck.
# Delegate: Managed by mise (.mise.toml)
install_shellcheck() {
  local _T0_SHC
  _T0_SHC=$(date +%s)
  local _TITLE="Shellcheck"
  local _PROVIDER="${VER_SHELLCHECK_PROVIDER:-}"
  local _VERSION="${VER_SHELLCHECK:-}"

  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    log_info "⏭️  Skipping Shellcheck: No shell files detected (FORCE_SETUP=${FORCE_SETUP:-0})"
    log_summary "Base" "Shellcheck" "⏭️ Skipped" "-" "0"
    return 0
  fi

  log_debug "Shell files detected, proceeding with Shellcheck installation"

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
  if ! run_mise install "${_PROVIDER:-}@${_VERSION:-}"; then
    _STAT_SHC="❌ Failed"
    log_summary "Base" "Shellcheck" "${_STAT_SHC:-}" "-" "$(($(date +%s) - _T0_SHC))"
    if is_ci_env; then
      log_error "Failed to install ${_TITLE:-} in CI."
      return 1
    else
      log_warn "Failed to install ${_TITLE:-}. Continuing..."
      return 0
    fi
  fi
  log_summary "Base" "Shellcheck" "${_STAT_SHC:-}" "$(get_version shellcheck)" "$(($(date +%s) - _T0_SHC))"
}

# Purpose: Installs Actionlint.
# Delegate: Managed by mise (.mise.toml)
install_actionlint() {
  local _T0_ACT
  _T0_ACT=$(date +%s)
  local _TITLE="Actionlint"
  local _PROVIDER="${VER_ACTIONLINT_PROVIDER:-}"
  local _VERSION="${VER_ACTIONLINT:-}"
  if ! has_lang_files ".github/workflows" "*.yml *.yaml"; then
    log_info "⏭️  Skipping Actionlint: No GitHub workflow files detected (FORCE_SETUP=${FORCE_SETUP:-0})"
    log_summary "Base" "Actionlint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  log_debug "GitHub workflow files detected, proceeding with Actionlint installation"

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
  if ! run_mise install "${_PROVIDER:-}@${_VERSION:-}"; then
    _STAT_ACT="❌ Failed"
    log_summary "Base" "Actionlint" "${_STAT_ACT:-}" "-" "$(($(date +%s) - _T0_ACT))"
    if is_ci_env; then
      log_error "Failed to install ${_TITLE:-} in CI."
      return 1
    else
      log_warn "Failed to install ${_TITLE:-}. Continuing..."
      return 0
    fi
  fi
  log_summary "Base" "Actionlint" "${_STAT_ACT:-}" "$(get_version actionlint)" "$(($(date +%s) - _T0_ACT))"
}

# Purpose: Sets up Shell environment.
setup_shell() {
  install_shfmt
  install_shellcheck
  install_actionlint
}
