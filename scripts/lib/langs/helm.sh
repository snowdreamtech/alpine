#!/usr/bin/env sh
# Helm Logic Module

# Purpose: Installs Helm via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_helm() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Helm via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "helm@${MISE_TOOL_VERSION_HELM}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Helm environment for project.
setup_helm() {
  local _T0_HELM_RT
  _T0_HELM_RT=$(date +%s)
  _log_setup "Helm" "helm"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "IaC Tool" "Helm" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Helm files
  if ! has_lang_files "Chart.yaml values.yaml" "CHARTS"; then
    log_summary "IaC Tool" "Helm" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_HELM_RT="✅ Installed"
  install_runtime_helm || _STAT_HELM_RT="❌ Failed"

  local _DUR_HELM_RT
  _DUR_HELM_RT=$(($(date +%s) - _T0_HELM_RT))
  log_summary "IaC Tool" "Helm" "$_STAT_HELM_RT" "$(get_version helm version --short)" "$_DUR_HELM_RT"
}

# Purpose: Checks if Helm is available.
# Examples:
#   check_runtime_helm "Linter"
check_runtime_helm() {
  local _TOOL_DESC_HELM="${1:-Helm}"
  if ! command -v helm >/dev/null 2>&1; then
    log_warn "Required tool 'helm' for $_TOOL_DESC_HELM is missing. Skipping."
    return 1
  fi
  return 0
}
