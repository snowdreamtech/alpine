#!/usr/bin/env sh
# Qwik Logic Module

# Purpose: Sets up Qwik environment for project.
setup_qwik() {
  local _T0_QWIK_RT
  _T0_QWIK_RT=$(date +%s)
  _log_setup "Qwik" "qwik"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Qwik" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Qwik: check package.json or jsx/tsx
  local _IS_QWIK=0
  if [ -f "package.json" ] && grep -q '"@builder.io/qwik"' package.json; then
    _IS_QWIK=1
  elif has_lang_files "*.jsx *.tsx"; then
    # Fallback to general detection if no package.json
    _IS_QWIK=1
  fi

  if [ "${_IS_QWIK}" -eq 0 ]; then
    log_summary "Frontend Tool" "Qwik" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_QWIK_RT="✅ Detected"

  local _DUR_QWIK_RT
  _DUR_QWIK_RT=$(($(date +%s) - _T0_QWIK_RT))
  log_summary "Frontend Tool" "Qwik" "$_STAT_QWIK_RT" "-" "$_DUR_QWIK_RT"
}

# Purpose: Checks if Qwik is relevant.
check_runtime_qwik() {
  local _TOOL_DESC_QWIK="${1:-Qwik}"
  if [ -f "package.json" ] && grep -q '"@builder.io/qwik"' package.json; then
    return 0
  fi
  if has_lang_files "*.jsx *.tsx"; then
    return 0
  fi
  return 1
}
