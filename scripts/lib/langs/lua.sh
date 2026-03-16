#!/usr/bin/env sh
# Lua Logic Module

# Purpose: Installs Lua runtime via mise.
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
  local _T0_LUA_RT
  _T0_LUA_RT=$(date +%s)
  _log_setup "Lua Runtime" "lua"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Lua" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.lua"; then
    log_summary "Runtime" "Lua" "⏭️ Skipped" "-" "0"
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
