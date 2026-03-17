#!/usr/bin/env sh
# Nim Logic Module

# Purpose: Installs Nim compiler via mise.
install_runtime_nim() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Nim compiler via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "nim@${MISE_TOOL_VERSION_NIM}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Nim environment for project.
setup_nim() {
  local _T0_NIM_RT
  _T0_NIM_RT=$(date +%s)
  _log_setup "Nim" "nim"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Nim" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Nim files
  if ! has_lang_files "nim.cfg nimble.ini" "*.nim *.nims *.nimble"; then
    log_summary "Runtime" "Nim" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_NIM_RT="✅ Installed"
  install_runtime_nim || _STAT_NIM_RT="❌ Failed"

  local _DUR_NIM_RT
  _DUR_NIM_RT=$(($(date +%s) - _T0_NIM_RT))
  log_summary "Runtime" "Nim" "$_STAT_NIM_RT" "$(get_version nim --version | head -n 1)" "$_DUR_NIM_RT"
}

# Purpose: Checks if Nim compiler is available.
check_runtime_nim() {
  local _TOOL_DESC_NIM="${1:-Nim}"
  if ! command -v nim >/dev/null 2>&1; then
    log_warn "Required runtime 'nim' for $_TOOL_DESC_NIM is missing. Skipping."
    return 1
  fi
  return 0
}
