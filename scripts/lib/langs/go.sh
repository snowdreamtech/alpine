#!/usr/bin/env bash
# Go Logic Module

# Purpose: Installs Go runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_go() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Go runtime."
    return 0
  fi

  # Runtime initialization
  run_mise install go
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Go runtime for project.
# Delegate: Managed by mise (.mise.toml)
setup_go() {
  local _T0_GO_RT
  _T0_GO_RT=$(date +%s)
  _log_setup "Go Runtime" "go"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Go" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "go.mod go.sum" "*.go"; then
    log_summary "Runtime" "Go" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_GO_RT="✅ Installed"
  install_runtime_go || _STAT_GO_RT="❌ Failed"

  local _DUR_GO_RT
  _DUR_GO_RT=$(($(date +%s) - _T0_GO_RT))
  log_summary "Runtime" "Go" "$_STAT_GO_RT" "$(get_version go)" "$_DUR_GO_RT"
}
