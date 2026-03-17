#!/usr/bin/env sh
# AsyncAPI Logic Module

# Purpose: Sets up AsyncAPI environment for project.
setup_asyncapi() {
  local _T0_ASYNCAPI_RT
  _T0_ASYNCAPI_RT=$(date +%s)
  _log_setup "AsyncAPI" "asyncapi"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "AsyncAPI" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect AsyncAPI: check for asyncapi.yaml or asyncapi.json
  if ! has_lang_files "asyncapi.yaml asyncapi.yml asyncapi.json"; then
    log_summary "Data Tool" "AsyncAPI" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_ASYNCAPI_RT="✅ Detected"

  local _DUR_ASYNCAPI_RT
  _DUR_ASYNCAPI_RT=$(($(date +%s) - _T0_ASYNCAPI_RT))
  log_summary "Data Tool" "AsyncAPI" "$_STAT_ASYNCAPI_RT" "-" "$_DUR_ASYNCAPI_RT"
}

# Purpose: Checks if AsyncAPI is relevant.
check_runtime_asyncapi() {
  local _TOOL_DESC_ASYNCAPI="${1:-AsyncAPI}"
  if has_lang_files "asyncapi.yaml asyncapi.yml asyncapi.json"; then
    return 0
  fi
  return 1
}
