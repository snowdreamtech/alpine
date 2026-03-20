#!/usr/bin/env sh
# PHP Logic Module

# Purpose: Installs PHP runtime via mise.
# Delegate: Managed via mise (.mise.toml) and composer.
install_runtime_php() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install PHP runtime."
    return 0
  fi

  # 1. Runtime initialization
  run_mise install php

  # 2. Dependency resolution
  if [ -f "composer.json" ]; then
    run_quiet composer install --no-interaction --prefer-dist
  fi
}

# Purpose: Sets up PHP runtime.
# Delegate: Managed by mise (.mise.toml)
setup_php() {
  if ! has_lang_files "composer.json" "*.php"; then
    return 0
  fi

  local _T0_PHP_RT
  _T0_PHP_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version php)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "php")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "PHP" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "PHP Runtime" "php"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "PHP" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_PHP_RT="✅ Installed"
  install_runtime_php || _STAT_PHP_RT="❌ Failed"

  local _DUR_PHP_RT
  _DUR_PHP_RT=$(($(date +%s) - _T0_PHP_RT))
  log_summary "Runtime" "PHP" "$_STAT_PHP_RT" "$(get_version php)" "$_DUR_PHP_RT"
}
# Purpose: Checks if PHP runtime is available.
# Examples:
#   check_runtime_php "Linter"
check_runtime_php() {
  local _TOOL_DESC_PHP="${1:-PHP}"
  if ! command -v php >/dev/null 2>&1; then
    log_warn "Required runtime 'php' for $_TOOL_DESC_PHP is missing. Skipping."
    return 1
  fi
  return 0
}
