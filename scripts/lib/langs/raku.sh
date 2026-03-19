#!/usr/bin/env sh
# Raku Logic Module

# Purpose: Installs Raku (via rakudo) via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_raku() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Raku (rakudo) via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "rakudo@${MISE_TOOL_VERSION_RAKU}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Raku environment for project.
setup_raku() {
  if ! has_lang_files "META6.json" "*.raku *.rakumod *.p6 *.pm6"; then
    return 0
  fi

  local _T0_RAKU_RT
  _T0_RAKU_RT=$(date +%s)
  _log_setup "Raku" "raku"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Raku" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_RAKU_RT="✅ Installed"
  install_runtime_raku || _STAT_RAKU_RT="❌ Failed"

  local _DUR_RAKU_RT
  _DUR_RAKU_RT=$(($(date +%s) - _T0_RAKU_RT))
  log_summary "Runtime" "Raku" "$_STAT_RAKU_RT" "$(get_version raku --version | head -n 1 | awk '{print $2}')" "$_DUR_RAKU_RT"
}

# Purpose: Checks if Raku is available.
# Examples:
#   check_runtime_raku "Linter"
check_runtime_raku() {
  local _TOOL_DESC_RAKU="${1:-Raku}"
  if ! command -v raku >/dev/null 2>&1; then
    log_warn "Required runtime 'raku' for $_TOOL_DESC_RAKU is missing. Skipping."
    return 1
  fi
  return 0
}
