#!/usr/bin/env sh
# Objective-C Logic Module

# Purpose: Objective-C usually uses system compilers (clang).
install_runtime_objc() {
  if [ "$_G_OS" != "macos" ]; then
    log_warn "Objective-C (Apple) toolchain is only supported on macOS."
    return 1
  fi

  if command -v clang >/dev/null 2>&1; then
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would check for clang/xcode-select."
    return 0
  fi

  log_warn "Clang not found. Please install Xcode Command Line Tools: xcode-select --install"
  return 1
}

# Purpose: Sets up Objective-C environment for project.
setup_objc() {
  local _T0_OBJC_RT
  _T0_OBJC_RT=$(date +%s)
  _log_setup "Objective-C" "clang"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Objective-C" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Objective-C files
  if ! has_lang_files "" "*.m *.mm"; then
    log_summary "Runtime" "Objective-C" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_OBJC_RT="✅ Available"
  install_runtime_objc || _STAT_OBJC_RT="⚠️ Missing"

  local _DUR_OBJC_RT
  _DUR_OBJC_RT=$(($(date +%s) - _T0_OBJC_RT))

  local _OBJC_VER="-"
  if command -v clang >/dev/null 2>&1; then
    _OBJC_VER=$(clang --version | head -n 1 | awk '{print $4}')
  fi

  log_summary "Runtime" "Objective-C" "$_STAT_OBJC_RT" "$_OBJC_VER" "$_DUR_OBJC_RT"
}

# Purpose: Checks if Objective-C compiler is available.
check_runtime_objc() {
  local _TOOL_DESC_OBJC="${1:-Objective-C}"
  if ! command -v clang >/dev/null 2>&1; then
    log_warn "Required runtime 'clang' for $_TOOL_DESC_OBJC is missing. Skipping."
    return 1
  fi
  return 0
}
