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

  log_info "=== install_shfmt: Starting ==="
  log_info "Provider: ${_PROVIDER:-}, Version: ${_VERSION:-}, CI: $(is_ci_env && echo YES || echo NO)"

  # In CI, always install (required by pre-commit hooks)
  # Locally, only install if shell files exist
  if ! is_ci_env && ! has_lang_files "" "*.sh *.bash *.bats"; then
    log_info "⏭️  Skipping Shfmt: No shell files detected"
    log_summary "Base" "Shfmt" "⏭️ Skipped" "-" "0"
    return 0
  fi

  log_info "Proceeding with Shfmt (CI or shell files detected)"

  # Step 1: Check if binary exists and works (FIRST, before version check)
  log_info "Step 1: Checking if shfmt binary exists and is executable"
  local _BINARY_EXISTS=0
  if verify_binary_exists "shfmt" "--version"; then
    log_info "Step 1: ✓ Binary exists and is executable"
    _BINARY_EXISTS=1
  else
    log_info "Step 1: ✗ Binary not found or not executable"
    _BINARY_EXISTS=0
  fi

  # Step 2: Check version ONLY if binary exists
  local _CUR_VER="-"
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")
  log_info "Step 2: Required version: ${_REQ_VER:-<none>}"

  if [ "${_BINARY_EXISTS:-0}" -eq 1 ]; then
    _CUR_VER=$(get_version shfmt)
    log_info "Step 2: Current version (binary exists): ${_CUR_VER:-<none>}"
  else
    log_info "Step 2: Skipping version check (binary doesn't exist)"
  fi

  # Step 3: Determine if installation is needed
  log_info "Step 3: Determining if installation is needed"
  local _NEEDS_INSTALL=0

  if [ "${_BINARY_EXISTS:-0}" -eq 0 ]; then
    log_info "Step 3: Binary doesn't exist → INSTALL NEEDED"
    _NEEDS_INSTALL=1
  elif [ "${_CUR_VER:-}" = "-" ] || [ -z "${_CUR_VER:-}" ]; then
    log_info "Step 3: No version detected (despite binary existing) → INSTALL NEEDED"
    _NEEDS_INSTALL=1
  elif ! is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_info "Step 3: Version mismatch (${_CUR_VER:-} != ${_REQ_VER:-}) → INSTALL NEEDED"
    _NEEDS_INSTALL=1
  else
    log_info "Step 3: Binary exists + version matches → NO INSTALL NEEDED"
    log_summary "Base" "Shfmt" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  # Step 4: Clean up if binary exists but needs reinstall
  if [ "${_BINARY_EXISTS:-0}" -eq 1 ] && [ "${_NEEDS_INSTALL:-0}" -eq 1 ]; then
    log_warn "Step 4: Binary exists but needs reinstall - cleaning up"
    mise uninstall "${_PROVIDER:-}" 2>/dev/null || true
    refresh_mise_cache
  fi

  # Step 5: Install
  log_info "Step 5: Installing ${_PROVIDER:-}@${_VERSION:-}"
  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Shfmt" '⚖️ Previewed' "-" '0'
    return 0
  fi

  local _STAT_SHF="✅ mise"
  if ! run_mise install "${_PROVIDER:-}@${_VERSION:-}"; then
    _STAT_SHF="❌ Failed"
    log_error "Step 5: mise install FAILED"
    log_summary "Base" "Shfmt" "${_STAT_SHF:-}" "-" "$(($(date +%s) - _T0_SHF))"
    if is_ci_env; then
      return 1
    else
      return 0
    fi
  fi

  log_info "Step 5: mise install succeeded"

  # Step 6: Post-install verification
  log_info "Step 6: Post-install verification"
  mise reshim 2>/dev/null || true
  sleep 1

  # Step 6a: Verify binary now exists
  if ! verify_binary_exists "shfmt" "--version"; then
    log_error "Step 6a: Binary still not found after installation!"
    log_summary "Base" "Shfmt" "❌ Not Found" "-" "$(($(date +%s) - _T0_SHF))"
    return 1
  fi
  log_info "Step 6a: Binary exists after installation"

  # Step 6b: Atomic verification (comprehensive check)
  if is_ci_env; then
    log_info "Step 6b: Running atomic verification"
    if ! verify_tool_atomic "shfmt" "${_PROVIDER:-}" "${_TITLE:-}" "--version"; then
      log_error "Step 6b: Atomic verification FAILED"
      log_summary "Base" "Shfmt" "❌ Not Usable" "-" "$(($(date +%s) - _T0_SHF))"
      return 1
    fi
    log_info "Step 6b: Atomic verification succeeded"
  fi

  log_summary "Base" "Shfmt" "${_STAT_SHF:-}" "$(get_version shfmt)" "$(($(date +%s) - _T0_SHF))"
  log_info "=== install_shfmt: Completed successfully ==="
}
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
