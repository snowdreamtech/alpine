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
  run_mise install "racket@${MISE_TOOL_VERSION_RACKET}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Racket environment for project.
setup_racket() {
  if ! has_lang_files "" "*.rkt *.rktl"; then
    return 0
  fi

  local _T0_RACKET_RT
  _T0_RACKET_RT=$(date +%s)
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
