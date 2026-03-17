#!/usr/bin/env sh
# Cap'n Proto Logic Module

# Purpose: Sets up Cap'n Proto environment for project.
setup_capnproto() {
  local _T0_CAPNP_RT
  _T0_CAPNP_RT=$(date +%s)
  _log_setup "Cap'n Proto" "capnproto"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "Cap'n Proto" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Cap'n Proto: check for *.capnp files
  if ! has_lang_files "*.capnp"; then
    log_summary "Data Tool" "Cap'n Proto" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_CAPNP_RT="✅ Detected"

  local _DUR_CAPNP_RT
  _DUR_CAPNP_RT=$(($(date +%s) - _T0_CAPNP_RT))
  log_summary "Data Tool" "Cap'n Proto" "$_STAT_CAPNP_RT" "-" "$_DUR_CAPNP_RT"
}

# Purpose: Checks if Cap'n Proto is relevant.
check_runtime_capnproto() {
  local _TOOL_DESC_CAPNP="${1:-Capn Proto}"
  if has_lang_files "*.capnp"; then
    return 0
  fi
  return 1
}
