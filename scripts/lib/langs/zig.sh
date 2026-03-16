#!/usr/bin/env sh
# Zig Logic Module

# Purpose: Installs Zig runtime via mise.
install_runtime_zig() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Zig runtime."
    return 0
  fi
  run_mise install zig
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Zig runtime.
setup_zig() {
  local _T0_ZIG_RT
  _T0_ZIG_RT=$(date +%s)
  _log_setup "Zig Runtime" "zig"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Zig" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "build.zig" "*.zig"; then
    log_summary "Runtime" "Zig" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_ZIG_RT="✅ Installed"
  install_runtime_zig || _STAT_ZIG_RT="❌ Failed"

  local _DUR_ZIG_RT
  _DUR_ZIG_RT=$(($(date +%s) - _T0_ZIG_RT))
  log_summary "Runtime" "Zig" "$_STAT_ZIG_RT" "$(get_version zig version)" "$_DUR_ZIG_RT"
}
# Purpose: Checks if Zig runtime is available.
# Examples:
#   check_runtime_zig "Linter"
check_runtime_zig() {
  local _TOOL_DESC_ZIG="${1:-Zig}"
  if ! command -v zig >/dev/null 2>&1; then
    log_warn "Required runtime 'zig' for $_TOOL_DESC_ZIG is missing. Skipping."
    return 1
  fi
  return 0
}
