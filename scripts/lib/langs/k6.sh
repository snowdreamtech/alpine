#!/usr/bin/env sh
# K6 Logic Module

# Purpose: Sets up K6 environment for project.
setup_k6() {
  local _T0_K6_RT
  _T0_K6_RT=$(date +%s)
  _log_setup "K6" "k6"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "SRE Tool" "K6" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect K6: check for k6 tests (often named *.k6.js or in a k6/ folder)
  if ! has_lang_files "*.k6.js k6/*.js"; then
    if [ -f "package.json" ] && grep -q '"k6"' package.json; then
      :
    else
      log_summary "SRE Tool" "K6" "⏭️ Skipped" "-" "0"
      return 0
    fi
  fi

  local _STAT_K6_RT="✅ Detected"

  local _DUR_K6_RT
  _DUR_K6_RT=$(($(date +%s) - _T0_K6_RT))
  log_summary "SRE Tool" "K6" "$_STAT_K6_RT" "-" "$_DUR_K6_RT"
}

# Purpose: Checks if K6 is relevant.
check_runtime_k6() {
  local _TOOL_DESC_K6="${1:-K6}"
  if has_lang_files "*.k6.js k6/*.js"; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q '"k6"' package.json; then
    return 0
  fi
  return 1
}
