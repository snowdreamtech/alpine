#!/usr/bin/env sh
# Deno Logic Module

# Purpose: Installs Deno runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_deno() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Deno runtime."
    return 0
  fi
  run_mise install deno
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Deno runtime.
setup_deno() {
  local _T0_DENO_RT
  _T0_DENO_RT=$(date +%s)
  _log_setup "Deno Runtime" "deno"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Deno" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "deno.json deno.jsonc" ""; then
    log_summary "Runtime" "Deno" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_DENO_RT="✅ Installed"
  install_runtime_deno || _STAT_DENO_RT="❌ Failed"

  local _DUR_DENO_RT
  _DUR_DENO_RT=$(($(date +%s) - _T0_DENO_RT))
  log_summary "Runtime" "Deno" "$_STAT_DENO_RT" "$(get_version deno --version | head -n 1 | awk '{print $2}')" "$_DUR_DENO_RT"
}
# Purpose: Checks if Deno runtime is available.
# Examples:
#   check_runtime_deno "Linter"
check_runtime_deno() {
  local _TOOL_DESC_DENO="${1:-Deno}"
  if ! command -v deno >/dev/null 2>&1; then
    log_warn "Required runtime 'deno' for $_TOOL_DESC_DENO is missing. Skipping."
    return 1
  fi
  return 0
}
