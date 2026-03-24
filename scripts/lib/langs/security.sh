#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Security Logic Module

# Purpose: Installs osv-scanner for vulnerability scanning.
# CI-only: Heavy GitHub Release binary (~40MB). Local dev skips to prevent stalling.
install_osv_scanner() {
  local _T0_OSV
  _T0_OSV=$(date +%s)
  local _TITLE="OSV-Scanner"
  local _PROVIDER="${VER_OSV_SCANNER_PROVIDER}"

  # CI-only guard: skip on local dev to prevent 40MB download stall.
  if ! is_ci_env; then
    log_summary "Security" "OSV-Scanner" "⏭️ CI-only" "-" "0"
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version osv-scanner)
  local _REQ_VER="${VER_OSV_SCANNER}"

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Security" "OSV-Scanner" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "OSV-Scanner" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_OSV="✅ mise"
  setup_registry_osv_scanner
  if ! run_mise install "$_PROVIDER"; then
    _STAT_OSV="❌ Failed"
    if is_ci_env; then
      log_warn "Optional security tool ($_TITLE) failed to install. Continuing..."
    fi
  fi
  log_summary "Security" "OSV-Scanner" "$_STAT_OSV" "$(get_version osv-scanner)" "$(($(date +%s) - _T0_OSV))"
}

# Purpose: Installs trivy for vulnerability scanning.
# CI-only: Heavy GitHub Release binary (~80MB). Local dev skips to prevent stalling.
install_trivy() {
  local _T0_TRIVY
  _T0_TRIVY=$(date +%s)
  local _TITLE="Trivy"
  local _PROVIDER="${VER_TRIVY_PROVIDER}"

  # CI-only guard: skip on local dev to prevent 80MB download stall.
  if ! is_ci_env; then
    log_summary "Security" "Trivy" "⏭️ CI-only" "-" "0"
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version trivy)
  local _REQ_VER="${VER_TRIVY}"

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Security" "Trivy" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "Trivy" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_TRIVY="✅ mise"
  setup_registry_trivy
  if ! run_mise install "$_PROVIDER"; then
    _STAT_TRIVY="❌ Failed"
    if is_ci_env; then
      log_warn "Optional security tool ($_TITLE) failed to install. Continuing..."
    fi
  fi
  log_summary "Security" "Trivy" "$_STAT_TRIVY" "$(get_version trivy)" "$(($(date +%s) - _T0_TRIVY))"
}

# Purpose: Installs zizmor for GitHub Actions security linting.
# Delegate: Managed by mise (.mise.toml)
install_zizmor() {
  local _T0_ZIZ
  _T0_ZIZ=$(date +%s)
  local _TITLE="Zizmor"
  local _PROVIDER="${VER_ZIZMOR_PROVIDER}"

  if ! has_lang_files ".github/workflows" "*.yaml *.yml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version zizmor)
  local _REQ_VER="${VER_ZIZMOR}"

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Security" "Zizmor" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "Zizmor" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_ZIZ="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ZIZ="❌ Failed"
  log_summary "Security" "Zizmor" "$_STAT_ZIZ" "$(get_version zizmor)" "$(($(date +%s) - _T0_ZIZ))"
}

# Purpose: Installs cargo-audit for Rust vulnerability scanning.
# CI-only: Requires downloading the Rust Advisory DB (network-heavy). Local dev skips.
# Delegate: Managed by mise (.mise.toml)
install_cargo_audit() {
  local _T0_CA
  _T0_CA=$(date +%s)
  local _TITLE="Cargo-Audit"
  local _PROVIDER="${VER_CARGO_AUDIT_PROVIDER}"

  if ! has_lang_files "Cargo.toml Cargo.lock" ""; then
    return 0
  fi

  # CI-only guard: Advisory DB download is network-heavy, skip locally.
  if ! is_ci_env; then
    log_summary "Security" "Cargo-Audit" "⏭️ CI-only" "-" "0"
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version cargo-audit)
  local _REQ_VER="${VER_CARGO_AUDIT}"

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Security" "Cargo-Audit" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "Cargo-Audit" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_CA="✅ mise"
  setup_registry_cargo_audit
  run_mise install "$_PROVIDER" || _STAT_CA="❌ Failed"
  log_summary "Security" "Cargo-Audit" "$_STAT_CA" "$(get_version cargo-audit)" "$(($(date +%s) - _T0_CA))"
}

# Purpose: Sets up Security audit environment.
setup_security() {
  install_osv_scanner
  install_trivy
  install_zizmor
  setup_rego # From rego.sh
  # Optional: logic for govulncheck/pip-audit can stay in go.sh/python.sh or be here
  install_cargo_audit
}
