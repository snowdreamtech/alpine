#!/usr/bin/env sh
# MoonBit Logic Module

# Purpose: Installs MoonBit via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_moonbit() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install MoonBit via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "moonbit@${MISE_TOOL_VERSION_MOONBIT}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up MoonBit environment for project.
setup_moonbit() {
  local _T0_MOON_RT
  _T0_MOON_RT=$(date +%s)
  _log_setup "MoonBit" "moon"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "MoonBit" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect MoonBit project
  if ! has_lang_files "moon.pkg.json" "*.mbt"; then
    log_summary "Runtime" "MoonBit" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_MOON_RT="✅ Installed"
  install_runtime_moonbit || _STAT_MOON_RT="❌ Failed"

  local _DUR_MOON_RT
  _DUR_MOON_RT=$(($(date +%s) - _T0_MOON_RT))
  log_summary "Runtime" "MoonBit" "$_STAT_MOON_RT" "$(get_version moon version | head -n 1 | awk '{print $NF}')" "$_DUR_MOON_RT"
}

# Purpose: Checks if MoonBit is available.
# Examples:
#   check_runtime_moonbit "Linter"
check_runtime_moonbit() {
  local _TOOL_DESC_MOON="${1:-MoonBit}"
  if ! command -v moon >/dev/null 2>&1; then
    log_warn "Required runtime 'moon' for $_TOOL_DESC_MOON is missing. Skipping."
    return 1
  fi
  return 0
}
