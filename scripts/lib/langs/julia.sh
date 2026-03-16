#!/usr/bin/env sh
# Julia Logic Module

# Purpose: Installs Julia runtime via mise.
install_runtime_julia() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Julia runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "julia@${MISE_TOOL_VERSION_JULIA}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Julia runtime.
setup_julia() {
  local _T0_JULIA_RT
  _T0_JULIA_RT=$(date +%s)
  _log_setup "Julia Runtime" "julia"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Julia" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Project.toml" "*.jl"; then
    log_summary "Runtime" "Julia" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_JULIA_RT="✅ Installed"
  install_runtime_julia || _STAT_JULIA_RT="❌ Failed"

  local _DUR_JULIA_RT
  _DUR_JULIA_RT=$(($(date +%s) - _T0_JULIA_RT))
  log_summary "Runtime" "Julia" "$_STAT_JULIA_RT" "$(get_version julia -v)" "$_DUR_JULIA_RT"
}
