#!/usr/bin/env bash
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
  eval "$(mise activate bash --shims)"

  # 2. Dependency resolution
  if [ -f "composer.json" ]; then
    run_quiet composer install --no-interaction --prefer-dist
  fi
}

# Purpose: Sets up PHP runtime.
# Delegate: Managed by mise (.mise.toml)
setup_php() {
  local _T0_PHP_RT
  _T0_PHP_RT=$(date +%s)
  _log_setup "PHP Runtime" "php"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "PHP" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "composer.json" "*.php"; then
    log_summary "Runtime" "PHP" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PHP_RT="✅ Installed"
  install_runtime_php || _STAT_PHP_RT="❌ Failed"

  local _DUR_PHP_RT
  _DUR_PHP_RT=$(($(date +%s) - _T0_PHP_RT))
  log_summary "Runtime" "PHP" "$_STAT_PHP_RT" "$(get_version php)" "$_DUR_PHP_RT"
}
