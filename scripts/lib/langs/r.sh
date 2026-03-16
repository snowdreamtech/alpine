#!/usr/bin/env sh
# R Logic Module

# Purpose: Installs R runtime via mise.
install_runtime_r() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install R runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "R@${MISE_TOOL_VERSION_R}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up R runtime.
setup_r() {
  local _T0_R_RT
  _T0_R_RT=$(date +%s)
  _log_setup "R Runtime" "R"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "R" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "DESCRIPTION" "*.R *.Rmd"; then
    log_summary "Runtime" "R" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_R_RT="✅ Installed"
  install_runtime_r || _STAT_R_RT="❌ Failed"

  local _DUR_R_RT
  _DUR_R_RT=$(($(date +%s) - _T0_R_RT))
  log_summary "Runtime" "R" "$_STAT_R_RT" "$(get_version R --version | head -n 1)" "$_DUR_R_RT"
}
