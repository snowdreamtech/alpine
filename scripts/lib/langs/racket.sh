#!/usr/bin/env sh
# Racket Logic Module

# Purpose: Installs Racket via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_racket() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Racket via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "racket@$(get_mise_tool_version racket)"
}

# Purpose: Sets up Racket environment for project.
setup_racket() {
  if ! has_lang_files "info.rkt" "*.rkt"; then
    return 0
  fi

  setup_registry_racket

  local _T0_RACKET_RT
  _T0_RACKET_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version racket)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "racket")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Racket" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "Racket" "racket"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Racket" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_RACKET_RT="✅ Installed"
  install_runtime_racket || _STAT_RACKET_RT="❌ Failed"

  local _DUR_RACKET_RT
  _DUR_RACKET_RT=$(($(date +%s) - _T0_RACKET_RT))
  log_summary "Runtime" "Racket" "$_STAT_RACKET_RT" "$(get_version racket --version | head -n 1 | awk '{print $NF}')" "$_DUR_RACKET_RT"
}

# Purpose: Checks if Racket is available.
# Examples:
#   check_runtime_racket "Linter"
check_runtime_racket() {
  local _TOOL_DESC_RACKET="${1:-Racket}"
  if ! command -v racket >/dev/null 2>&1; then
    log_warn "Required runtime 'racket' for $_TOOL_DESC_RACKET is missing. Skipping."
    return 1
  fi
  return 0
}
