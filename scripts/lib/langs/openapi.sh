#!/usr/bin/env sh
# OpenAPI Logic Module

# Purpose: Sets up OpenAPI environment for project.
setup_openapi() {
  local _T0_OAI_RT
  _T0_OAI_RT=$(date +%s)
  _log_setup "OpenAPI" "openapi"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "API Tool" "OpenAPI" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect OpenAPI files
  if ! has_lang_files "openapi.yaml openapi.json swagger.yaml swagger.json"; then
    log_summary "API Tool" "OpenAPI" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # OpenAPI is often audited by Spectral (already integrated) or other tools.
  # We focus on detection and metadata.
  local _STAT_OAI_RT="✅ Detected"

  local _DUR_OAI_RT
  _DUR_OAI_RT=$(($(date +%s) - _T0_OAI_RT))
  log_summary "API Tool" "OpenAPI" "$_STAT_OAI_RT" "-" "$_DUR_OAI_RT"
}

# Purpose: Checks if OpenAPI files are present.
check_runtime_openapi() {
  local _TOOL_DESC_OAI="${1:-OpenAPI}"
  if ! has_lang_files "openapi.yaml openapi.json swagger.yaml swagger.json"; then
    return 1
  fi
  return 0
}
