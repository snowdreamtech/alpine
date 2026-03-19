#!/usr/bin/env sh
# Lua Logic Module

# Purpose: Installs Lua runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_lua() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Lua runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "lua@${MISE_TOOL_VERSION_LUA}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Lua runtime and mandatory linting tools.
setup_lua() {
  if ! has_lang_files "" "*.lua"; then
    return 0
  fi

  local _T0_LUA_RT
  _T0_LUA_RT=$(date +%s)
  _log_setup "Lua Runtime" "lua"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Lua" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_LUA_RT="✅ Installed"
  install_runtime_lua || _STAT_LUA_RT="❌ Failed"

  local _DUR_LUA_RT
  _DUR_LUA_RT=$(($(date +%s) - _T0_LUA_RT))
  log_summary "Runtime" "Lua" "$_STAT_LUA_RT" "$(get_version lua -v | head -n 1)" "$_DUR_LUA_RT"

  # Also ensure linting tools are present
  install_stylua
}
# Purpose: Checks if Lua runtime is available.
# Examples:
#   check_runtime_lua "Linter"
check_runtime_lua() {
  local _TOOL_DESC_LUA="${1:-Lua}"
  if ! command -v lua >/dev/null 2>&1; then
    log_warn "Required runtime 'lua' for $_TOOL_DESC_LUA is missing. Skipping."
    return 1
  fi
  return 0
}
