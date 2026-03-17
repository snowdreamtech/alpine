#!/usr/bin/env sh
# Gleam Logic Module

# Purpose: Installs Gleam runtime via mise.
install_runtime_gleam() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Gleam runtime via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "gleam@${MISE_TOOL_VERSION_GLEAM}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Gleam environment for project.
setup_gleam() {
  local _T0_GLM_RT
  _T0_GLM_RT=$(date +%s)
  _log_setup "Gleam" "gleam"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Gleam" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Gleam files
  if ! has_lang_files "gleam.toml" "*.gleam"; then
    log_summary "Runtime" "Gleam" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_GLM_RT="✅ Installed"
  install_runtime_gleam || _STAT_GLM_RT="❌ Failed"

  local _DUR_GLM_RT
  _DUR_GLM_RT=$(($(date +%s) - _T0_GLM_RT))
  log_summary "Runtime" "Gleam" "$_STAT_GLM_RT" "$(get_version gleam --version | head -n 1)" "$_DUR_GLM_RT"
}

# Purpose: Checks if Gleam is available.
check_runtime_gleam() {
  local _TOOL_DESC_GLM="${1:-Gleam}"
  if ! command -v gleam >/dev/null 2>&1; then
    log_warn "Required runtime 'gleam' for $_TOOL_DESC_GLM is missing. Skipping."
    return 1
  fi
  return 0
}
