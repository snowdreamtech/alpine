#!/usr/bin/env sh
# LangChain Logic Module

# Purpose: Sets up LangChain environment for project.
setup_langchain() {
  local _T0_LANGCHAIN_RT
  _T0_LANGCHAIN_RT=$(date +%s)
  _log_setup "LangChain" "langchain"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "AI Tool" "LangChain" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect LangChain: check for langchain in requirement files
  if [ -f "requirements.txt" ] && grep -q "langchain" "requirements.txt"; then
    :
  elif [ -f "package.json" ] && grep -q "langchain" "package.json"; then
    :
  elif [ -f "pyproject.toml" ] && grep -q "langchain" "pyproject.toml"; then
    :
  else
    log_summary "AI Tool" "LangChain" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_LANGCHAIN_RT="✅ Detected"

  local _DUR_LANGCHAIN_RT
  _DUR_LANGCHAIN_RT=$(($(date +%s) - _T0_LANGCHAIN_RT))
  log_summary "AI Tool" "LangChain" "$_STAT_LANGCHAIN_RT" "-" "$_DUR_LANGCHAIN_RT"
}

# Purpose: Checks if LangChain is relevant.
check_runtime_langchain() {
  local _TOOL_DESC_LANGCHAIN="${1:-LangChain}"
  if [ -f "requirements.txt" ] && grep -q "langchain" "requirements.txt"; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q "langchain" "package.json"; then
    return 0
  fi
  if grep -q "langchain" ./* 2>/dev/null; then
    return 0
  fi
  return 1
}
