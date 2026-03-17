#!/usr/bin/env sh
# Alpine.js Logic Module

# Purpose: Sets up Alpine.js environment for project.
setup_alpine() {
  local _T0_ALPINE_RT
  _T0_ALPINE_RT=$(date +%s)
  _log_setup "Alpine.js" "alpine"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Frontend Tool" "Alpine.js" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Alpine.js: check for alpine.js, alpine.min.js, or alpine in package.json
  if ! has_lang_files "alpine.js alpine.min.js"; then
    if [ -f "package.json" ] && grep -q '"alpinejs"' package.json; then
      :
    else
      log_summary "Frontend Tool" "Alpine.js" "⏭️ Skipped" "-" "0"
      return 0
    fi
  fi

  local _STAT_ALPINE_RT="✅ Detected"

  local _DUR_ALPINE_RT
  _DUR_ALPINE_RT=$(($(date +%s) - _T0_ALPINE_RT))
  log_summary "Frontend Tool" "Alpine.js" "$_STAT_ALPINE_RT" "-" "$_DUR_ALPINE_RT"
}

# Purpose: Checks if Alpine.js is relevant.
check_runtime_alpine() {
  local _TOOL_DESC_ALPINE="${1:-Alpine.js}"
  if has_lang_files "alpine.js alpine.min.js"; then
    return 0
  fi
  if [ -f "package.json" ] && grep -q '"alpinejs"' package.json; then
    return 0
  fi
  return 1
}
