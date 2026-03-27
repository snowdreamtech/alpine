#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Terraform Logic Module

# Purpose: Installs Terraform via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_terraform() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Terraform via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "terraform@$(get_mise_tool_version terraform)"
}

# Purpose: Installs TFLint.
# Delegate: Managed by mise (.mise.toml)
install_tflint() {
  local _T0_TF
  _T0_TF=$(date +%s)
  local _TITLE="TFLint"
  local _PROVIDER="github:terraform-linters/tflint"
  if ! has_lang_files "" "*.tf"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version tflint)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "IaC" "TFLint" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "IaC" "TFLint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_TF="✅ mise"
  setup_registry_tflint
  run_mise install "${_PROVIDER:-}" || _STAT_TF="❌ Failed"
  log_summary "IaC" "TFLint" "${_STAT_TF:-}" "$(get_version tflint)" "$(($(date +%s) - _T0_TF))"
}

# Purpose: Sets up Terraform environment for project.
setup_terraform() {
  if ! has_lang_files "" "*.tf *.tfvars *.hcl"; then
    return 0
  fi

  local _T0_TF_RT
  _T0_TF_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version terraform)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "terraform")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Runtime" "Terraform" "✅ Detected" "${_CUR_VER:-}" "0"
  else
    _log_setup "Terraform" "terraform"

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_summary "Runtime" "Terraform" "⚖️ Previewed" "-" "0"
    else
      local _STAT_TF_RT="✅ Installed"
      install_runtime_terraform || _STAT_TF_RT="❌ Failed"

      local _DUR_TF_RT
      _DUR_TF_RT=$(($(date +%s) - _T0_TF_RT))
      log_summary "Runtime" "Terraform" "${_STAT_TF_RT:-}" "$(get_version terraform)" "${_DUR_TF_RT:-}"
    fi
  fi

  # Setup related tools
  install_tflint
}

# Purpose: Checks if Terraform is available.
# Examples:
#   check_runtime_terraform "Linter"
check_runtime_terraform() {
  local _TOOL_DESC_TF="${1:-Terraform}"
  if ! resolve_bin "terraform" >/dev/null 2>&1; then
    log_warn "Required runtime 'terraform' for ${_TOOL_DESC_TF:-} is missing. Skipping."
    return 1
  fi
  return 0
}
