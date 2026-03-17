#!/usr/bin/env sh
# PostgreSQL Logic Module

# Purpose: Sets up PostgreSQL environment for project.
setup_postgresql() {
  local _T0_POSTGRESQL_RT
  _T0_POSTGRESQL_RT=$(date +%s)
  _log_setup "PostgreSQL" "postgresql"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Database" "PostgreSQL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect PostgreSQL: check for pg_hba.conf or entry in common config files
  if [ -f "pg_hba.conf" ] || grep -qi "postgres" docker-compose.yml 2>/dev/null; then
    :
  elif [ -f "package.json" ] && grep -q "pg" "package.json"; then
    :
  elif [ -f "requirements.txt" ] && grep -E -q "^psycopg2(-binary)?([=<>! ]|$)" "requirements.txt"; then
    :
  elif [ -f "pyproject.toml" ] && grep -q "psycopg2" "pyproject.toml"; then
    :
  else
    log_summary "Database" "PostgreSQL" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_POSTGRESQL_RT="✅ Detected"

  # Heuristic version detection
  local _VER_POSTGRESQL="-"
  if command -v psql >/dev/null 2>&1; then
    _VER_POSTGRESQL=$(psql --version | awk '{print $NF}' || echo "-")
  fi

  local _DUR_POSTGRESQL_RT
  _DUR_POSTGRESQL_RT=$(($(date +%s) - _T0_POSTGRESQL_RT))
  log_summary "Database" "PostgreSQL" "$_STAT_POSTGRESQL_RT" "$_VER_POSTGRESQL" "$_DUR_POSTGRESQL_RT"
}

# Purpose: Checks if PostgreSQL is relevant.
check_runtime_postgresql() {
  local _TOOL_DESC_POSTGRESQL="${1:-PostgreSQL}"
  if [ -f "pg_hba.conf" ] || grep -qi "postgres" docker-compose.yml 2>/dev/null; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q "pg" "package.json"; then
    return 0
  fi
  if [ -f "requirements.txt" ] && grep -E -q "^psycopg2(-binary)?([=<>! ]|$)" "requirements.txt"; then
    return 0
  fi
  if [ -f "pyproject.toml" ] && grep -q "psycopg2" "pyproject.toml"; then
    return 0
  fi
  return 1
}
