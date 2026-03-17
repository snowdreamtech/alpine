#!/usr/bin/env sh
# Lit Logic Module

# Purpose: Sets up Lit environment for project.
setup_lit() {
  local _T0_LIT_RT
  _T0_LIT_RT=$(date +%s)
  _log_setup "Lit" "lit"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Lit" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Lit: check for 'lit' in package.json or *.lit.js/ts
  local _HAS_LIT=0
  if [ -f "package.json" ] && grep -q '"lit"' package.json; then
    _HAS_LIT=1
  elif has_lang_files "*.lit.js *.lit.ts *.lit.jsx *.lit.tsx"; then
    _HAS_LIT=1
  fi

  if [ "${_HAS_LIT}" -eq 0 ]; then
    log_summary "Frontend Tool" "Lit" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_LIT_RT="✅ Detected"

  local _DUR_LIT_RT
  _DUR_LIT_RT=$(($(date +%s) - _T0_LIT_RT))
  log_summary "Frontend Tool" "Lit" "$_STAT_LIT_RT" "-" "$_DUR_LIT_RT"
}

# Purpose: Checks if Lit is relevant.
check_runtime_lit() {
  local _TOOL_DESC_LIT="${1:-Lit}"
  if [ -f "package.json" ] && grep -q '"lit"' package.json; then
    return 0
  fi
  if has_lang_files "*.lit.js *.lit.ts *.lit.jsx *.lit.tsx"; then
    return 0
  fi
  return 1
}
