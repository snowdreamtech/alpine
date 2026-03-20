#!/usr/bin/env sh
# Rego Logic Module

# Purpose: Installs OPA/Rego.
# Delegate: Managed by mise (.mise.toml)
install_rego() {
  local _T0_REGO
  _T0_REGO=$(date +%s)
  local _TITLE="Rego (OPA)"
  local _PROVIDER="github:open-policy-agent/opa"
  if ! has_lang_files "" "REGO"; then
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "Rego" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_REGO="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_REGO="❌ Failed"
  log_summary "Security" "Rego" "$_STAT_REGO" "$(get_version opa version | grep Version | awk '{print $NF}')" "$(($(date +%s) - _T0_REGO))"
}

# Purpose: Sets up Rego environment for project.
setup_rego() {
  install_rego
}
