#!/usr/bin/env sh
# Tauri Logic Module

# Purpose: Sets up Tauri environment for project.
setup_tauri() {
  local _T0_TAURI_RT
  _T0_TAURI_RT=$(date +%s)
  _log_setup "Tauri" "tauri"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Desktop Tool" "Tauri" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Tauri: check for src-tauri/tauri.conf.json or tauri.conf.json
  if ! has_lang_files "tauri.conf.json src-tauri/tauri.conf.json"; then
    log_summary "Desktop Tool" "Tauri" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TAURI_RT="✅ Detected"

  local _DUR_TAURI_RT
  _DUR_TAURI_RT=$(($(date +%s) - _T0_TAURI_RT))
  log_summary "Desktop Tool" "Tauri" "$_STAT_TAURI_RT" "-" "$_DUR_TAURI_RT"
}

# Purpose: Checks if Tauri is relevant.
check_runtime_tauri() {
  local _TOOL_DESC_TAURI="${1:-Tauri}"
  if has_lang_files "tauri.conf.json src-tauri/tauri.conf.json"; then
    return 0
  fi
  return 1
}
