#!/usr/bin/env sh
# Mojo Logic Module

# Purpose: Installs Mojo runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_mojo() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Mojo runtime via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "mojo@$(get_mise_tool_version mojo)"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Mojo environment for project.
setup_mojo() {
  if ! has_lang_files "" "*.mojo *.fire"; then
    return 0
  fi

  local _T0_MOJ_RT
  _T0_MOJ_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version mojo)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "mojo")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Mojo" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "Mojo" "mojo"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Mojo" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_MOJ_RT="✅ Installed"
  install_runtime_mojo || _STAT_MOJ_RT="❌ Failed"

  local _DUR_MOJ_RT
  _DUR_MOJ_RT=$(($(date +%s) - _T0_MOJ_RT))
  log_summary "Runtime" "Mojo" "$_STAT_MOJ_RT" "$(get_version mojo --version | head -n 1)" "$_DUR_MOJ_RT"
}

# Purpose: Checks if Mojo is available.
# Examples:
#   check_runtime_mojo "Linter"
check_runtime_mojo() {
  local _TOOL_DESC_MOJ="${1:-Mojo}"
  if ! command -v mojo >/dev/null 2>&1; then
    log_warn "Required runtime 'mojo' for $_TOOL_DESC_MOJ is missing. Skipping."
    return 1
  fi
  return 0
}
