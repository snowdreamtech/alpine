#!/usr/bin/env sh
# Move Logic Module

# Purpose: Installs Move toolchain (via aptos CLI) via mise.
install_runtime_move() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Aptos CLI (Move toolchain) via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "aptos@${MISE_TOOL_VERSION_MOVE}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Move environment for project.
setup_move() {
  local _T0_MOVE_RT
  _T0_MOVE_RT=$(date +%s)
  _log_setup "Move" "aptos"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Move" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Move files
  if ! has_lang_files "Move.toml" "*.move"; then
    log_summary "Runtime" "Move" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_MOVE_RT="✅ Installed"
  install_runtime_move || _STAT_MOVE_RT="❌ Failed"

  local _DUR_MOVE_RT
  _DUR_MOVE_RT=$(($(date +%s) - _T0_MOVE_RT))
  log_summary "Runtime" "Move" "$_STAT_MOVE_RT" "$(get_version aptos --version | awk '{print $NF}')" "$_DUR_MOVE_RT"
}

# Purpose: Checks if Move (aptos) is available.
check_runtime_move() {
  local _TOOL_DESC_MOVE="${1:-Move}"
  if ! command -v aptos >/dev/null 2>&1; then
    log_warn "Required runtime 'aptos' for $_TOOL_DESC_MOVE is missing. Skipping."
    return 1
  fi
  return 0
}
