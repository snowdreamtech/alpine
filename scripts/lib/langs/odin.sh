#!/usr/bin/env sh
# Odin Logic Module

# Purpose: Installs Odin compiler via mise.
install_runtime_odin() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Odin compiler via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "odin@${MISE_TOOL_VERSION_ODIN}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Odin environment for project.
setup_odin() {
  local _T0_ODIN_RT
  _T0_ODIN_RT=$(date +%s)
  _log_setup "Odin" "odin"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Odin" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Odin files
  if ! has_lang_files "" "*.odin"; then
    log_summary "Runtime" "Odin" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_ODIN_RT="✅ Installed"
  install_runtime_odin || _STAT_ODIN_RT="❌ Failed"

  local _DUR_ODIN_RT
  _DUR_ODIN_RT=$(($(date +%s) - _T0_ODIN_RT))
  log_summary "Runtime" "Odin" "$_STAT_ODIN_RT" "$(get_version odin version)" "$_DUR_ODIN_RT"
}

# Purpose: Checks if Odin compiler is available.
check_runtime_odin() {
  local _TOOL_DESC_ODIN="${1:-Odin}"
  if ! command -v odin >/dev/null 2>&1; then
    log_warn "Required runtime 'odin' for $_TOOL_DESC_ODIN is missing. Skipping."
    return 1
  fi
  return 0
}
