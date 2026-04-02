#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Helm Logic Module

# Purpose: Installs Helm via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_helm() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Helm via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "helm@$(get_mise_tool_version helm)"
}

# Purpose: Installs kube-linter.
# Delegate: Managed by mise (.mise.toml)
install_kube_linter() {
  local _T0_KL
  _T0_KL=$(date +%s)
  local _TITLE="Kube-Linter"
  local _PROVIDER="${VER_KUBE_LINTER_PROVIDER:-}"
  local _VERSION="${VER_KUBE_LINTER:-}"
  if ! has_lang_files "" "CHARTS *.yaml *.yml"; then
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"
  local _STAT_KL="✅ mise"
  run_mise install "${_PROVIDER:-}@${_VERSION:-}" || _STAT_KL="❌ Failed"
  log_summary "IaC" "Kube-Linter" "${_STAT_KL:-}" "$(get_version kube-linter version)" "$(($(date +%s) - _T0_KL))"
}

# Purpose: Sets up Helm environment for project.
setup_helm() {
  if ! has_lang_files "" "CHARTS *.yaml *.yml"; then
    return 0
  fi

  local _T0_HELM
  _T0_HELM=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version helm)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "helm")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "IaC" "Helm" "✅ Detected" "${_CUR_VER:-}" "0"
  else
    _log_setup "Helm" "helm"

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_summary "IaC" "Helm" "⚖️ Previewed" "-" "0"
    else
      local _STAT_HELM_RT="✅ Installed"
      install_runtime_helm || _STAT_HELM_RT="❌ Failed"

      local _DUR_HELM
      _DUR_HELM=$(($(date +%s) - _T0_HELM))
      log_summary "IaC" "Helm" "${_STAT_HELM_RT:-}" "$(get_version helm version --short)" "${_DUR_HELM:-}"
    fi
  fi

  # Setup related tools
  install_kube_linter
}

# Purpose: Checks if Helm is available.
# Examples:
#   check_runtime_helm "Linter"
check_runtime_helm() {
  local _TOOL_DESC_HELM="${1:-Helm}"
  if ! resolve_bin "helm" >/dev/null 2>&1; then
    log_warn "Required tool 'helm' for ${_TOOL_DESC_HELM:-} is missing. Skipping."
    return 1
  fi
  return 0
}
