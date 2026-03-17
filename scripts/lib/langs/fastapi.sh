#!/usr/bin/env sh
# FastAPI Logic Module

# Purpose: Sets up FastAPI environment for project.
setup_fastapi() {
  local _T0_FASTAPI_RT
  _T0_FASTAPI_RT=$(date +%s)
  _log_setup "FastAPI" "fastapi"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Web Framework" "FastAPI" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect FastAPI: check for main.py with fastapi import or requirements.txt/pyproject.toml entry
  if [ -f "main.py" ] && grep -q "from fastapi" "main.py"; then
    :
  elif [ -f "requirements.txt" ] && grep -E -q "^fastapi([=<>! ]|$)" "requirements.txt"; then
    :
  elif [ -f "pyproject.toml" ] && grep -q "fastapi" "pyproject.toml"; then
    :
  else
    log_summary "Web Framework" "FastAPI" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_FASTAPI_RT="✅ Detected"
  local _VER_FASTAPI
  _VER_FASTAPI=$(pip show fastapi 2>/dev/null | grep "^Version:" | awk '{print $2}' || echo "-")

  local _DUR_FASTAPI_RT
  _DUR_FASTAPI_RT=$(($(date +%s) - _T0_FASTAPI_RT))
  log_summary "Web Framework" "FastAPI" "$_STAT_FASTAPI_RT" "$_VER_FASTAPI" "$_DUR_FASTAPI_RT"
}

# Purpose: Checks if FastAPI is relevant.
check_runtime_fastapi() {
  local _TOOL_DESC_FASTAPI="${1:-FastAPI}"
  if [ -f "main.py" ] && grep -q "from fastapi" "main.py"; then
    return 0
  fi
  if [ -f "requirements.txt" ] && grep -E -q "^fastapi([=<>! ]|$)" "requirements.txt"; then
    return 0
  fi
  if [ -f "pyproject.toml" ] && grep -q "fastapi" "pyproject.toml"; then
    return 0
  fi
  return 1
}
