#!/usr/bin/env sh
# SolidJS Logic Module

# Purpose: Sets up SolidJS environment for project.
setup_solid() {
  local _T0_SOLID_RT
  _T0_SOLID_RT=$(date +%s)
  _log_setup "SolidJS" "solid"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "SolidJS" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect SolidJS: check package.json or .jsx/.tsx files
  local _IS_SOLID=0
  if [ -f "package.json" ] && grep -q '"solid-js"' package.json; then
    _IS_SOLID=1
  elif has_lang_files "*.jsx *.tsx"; then
    # Fallback to general detection if no package.json
    _IS_SOLID=1
  fi

  if [ "${_IS_SOLID}" -eq 0 ]; then
    log_summary "Frontend Tool" "SolidJS" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SOLID_RT="✅ Detected"

  local _DUR_SOLID_RT
  _DUR_SOLID_RT=$(($(date +%s) - _T0_SOLID_RT))
  log_summary "Frontend Tool" "SolidJS" "$_STAT_SOLID_RT" "-" "$_DUR_SOLID_RT"
}

# Purpose: Checks if SolidJS is relevant.
check_runtime_solid() {
  local _TOOL_DESC_SOLID="${1:-SolidJS}"
  if [ -f "package.json" ] && grep -q '"solid-js"' package.json; then
    return 0
  fi
  if has_lang_files "*.jsx *.tsx"; then
    return 0
  fi
  return 1
}
