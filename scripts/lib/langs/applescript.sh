#!/usr/bin/env sh
# AppleScript Logic Module

# Purpose: Sets up AppleScript environment for project.
setup_applescript() {
  local _T0_AS_RT
  _T0_AS_RT=$(date +%s)
  _log_setup "AppleScript" "applescript"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Desktop Tool" "AppleScript" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect AppleScript files
  if ! has_lang_files "*.applescript *.scpt"; then
    log_summary "Desktop Tool" "AppleScript" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # AppleScript is native to macOS.
  # We focus on detection and availability of osascript.
  local _STAT_AS_RT="✅ Detected"

  local _DUR_AS_RT
  _DUR_AS_RT=$(($(date +%s) - _T0_AS_RT))
  log_summary "Desktop Tool" "AppleScript" "$_STAT_AS_RT" "-" "$_DUR_AS_RT"
}

# Purpose: Checks if osascript is available.
check_runtime_applescript() {
  local _TOOL_DESC_AS="${1:-AppleScript}"
  if ! command -v osascript >/dev/null 2>&1; then
    log_warn "Required tool 'osascript' for $_TOOL_DESC_AS is missing. OS might not be macOS."
    return 1
  fi
  return 0
}
