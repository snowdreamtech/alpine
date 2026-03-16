#!/usr/bin/env bash
# Groovy Logic Module

# Purpose: Installs Groovy runtime via mise.
install_runtime_groovy() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Groovy runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "groovy@${MISE_TOOL_VERSION_GROOVY}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Groovy runtime.
setup_groovy() {
  local _T0_GROOVY_RT
  _T0_GROOVY_RT=$(date +%s)
  _log_setup "Groovy Runtime" "groovy"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Groovy" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.groovy *.gradle"; then
    log_summary "Runtime" "Groovy" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_GROOVY_RT="✅ Installed"
  install_runtime_groovy || _STAT_GROOVY_RT="❌ Failed"

  local _DUR_GROOVY_RT
  _DUR_GROOVY_RT=$(($(date +%s) - _T0_GROOVY_RT))
  log_summary "Runtime" "Groovy" "$_STAT_GROOVY_RT" "$(get_version groovy -v | grep 'Groovy Version' | head -n 1)" "$_DUR_GROOVY_RT"
}
