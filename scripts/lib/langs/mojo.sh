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
  run_mise install "mojo@${MISE_TOOL_VERSION_MOJO}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Mojo environment for project.
setup_mojo() {
  local _T0_MOJ_RT
  _T0_MOJ_RT=$(date +%s)
  _log_setup "Mojo" "mojo"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Mojo" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Mojo files
  if ! has_lang_files "" "*.mojo *.fire"; then
    log_summary "Runtime" "Mojo" "⏭️ Skipped" "-" "0"
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
