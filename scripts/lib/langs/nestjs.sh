#!/usr/bin/env sh
# NestJS Logic Module

# Purpose: Sets up NestJS environment for project.
setup_nestjs() {
  local _T0_NESTJS_RT
  _T0_NESTJS_RT=$(date +%s)
  _log_setup "NestJS" "nestjs"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Web Framework" "NestJS" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect NestJS: check for nest-cli.json or package.json with @nestjs/core
  if [ -f "nest-cli.json" ]; then
    :
  elif [ -f "package.json" ] && grep -q "@nestjs/core" "package.json"; then
    :
  else
    log_summary "Web Framework" "NestJS" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_NESTJS_RT="✅ Detected"

  # Heuristic version detection: check nest version
  local _VER_NESTJS="-"
  if command -v nest >/dev/null 2>&1; then
    _VER_NESTJS=$(nest --version 2>/dev/null || echo "-")
  fi

  local _DUR_NESTJS_RT
  _DUR_NESTJS_RT=$(($(date +%s) - _T0_NESTJS_RT))
  log_summary "Web Framework" "NestJS" "$_STAT_NESTJS_RT" "$_VER_NESTJS" "$_DUR_NESTJS_RT"
}

# Purpose: Checks if NestJS is relevant.
check_runtime_nestjs() {
  local _TOOL_DESC_NESTJS="${1:-NestJS}"
  if [ -f "nest-cli.json" ]; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q "@nestjs/core" "package.json"; then
    return 0
  fi
  return 1
}
