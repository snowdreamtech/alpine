#!/usr/bin/env sh
# Redis Logic Module

# Purpose: Sets up Redis environment for project.
setup_redis() {
  local _T0_REDIS_RT
  _T0_REDIS_RT=$(date +%s)
  _log_setup "Redis" "redis"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Database" "Redis" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Redis: check for redis.conf or entry in common config files
  if [ -f "redis.conf" ] || grep -qi "redis" docker-compose.yml 2>/dev/null; then
    :
  elif [ -f "package.json" ] && grep -q "redis" "package.json"; then
    :
  elif [ -f "requirements.txt" ] && grep -E -q "^redis([=<>! ]|$)" "requirements.txt"; then
    :
  else
    log_summary "Database" "Redis" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_REDIS_RT="✅ Detected"

  # Heuristic version detection
  local _VER_REDIS="-"
  if command -v redis-server >/dev/null 2>&1; then
    _VER_REDIS=$(redis-server --version | awk '{print $3}' | cut -d= -f2 || echo "-")
  fi

  local _DUR_REDIS_RT
  _DUR_REDIS_RT=$(($(date +%s) - _T0_REDIS_RT))
  log_summary "Database" "Redis" "$_STAT_REDIS_RT" "$_VER_REDIS" "$_DUR_REDIS_RT"
}

# Purpose: Checks if Redis is relevant.
check_runtime_redis() {
  local _TOOL_DESC_REDIS="${1:-Redis}"
  if [ -f "redis.conf" ] || grep -qi "redis" docker-compose.yml 2>/dev/null; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q "redis" "package.json"; then
    return 0
  fi
  if [ -f "requirements.txt" ] && grep -E -q "^redis([=<>! ]|$)" "requirements.txt"; then
    return 0
  fi
  return 1
}
