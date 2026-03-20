#!/usr/bin/env sh
# Terragrunt Logic Module

# Purpose: Installs Terragrunt via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_terragrunt() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Terragrunt via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "terragrunt@$(get_mise_tool_version terragrunt)"
}

# Purpose: Sets up Terragrunt environment for project.
setup_terragrunt() {
  if ! has_lang_files "" "HCL"; then
    return 0
  fi

  local _T0_TERRA_RT
  _T0_TERRA_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version terragrunt)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "terragrunt")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Runtime" "Terragrunt" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "Terragrunt" "terragrunt"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Terragrunt" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_TERRA_RT="✅ Installed"
  install_runtime_terragrunt || _STAT_TERRA_RT="❌ Failed"

  local _DUR_TERRA_RT
  _DUR_TERRA_RT=$(($(date +%s) - _T0_TERRA_RT))
  log_summary "Runtime" "Terragrunt" "$_STAT_TERRA_RT" "$(get_version terragrunt --version | awk '{print $NF}')" "$_DUR_TERRA_RT"
}

# Purpose: Checks if Terragrunt is available.
# Examples:
#   check_runtime_terragrunt "Linter"
check_runtime_terragrunt() {
  local _TOOL_DESC_TERRA="${1:-Terragrunt}"
  if ! command -v terragrunt >/dev/null 2>&1; then
    log_warn "Required tool 'terragrunt' for $_TOOL_DESC_TERRA is missing. Skipping."
    return 1
  fi
  return 0
}
