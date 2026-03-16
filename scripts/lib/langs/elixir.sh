#!/usr/bin/env bash
# Elixir Logic Module

# Purpose: Installs Elixir/Erlang runtime via mise.
install_runtime_elixir() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Elixir/Erlang runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "erlang@${MISE_TOOL_VERSION_ERLANG}"
  # shellcheck disable=SC2154
  run_mise install "elixir@${MISE_TOOL_VERSION_ELIXIR}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Elixir runtime and mandatory linting tools.
setup_elixir() {
  local _T0_ELIXIR_RT
  _T0_ELIXIR_RT=$(date +%s)
  _log_setup "Elixir Runtime" "elixir"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Elixir" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "mix.exs" "*.ex *.exs"; then
    log_summary "Runtime" "Elixir" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_ELIXIR_RT="✅ Installed"
  install_runtime_elixir || _STAT_ELIXIR_RT="❌ Failed"

  local _DUR_ELIXIR_RT
  _DUR_ELIXIR_RT=$(($(date +%s) - _T0_ELIXIR_RT))
  log_summary "Runtime" "Elixir" "$_STAT_ELIXIR_RT" "$(get_version elixir --version | grep 'Elixir' | head -n 1)" "$_DUR_ELIXIR_RT"
}
