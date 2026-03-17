#!/usr/bin/env sh
# MongoDB Logic Module

# Purpose: Sets up MongoDB environment for project.
setup_mongodb() {
  local _T0_MONGODB_RT
  _T0_MONGODB_RT=$(date +%s)
  _log_setup "MongoDB" "mongodb"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Database" "MongoDB" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect MongoDB: check for mongodb.conf or entry in common config files
  if [ -f "mongodb.conf" ] || grep -qi "mongo" docker-compose.yml 2>/dev/null; then
    :
  elif [ -f "package.json" ] && grep -q "mongodb" "package.json"; then
    :
  elif [ -f "requirements.txt" ] && grep -E -q "^pymongo([=<>! ]|$)" "requirements.txt"; then
    :
  else
    log_summary "Database" "MongoDB" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_MONGODB_RT="✅ Detected"

  # Heuristic version detection
  local _VER_MONGODB="-"
  if command -v mongod >/dev/null 2>&1; then
    _VER_MONGODB=$(mongod --version | head -n1 | awk '{print $NF}' | tr -d 'v' || echo "-")
  fi

  local _DUR_MONGODB_RT
  _DUR_MONGODB_RT=$(($(date +%s) - _T0_MONGODB_RT))
  log_summary "Database" "MongoDB" "$_STAT_MONGODB_RT" "$_VER_MONGODB" "$_DUR_MONGODB_RT"
}

# Purpose: Checks if MongoDB is relevant.
check_runtime_mongodb() {
  local _TOOL_DESC_MONGODB="${1:-MongoDB}"
  if [ -f "mongodb.conf" ] || grep -qi "mongo" docker-compose.yml 2>/dev/null; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q "mongodb" "package.json"; then
    return 0
  fi
  if [ -f "requirements.txt" ] && grep -E -q "^pymongo([=<>! ]|$)" "requirements.txt"; then
    return 0
  fi
  return 1
}
