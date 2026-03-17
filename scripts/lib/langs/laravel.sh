#!/usr/bin/env sh
# Laravel Logic Module

# Purpose: Sets up Laravel environment for project.
setup_laravel() {
  local _T0_LARAVEL_RT
  _T0_LARAVEL_RT=$(date +%s)
  _log_setup "Laravel" "laravel"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Web Framework" "Laravel" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Laravel: check for artisan or composer.json with laravel/framework
  if [ -f "artisan" ]; then
    :
  elif [ -f "composer.json" ] && grep -q "laravel/framework" "composer.json"; then
    :
  else
    log_summary "Web Framework" "Laravel" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_LARAVEL_RT="✅ Detected"

  # Heuristic version detection: check artisan --version
  local _VER_LARAVEL="-"
  if command -v php >/dev/null 2>&1 && [ -f "artisan" ]; then
    _VER_LARAVEL=$(php artisan --version 2>/dev/null | awk '{print $NF}' || echo "-")
  fi

  local _DUR_LARAVEL_RT
  _DUR_LARAVEL_RT=$(($(date +%s) - _T0_LARAVEL_RT))
  log_summary "Web Framework" "Laravel" "$_STAT_LARAVEL_RT" "$_VER_LARAVEL" "$_DUR_LARAVEL_RT"
}

# Purpose: Checks if Laravel is relevant.
check_runtime_laravel() {
  local _TOOL_DESC_LARAVEL="${1:-Laravel}"
  if [ -f "artisan" ]; then
    return 0
  fi
  if [ -f "composer.json" ] && grep -q "laravel/framework" "composer.json"; then
    return 0
  fi
  return 1
}
