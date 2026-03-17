#!/usr/bin/env sh
# Terragrunt Logic Module

# Purpose: Installs Terragrunt via mise.
install_runtime_terragrunt() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Terragrunt via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "terragrunt@${MISE_TOOL_VERSION_TERRAGRUNT}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Terragrunt environment for project.
setup_terragrunt() {
  local _T0_TERRA_RT
  _T0_TERRA_RT=$(date +%s)
  _log_setup "Terragrunt" "terragrunt"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Terragrunt" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Terragrunt files
  if ! has_lang_files "terragrunt.hcl"; then
    log_summary "Runtime" "Terragrunt" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TERRA_RT="✅ Installed"
  install_runtime_terragrunt || _STAT_TERRA_RT="❌ Failed"

  local _DUR_TERRA_RT
  _DUR_TERRA_RT=$(($(date +%s) - _T0_TERRA_RT))
  log_summary "Runtime" "Terragrunt" "$_STAT_TERRA_RT" "$(get_version terragrunt --version | awk '{print $NF}')" "$_DUR_TERRA_RT"
}

# Purpose: Checks if Terragrunt is available.
check_runtime_terragrunt() {
  local _TOOL_DESC_TERRA="${1:-Terragrunt}"
  if ! command -v terragrunt >/dev/null 2>&1; then
    log_warn "Required tool 'terragrunt' for $_TOOL_DESC_TERRA is missing. Skipping."
    return 1
  fi
  return 0
}
