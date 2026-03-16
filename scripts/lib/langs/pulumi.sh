#!/usr/bin/env bash
# Pulumi Logic Module

# Purpose: Installs Pulumi CLI via mise.
install_runtime_pulumi() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Pulumi CLI."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "pulumi@${MISE_TOOL_VERSION_PULUMI}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Pulumi IaC.
setup_pulumi() {
  local _T0_PULUMI_RT
  _T0_PULUMI_RT=$(date +%s)
  _log_setup "Pulumi CLI" "pulumi"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "IaC" "Pulumi" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Pulumi.yaml" ""; then
    log_summary "IaC" "Pulumi" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PULUMI_RT="✅ Installed"
  install_runtime_pulumi || _STAT_PULUMI_RT="❌ Failed"

  local _DUR_PULUMI_RT
  _DUR_PULUMI_RT=$(($(date +%s) - _T0_PULUMI_RT))
  log_summary "IaC" "Pulumi" "$_STAT_PULUMI_RT" "$(get_version pulumi version)" "$_DUR_PULUMI_RT"
}
