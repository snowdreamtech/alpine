#!/usr/bin/env sh
# Flutter Logic Module

# Purpose: Installs Flutter runtime via mise.
install_runtime_flutter() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Flutter runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "flutter@${MISE_TOOL_VERSION_FLUTTER}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Flutter runtime.
setup_flutter() {
  local _T0_FLUTTER_RT
  _T0_FLUTTER_RT=$(date +%s)
  _log_setup "Flutter Runtime" "flutter"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Flutter" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "pubspec.yaml" ""; then
    log_summary "Runtime" "Flutter" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Skip if it's just a Dart project without Flutter dependencies
  if ! grep -q "flutter:" "pubspec.yaml"; then
    log_summary "Runtime" "Flutter" "⏭️ Skipped (Dart only)" "-" "0"
    return 0
  fi

  local _STAT_FLUTTER_RT="✅ Installed"
  install_runtime_flutter || _STAT_FLUTTER_RT="❌ Failed"

  local _DUR_FLUTTER_RT
  _DUR_FLUTTER_RT=$(($(date +%s) - _T0_FLUTTER_RT))
  log_summary "Runtime" "Flutter" "$_STAT_FLUTTER_RT" "$(get_version flutter --version | head -n 1)" "$_DUR_FLUTTER_RT"
}
