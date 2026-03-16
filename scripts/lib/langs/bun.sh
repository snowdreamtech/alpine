#!/usr/bin/env bash
# Bun Logic Module

# Purpose: Installs Bun runtime via mise.
install_runtime_bun() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Bun runtime."
    return 0
  fi
  run_mise install bun
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Bun runtime.
setup_bun() {
  local _T0_BUN_RT
  _T0_BUN_RT=$(date +%s)
  _log_setup "Bun Runtime" "bun"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Bun" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "bun.lockb" ""; then
    log_summary "Runtime" "Bun" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_BUN_RT="✅ Installed"
  install_runtime_bun || _STAT_BUN_RT="❌ Failed"

  local _DUR_BUN_RT
  _DUR_BUN_RT=$(($(date +%s) - _T0_BUN_RT))
  log_summary "Runtime" "Bun" "$_STAT_BUN_RT" "$(get_version bun --version)" "$_DUR_BUN_RT"
}
