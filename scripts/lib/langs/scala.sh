#!/usr/bin/env bash
# Scala Logic Module

# Purpose: Installs Scala runtime via mise.
install_runtime_scala() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Scala runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "scala@${MISE_TOOL_VERSION_SCALA}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Scala runtime.
setup_scala() {
  local _T0_SCALA_RT
  _T0_SCALA_RT=$(date +%s)
  _log_setup "Scala Runtime" "scala"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Scala" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "build.sbt" "*.scala *.sc"; then
    log_summary "Runtime" "Scala" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SCALA_RT="✅ Installed"
  install_runtime_scala || _STAT_SCALA_RT="❌ Failed"

  local _DUR_SCALA_RT
  _DUR_SCALA_RT=$(($(date +%s) - _T0_SCALA_RT))
  log_summary "Runtime" "Scala" "$_STAT_SCALA_RT" "$(get_version scala -version | head -n 1)" "$_DUR_SCALA_RT"
}
