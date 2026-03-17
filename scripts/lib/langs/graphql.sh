#!/usr/bin/env sh
# GraphQL Logic Module

# Purpose: Sets up GraphQL environment for project.
setup_graphql() {
  local _T0_GQL_RT
  _T0_GQL_RT=$(date +%s)
  _log_setup "GraphQL" "graphql"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "API Tool" "GraphQL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect GraphQL files
  if ! has_lang_files "*.graphql *.gql"; then
    log_summary "API Tool" "GraphQL" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # GraphQL is typically handled by language-specific libraries.
  # We focus on detection and availability of common tools if needed.
  local _STAT_GQL_RT="✅ Detected"

  local _DUR_GQL_RT
  _DUR_GQL_RT=$(($(date +%s) - _T0_GQL_RT))
  log_summary "API Tool" "GraphQL" "$_STAT_GQL_RT" "-" "$_DUR_GQL_RT"
}

# Purpose: Checks if GraphQL files are present.
check_runtime_graphql() {
  local _TOOL_DESC_GQL="${1:-GraphQL}"
  if ! has_lang_files "*.graphql *.gql"; then
    return 1
  fi
  return 0
}
