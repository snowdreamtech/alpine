#!/usr/bin/env sh
# Elixir Logic Module

# Purpose: Installs Elixir/Erlang runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_elixir() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Elixir/Erlang runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "erlang@$(get_mise_tool_version erlang)"
  # shellcheck disable=SC2154
  run_mise install "elixir@$(get_mise_tool_version elixir)"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Elixir runtime and mandatory linting tools.
setup_elixir() {
  if ! has_lang_files "mix.exs" "*.ex *.exs"; then
    return 0
  fi

  local _T0_ELIXIR_RT
  _T0_ELIXIR_RT=$(date +%s)
  _log_setup "Elixir Runtime" "elixir"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Elixir" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_ELIXIR_RT="✅ Installed"
  install_runtime_elixir || _STAT_ELIXIR_RT="❌ Failed"

  local _DUR_ELIXIR_RT
  _DUR_ELIXIR_RT=$(($(date +%s) - _T0_ELIXIR_RT))
  log_summary "Runtime" "Elixir" "$_STAT_ELIXIR_RT" "$(get_version elixir --version | grep 'Elixir' | head -n 1)" "$_DUR_ELIXIR_RT"
}
# Purpose: Checks if Elixir runtime is available.
# Examples:
#   check_runtime_elixir "Linter"
check_runtime_elixir() {
  local _TOOL_DESC_ELIXIR="${1:-Elixir}"
  if ! command -v elixir >/dev/null 2>&1; then
    log_warn "Required runtime 'elixir' for $_TOOL_DESC_ELIXIR is missing. Skipping."
    return 1
  fi
  return 0
}
