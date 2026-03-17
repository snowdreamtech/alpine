#!/usr/bin/env sh
# WasmTime Logic Module

# Purpose: Sets up WasmTime environment for project.
setup_wasmtime() {
  local _T0_WASMTIME_RT
  _T0_WASMTIME_RT=$(date +%s)
  _log_setup "WasmTime" "wasmtime"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "System Tool" "WasmTime" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Wasm: check for *.wasm or *.wat files
  if ! has_lang_files "*.wasm *.wat"; then
    log_summary "System Tool" "WasmTime" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_WASMTIME_RT="✅ Detected"

  local _DUR_WASMTIME_RT
  _DUR_WASMTIME_RT=$(($(date +%s) - _T0_WASMTIME_RT))
  log_summary "System Tool" "WasmTime" "$_STAT_WASMTIME_RT" "-" "$_DUR_WASMTIME_RT"
}

# Purpose: Checks if WasmTime is relevant.
check_runtime_wasmtime() {
  local _TOOL_DESC_WASMTIME="${1:-WasmTime}"
  if has_lang_files "*.wasm *.wat"; then
    return 0
  fi
  return 1
}
