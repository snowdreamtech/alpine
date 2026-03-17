#!/usr/bin/env sh
# Wasmer Logic Module

# Purpose: Sets up Wasmer environment for project.
setup_wasmer() {
  local _T0_WASMER_RT
  _T0_WASMER_RT=$(date +%s)
  _log_setup "Wasmer" "wasmer"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Wasm Runtime" "Wasmer" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Wasmer: check for wasmer.toml
  if ! has_lang_files "wasmer.toml"; then
    log_summary "Wasm Runtime" "Wasmer" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_WASMER_RT="✅ Detected"

  local _DUR_WASMER_RT
  _DUR_WASMER_RT=$(($(date +%s) - _T0_WASMER_RT))
  log_summary "Wasm Runtime" "Wasmer" "$_STAT_WASMER_RT" "-" "$_DUR_WASMER_RT"
}

# Purpose: Checks if Wasmer is relevant.
check_runtime_wasmer() {
  local _TOOL_DESC_WASMER="${1:-Wasmer}"
  if has_lang_files "wasmer.toml"; then
    return 0
  fi
  return 1
}
