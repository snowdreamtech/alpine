#!/usr/bin/env sh
# Dlang Logic Module

# Purpose: Installs Dlang (dmd) via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_dlang() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Dlang (dmd) via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "dmd@${MISE_TOOL_VERSION_DLANG}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Dlang environment for project.
setup_dlang() {
  if ! has_lang_files "dub.json dub.sdl" "*.d"; then
    return 0
  fi

  local _T0_D_RT
  _T0_D_RT=$(date +%s)
  _log_setup "Dlang" "dmd"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Dlang" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_D_RT="✅ Installed"
  install_runtime_dlang || _STAT_D_RT="❌ Failed"

  local _DUR_D_RT
  _DUR_D_RT=$(($(date +%s) - _T0_D_RT))
  log_summary "Runtime" "Dlang" "$_STAT_D_RT" "$(get_version dmd --version | head -n 1 | awk '{print $4}')" "$_DUR_D_RT"
}

# Purpose: Checks if Dlang is available.
# Examples:
#   check_runtime_dlang "Linter"
check_runtime_dlang() {
  local _TOOL_DESC_D="${1:-Dlang}"
  if ! command -v dmd >/dev/null 2>&1; then
    log_warn "Required runtime 'dmd' for $_TOOL_DESC_D is missing. Skipping."
    return 1
  fi
  return 0
}
