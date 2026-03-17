#!/usr/bin/env sh
# Terraform Logic Module

# Purpose: Installs OpenTofu via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_tofu() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Terraform via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "terraform@${MISE_TOOL_VERSION_TERRAFORM}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Terraform environment for project.
setup_terraform() {
  local _T0_TF_RT
  _T0_TF_RT=$(date +%s)
  _log_setup "Terraform" "terraform"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Terraform" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Terraform files
  if ! has_lang_files "" "*.tf *.tfvars *.hcl"; then
    log_summary "Runtime" "Terraform" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TF_RT="✅ Installed"
  install_runtime_terraform || _STAT_TF_RT="❌ Failed"

  local _DUR_TF_RT
  _DUR_TF_RT=$(($(date +%s) - _T0_TF_RT))
  log_summary "Runtime" "Terraform" "$_STAT_TF_RT" "$(get_version terraform)" "$_DUR_TF_RT"
}

# Purpose: Checks if Terraform is available.
# Examples:
#   check_runtime_terraform "Linter"
check_runtime_terraform() {
  local _TOOL_DESC_TF="${1:-Terraform}"
  if ! command -v terraform >/dev/null 2>&1; then
    log_warn "Required runtime 'terraform' for $_TOOL_DESC_TF is missing. Skipping."
    return 1
  fi
  return 0
}
