#!/usr/bin/env sh
# HTMX Logic Module

# Purpose: Sets up HTMX environment for project.
setup_htmx() {
  local _T0_HTMX_RT
  _T0_HTMX_RT=$(date +%s)
  _log_setup "HTMX" "htmx"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "HTMX" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect HTMX: check for htmx.js, htmx.min.js, or htmx in scripts (src or package.json)
  if ! has_lang_files "htmx.js htmx.min.js"; then
    if [ -f "package.json" ] && grep -q '"htmx.org"' package.json; then
      :
    else
      log_summary "Frontend Tool" "HTMX" "⏭️ Skipped" "-" "0"
      return 0
    fi
  fi

  local _STAT_HTMX_RT="✅ Detected"

  local _DUR_HTMX_RT
  _DUR_HTMX_RT=$(($(date +%s) - _T0_HTMX_RT))
  log_summary "Frontend Tool" "HTMX" "$_STAT_HTMX_RT" "-" "$_DUR_HTMX_RT"
}

# Purpose: Checks if HTMX is relevant.
check_runtime_htmx() {
  local _TOOL_DESC_HTMX="${1:-HTMX}"
  if has_lang_files "htmx.js htmx.min.js"; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q '"htmx.org"' package.json; then
    return 0
  fi
  return 1
}
