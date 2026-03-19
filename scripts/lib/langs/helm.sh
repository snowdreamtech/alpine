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
  run_mise install "helm@$(get_mise_tool_version helm)"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Helm environment for project.
setup_helm() {
  if ! has_lang_files "" "CHARTS *.yaml *.yml"; then
    return 0
  fi

  local _T0_HELM
  _T0_HELM=$(date +%s)
  _log_setup "Helm" "helm"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "IaC" "Helm" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_HELM_RT="✅ Installed"
  install_runtime_helm || _STAT_HELM_RT="❌ Failed"

  local _DUR_HELM
  _DUR_HELM=$(($(date +%s) - _T0_HELM))
  log_summary "IaC" "Helm" "$_STAT_HELM_RT" "$(get_version helm version --short)" "$_DUR_HELM"
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
