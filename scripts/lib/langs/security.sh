#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Security Logic Module

# Purpose: Installs osv-scanner for vulnerability scanning.
# CI-only: Compiled via `go install` from Go proxy. Local dev skips to avoid build time.
install_osv_scanner() {
  local _T0_OSV
  _T0_OSV=$(date +%s)
  local _TITLE="OSV-Scanner"
  local _PROVIDER="${VER_OSV_SCANNER_PROVIDER:-}"
  local _VERSION="${VER_OSV_SCANNER:-}"

  # CI-only guard by default, but allow manual/explicit on-demand installation
  # for local developers who explicitly run 'make audit'.
  local _OSV_BIN
  _OSV_BIN=$(resolve_bin "osv-scanner") || true
  if [ -n "${_OSV_BIN:-}" ]; then
    log_success "✅ OSV-Scanner: Active (Found at ${_OSV_BIN:-})"
    return 0
  fi

  # Tier 3 Tool: Optional for local development.
  if ! is_ci_env && [ "${OSV_FORCE_INSTALL:-0}" -ne 1 ]; then
    log_summary "Security" "OSV-Scanner" "⏭️ Optional (CI-only by default)" "-" "0"
    log_info "⏭️  OSV-Scanner: Optional for local development. Set OSV_FORCE_INSTALL=1 to force installation."
    return 0
  fi

  log_info "Installing OSV-Scanner..."

  # Skip if manually disabled
  if [ "${SKIP_OSV:-0}" -eq 1 ]; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version osv-scanner)
  local _REQ_VER="${VER_OSV_SCANNER:-}"

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Security" "OSV-Scanner" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "OSV-Scanner" '⚖️ Previewed' "-" '0'
    return 0
  fi

  local _STAT_OSV="✅ mise"
  setup_registry_osv_scanner
  # Explicitly use mise to install the github provider
  if ! run_mise install "${_PROVIDER:-}@${_VERSION:-}"; then
    _STAT_OSV="❌ Failed"
    if is_ci_env; then
      log_warn "Optional security tool (${_TITLE:-}) failed to install. Continuing..."
    fi
  fi
  log_summary "Security" "OSV-Scanner" "${_STAT_OSV:-}" "$(get_version osv-scanner)" "$(($(date +%s) - _T0_OSV))"
}

# NOTE: Trivy CLI installation removed. Vulnerability scanning is handled by
# aquasecurity/trivy-action in CI workflows (ci.yml), which bundles its own binary.
# This eliminates ~80MB GitHub Release downloads and prevents GitHub API 403 rate limits.

# Purpose: Installs zizmor for GitHub Actions security linting.
# Delegate: Managed by mise (.mise.toml)
install_zizmor() {
  local _T0_ZIZ
  _T0_ZIZ=$(date +%s)
  local _TITLE="Zizmor"
  local _PROVIDER="${VER_ZIZMOR_PROVIDER:-}"
  local _VERSION="${VER_ZIZMOR:-}"

  # CI-only: GH Actions security linter is rarely needed for local app code.
  local _ZIZMOR_BIN
  _ZIZMOR_BIN=$(resolve_bin "zizmor") || true
  if [ -n "${_ZIZMOR_BIN:-}" ]; then
    log_success "✅ Zizmor: Active (Found at ${_ZIZMOR_BIN:-})"
    return 0
  fi

  # Tier 3 Tool: Optional for local development.
  if ! is_ci_env && [ "${ZIZMOR_FORCE_INSTALL:-0}" -ne 1 ]; then
    log_summary "Security" "Zizmor" "⏭️ Optional (CI-only by default)" "-" "0"
    log_info "⏭️  Zizmor: Optional for local development. Set ZIZMOR_FORCE_INSTALL=1 to force installation."
    return 0
  fi

  log_info "Installing zizmor..."

  if ! has_lang_files ".github/workflows" "*.yaml *.yml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version zizmor)
  local _REQ_VER="${VER_ZIZMOR:-}"

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Security" "Zizmor" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "Zizmor" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_ZIZ="✅ mise"
  setup_registry_zizmor
  run_mise install "${_PROVIDER:-}@${_VERSION:-}" || _STAT_ZIZ="❌ Failed"
  log_summary "Security" "Zizmor" "${_STAT_ZIZ:-}" "$(get_version zizmor)" "$(($(date +%s) - _T0_ZIZ))"
}

# Purpose: Installs cargo-audit for Rust vulnerability scanning.
# CI-only: Requires downloading the Rust Advisory DB (network-heavy). Local dev skips.
# Delegate: Managed by mise (.mise.toml)
install_cargo_audit() {
  local _T0_CA
  _T0_CA=$(date +%s)
  local _TITLE="Cargo-Audit"
  local _PROVIDER="${VER_CARGO_AUDIT_PROVIDER:-}"
  local _VERSION="${VER_CARGO_AUDIT:-}"

  if ! has_lang_files "Cargo.toml Cargo.lock" ""; then
    return 0
  fi

  # CI-only guard: Advisory DB download is network-heavy, skip locally.
  local _CA_BIN
  _CA_BIN=$(resolve_bin "cargo-audit") || true
  if [ -n "${_CA_BIN:-}" ]; then
    log_success "✅ Cargo-audit: Active (Found at ${_CA_BIN:-})"
    return 0
  fi

  # Tier 3 Tool: Optional for local development.
  if ! is_ci_env && [ "${CA_FORCE_INSTALL:-0}" -ne 1 ]; then
    log_summary "Security" "Cargo-audit" "⏭️ Optional (CI-only by default)" "-" "0"
    log_info "⏭️  Cargo-audit: Optional for local development. Set CA_FORCE_INSTALL=1 to force installation."
    return 0
  fi

  log_info "Installing cargo-audit..."

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version cargo-audit)
  local _REQ_VER="${VER_CARGO_AUDIT:-}"

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Security" "Cargo-Audit" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "Cargo-Audit" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_CA="✅ mise"
  setup_registry_cargo_audit
  run_mise install "${_PROVIDER:-}@${_VERSION:-}" || _STAT_CA="❌ Failed"
  log_summary "Security" "Cargo-Audit" "${_STAT_CA:-}" "$(get_version cargo-audit)" "$(($(date +%s) - _T0_CA))"
}

# Purpose: Sets up Security audit environment.
setup_security() {
  install_osv_scanner
  install_zizmor
  setup_rego # From rego.sh
  # Optional: logic for govulncheck/pip-audit can stay in go.sh/python.sh or be here
  install_cargo_audit
}
