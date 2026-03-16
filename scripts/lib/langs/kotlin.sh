#!/usr/bin/env bash
# Kotlin Logic Module

# Purpose: Installs Kotlin runtime via mise.
install_runtime_kotlin() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Kotlin runtime."
    return 0
  fi
  run_mise install kotlin
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Kotlin runtime and mandatory linting tools.
setup_kotlin() {
  local _T0_KOTLIN_RT
  _T0_KOTLIN_RT=$(date +%s)
  _log_setup "Kotlin Runtime" "kotlin"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Kotlin" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "build.gradle.kts" "*.kt *.kts"; then
    log_summary "Runtime" "Kotlin" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_KOTLIN_RT="✅ Installed"
  install_runtime_kotlin || _STAT_KOTLIN_RT="❌ Failed"

  local _DUR_KOTLIN_RT
  _DUR_KOTLIN_RT=$(($(date +%s) - _T0_KOTLIN_RT))
  log_summary "Runtime" "Kotlin" "$_STAT_KOTLIN_RT" "$(get_version kotlin -version | head -n 1)" "$_DUR_KOTLIN_RT"

  # Also ensure linting tools are present
  install_ktlint
}
