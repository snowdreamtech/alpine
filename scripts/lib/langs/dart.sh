#!/usr/bin/env sh
# Dart Logic Module

# Purpose: Installs Dart runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_dart() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Dart runtime."
    return 0
  fi
  run_mise install dart
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Dart runtime.
setup_dart() {
  if ! has_lang_files "pubspec.yaml" "*.dart"; then
    return 0
  fi

  local _T0_DART_RT
  _T0_DART_RT=$(date +%s)
  _log_setup "Dart Runtime" "dart"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Dart" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_DART_RT="✅ Installed"
  install_runtime_dart || _STAT_DART_RT="❌ Failed"

  local _DUR_DART_RT
  _DUR_DART_RT=$(($(date +%s) - _T0_DART_RT))
  log_summary "Runtime" "Dart" "$_STAT_DART_RT" "$(get_version dart --version | head -n 1)" "$_DUR_DART_RT"
}
# Purpose: Checks if Dart runtime is available.
# Examples:
#   check_runtime_dart "Linter"
check_runtime_dart() {
  local _TOOL_DESC_DART="${1:-Dart}"
  if ! command -v dart >/dev/null 2>&1; then
    log_warn "Required runtime 'dart' for $_TOOL_DESC_DART is missing. Skipping."
    return 1
  fi
  return 0
}
