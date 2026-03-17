#!/usr/bin/env sh
# Erlang Logic Module

# Purpose: Installs Erlang runtime via mise.
install_runtime_erlang() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Erlang via mise."
    return 0
  fi

  run_mise install erlang
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Erlang environment for project.
setup_erlang() {
  local _T0_ERL_RT
  _T0_ERL_RT=$(date +%s)
  _log_setup "Erlang" "erlang"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Erlang" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Erlang files
  if ! has_lang_files "rebar.config erlang.mk" "*.erl *.hrl"; then
    log_summary "Runtime" "Erlang" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_ERL_RT="✅ Installed"
  install_runtime_erlang || _STAT_ERL_RT="❌ Failed"

  local _DUR_ERL_RT
  _DUR_ERL_RT=$(($(date +%s) - _T0_ERL_RT))
  log_summary "Runtime" "Erlang" "$_STAT_ERL_RT" "$(get_version erl -version | head -n 1 | awk '{print $NF}')" "$_DUR_ERL_RT"
}

# Purpose: Checks if Erlang is available.
check_runtime_erlang() {
  local _TOOL_DESC_ERL="${1:-Erlang}"
  if ! command -v erl >/dev/null 2>&1; then
    log_warn "Required runtime 'erl' for $_TOOL_DESC_ERL is missing. Skipping."
    return 1
  fi
  return 0
}
