#!/usr/bin/env sh
# Haxe Logic Module

# Purpose: Installs Haxe via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_haxe() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Haxe via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "haxe@${MISE_TOOL_VERSION_HAXE}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Haxe environment for project.
# Delegate: Managed by mise (.mise.toml)
setup_haxe() {
  local _T0_HX_RT
  _T0_HX_RT=$(date +%s)
  _log_setup "Haxe" "haxe"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Haxe" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Haxe files
  if ! has_lang_files "project.xml build.hxml" "*.hx"; then
    log_summary "Runtime" "Haxe" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_HX_RT="✅ Installed"
  install_runtime_haxe || _STAT_HX_RT="❌ Failed"

  local _DUR_HX_RT
  _DUR_HX_RT=$(($(date +%s) - _T0_HX_RT))
  log_summary "Runtime" "Haxe" "$_STAT_HX_RT" "$(get_version haxe -version | head -n 1)" "$_DUR_HX_RT"
}

# Purpose: Checks if Haxe is available.
# Examples:
#   check_runtime_haxe "Linter"
check_runtime_haxe() {
  local _TOOL_DESC_HX="${1:-Haxe}"
  if ! command -v haxe >/dev/null 2>&1; then
    log_warn "Required runtime 'haxe' for $_TOOL_DESC_HX is missing. Skipping."
    return 1
  fi
  return 0
}
