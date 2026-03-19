#!/usr/bin/env sh
# Grain Logic Module

# Purpose: Installs Grain via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_grain() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Grain via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "grain@${MISE_TOOL_VERSION_GRAIN}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Grain environment for project.
setup_grain() {
  if ! has_lang_files "" "*.gr"; then
    return 0
  fi

  local _T0_GRAIN_RT
  _T0_GRAIN_RT=$(date +%s)
  _log_setup "Grain" "grain"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Grain" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_GRAIN_RT="✅ Installed"
  install_runtime_grain || _STAT_GRAIN_RT="❌ Failed"

  local _DUR_GRAIN_RT
  _DUR_GRAIN_RT=$(($(date +%s) - _T0_GRAIN_RT))
  log_summary "Runtime" "Grain" "$_STAT_GRAIN_RT" "$(get_version grain --version | head -n 1 | awk '{print $NF}')" "$_DUR_GRAIN_RT"
}

# Purpose: Checks if Grain is available.
# Examples:
#   check_runtime_grain "Linter"
check_runtime_grain() {
  local _TOOL_DESC_GRAIN="${1:-Grain}"
  if ! command -v grain >/dev/null 2>&1; then
    log_warn "Required runtime 'grain' for $_TOOL_DESC_GRAIN is missing. Skipping."
    return 1
  fi
  return 0
}
