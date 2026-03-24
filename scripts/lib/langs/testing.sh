#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Testing Logic Module

# Purpose: Installs bats (Bash Automated Testing System).
# Delegate: Managed by mise (.mise.toml)
install_bats() {
  local _T0_BATS
  _T0_BATS=$(date +%s)
  local _TITLE="Bats"
  local _PROVIDER="${VER_BATS_PROVIDER:-npm:bats}"

  if ! has_lang_files "" "*.bats"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version bats --version)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Testing" "Bats" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Testing" "Bats" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_BATS="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_BATS="❌ Failed"
  log_summary "Testing" "Bats" "$_STAT_BATS" "$(get_version bats --version)" "$(($(date +%s) - _T0_BATS))"
}

# Purpose: Installs bats-libs (helper libraries for bats).
install_bats_libs() {
  if ! has_lang_files "" "*.bats"; then
    return 0
  fi
  log_summary "Testing" "Bats-Libs" "✅ Active" "-" "0"
}

# Purpose: Checks for Playwright deployment configurations.
install_playwright() {
  if ! has_lang_files "" "PLAYWRIGHT"; then
    return 0
  fi
  log_summary "Testing" "Playwright" "✅ Detected" "-" "0"
}

# Purpose: Checks for Cypress deployment configurations.
install_cypress() {
  if ! has_lang_files "" "CYPRESS"; then
    return 0
  fi
  log_summary "Testing" "Cypress" "✅ Detected" "-" "0"
}

# Purpose: Checks for Vitest deployment configurations.
install_vitest() {
  if ! has_lang_files "" "VITEST"; then
    return 0
  fi
  log_summary "Testing" "Vitest" "✅ Detected" "-" "0"
}

# Purpose: Sets up Testing environment.
setup_testing() {
  install_bats
  install_bats_libs
  install_playwright
  install_cypress
  install_vitest
}
