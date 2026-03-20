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
  run_mise install "rakudo@$(get_mise_tool_version raku)"
}

# Purpose: Sets up Raku environment for project.
setup_raku() {
  if ! has_lang_files "META6.json" "*.raku *.rakumod *.rakutest *.pm6 *.pl6"; then
    return 0
  fi

  setup_registry_raku

  local _T0_RAKU_RT
  _T0_RAKU_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version raku)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "raku")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Raku" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

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
