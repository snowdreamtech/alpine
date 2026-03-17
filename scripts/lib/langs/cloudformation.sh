#!/usr/bin/env sh
# CloudFormation Logic Module

# Purpose: Sets up CloudFormation environment for project.
setup_cloudformation() {
  local _T0_CFN_RT
  _T0_CFN_RT=$(date +%s)
  _log_setup "CloudFormation" "cloudformation"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "IaC Tool" "CloudFormation" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect CloudFormation files
  if ! has_lang_files "*.template *.cfn.yaml *.cfn.json"; then
    log_summary "IaC Tool" "CloudFormation" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # CloudFormation is typically handled by 'aws cloudformation' or 'cfn-lint'.
  # We focus on detection and availability.
  local _STAT_CFN_RT="✅ Detected"

  local _DUR_CFN_RT
  _DUR_CFN_RT=$(($(date +%s) - _T0_CFN_RT))
  log_summary "IaC Tool" "CloudFormation" "$_STAT_CFN_RT" "-" "$_DUR_CFN_RT"
}

# Purpose: Checks if CloudFormation files are present.
check_runtime_cloudformation() {
  local _TOOL_DESC_CFN="${1:-CloudFormation}"
  if ! has_lang_files "*.template *.cfn.yaml *.cfn.json"; then
    return 1
  fi
  return 0
}
