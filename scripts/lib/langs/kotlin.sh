#!/usr/bin/env sh
# Kotlin Logic Module

# Purpose: Installs Kotlin runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_kotlin() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Kotlin runtime."
    return 0
  fi
  run_mise install kotlin
  eval "$(mise activate bash --shims)"
}

# Purpose: Installs ktlint.
# Delegate: Managed by mise (.mise.toml)
install_ktlint() {
  local _T0_KT
  _T0_KT=$(date +%s)
  local _TITLE="ktlint"
  local _PROVIDER="npm:@naturalcycles/ktlint"

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Kotlin" "ktlint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_KT="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_KT="❌ Failed"
  log_summary "Kotlin" "ktlint" "$_STAT_KT" "$(get_version ktlint --version)" "$(($(date +%s) - _T0_KT))"
}

# Purpose: Sets up Kotlin runtime and mandatory linting tools.
setup_kotlin() {
  if ! has_lang_files "build.gradle.kts" "*.kt *.kts"; then
    return 0
  fi

  local _T0_KOTLIN_RT
  _T0_KOTLIN_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version kotlin)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "kotlin")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Kotlin" "✅ Detected" "$_CUR_VER" "0"
  else
    _log_setup "Kotlin Runtime" "kotlin"

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_summary "Runtime" "Kotlin" "⚖️ Previewed" "-" "0"
    else
      local _STAT_KOTLIN_RT="✅ Installed"
      install_runtime_kotlin || _STAT_KOTLIN_RT="❌ Failed"

      local _DUR_KOTLIN_RT
      _DUR_KOTLIN_RT=$(($(date +%s) - _T0_KOTLIN_RT))
      log_summary "Runtime" "Kotlin" "$_STAT_KOTLIN_RT" "$(get_version kotlin -version | head -n 1)" "$_DUR_KOTLIN_RT"
    fi
  fi

  # Also ensure linting tools are present
  install_ktlint
}
# Purpose: Checks if Kotlin runtime is available.
# Examples:
#   check_runtime_kotlin "Linter"
check_runtime_kotlin() {
  local _TOOL_DESC_KOTLIN="${1:-Kotlin}"
  if ! command -v kotlin >/dev/null 2>&1; then
    log_warn "Required runtime 'kotlin' for $_TOOL_DESC_KOTLIN is missing. Skipping."
    return 1
  fi
  return 0
}
