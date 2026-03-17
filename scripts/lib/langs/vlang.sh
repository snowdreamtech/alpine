#!/usr/bin/env sh
# Vlang Logic Module

# Purpose: Installs V compiler via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_vlang() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Vlang via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "vlang@${MISE_TOOL_VERSION_VLANG}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Vlang environment for project.
setup_vlang() {
  local _T0_VLG_RT
  _T0_VLG_RT=$(date +%s)
  _log_setup "Vlang" "v"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Vlang" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Vlang files
  if ! has_lang_files "v.mod" "*.v *.vsh"; then
    log_summary "Runtime" "Vlang" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_VLG_RT="✅ Installed"
  install_runtime_vlang || _STAT_VLG_RT="❌ Failed"

  local _DUR_VLG_RT
  _DUR_VLG_RT=$(($(date +%s) - _T0_VLG_RT))
  log_summary "Runtime" "Vlang" "$_STAT_VLG_RT" "$(get_version v version | head -n 1)" "$_DUR_VLG_RT"
}

# Purpose: Checks if V compiler is available.
# Examples:
#   check_runtime_vlang "Linter"
check_runtime_vlang() {
  local _TOOL_DESC_VLG="${1:-Vlang}"
  if ! command -v v >/dev/null 2>&1; then
    log_warn "Required runtime 'v' for $_TOOL_DESC_VLG is missing. Skipping."
    return 1
  fi
  return 0
}
