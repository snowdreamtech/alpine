#!/usr/bin/env sh
# GDScript Logic Module

# Purpose: Sets up GDScript environment for project.
setup_gdscript() {
  local _T0_GD_RT
  _T0_GD_RT=$(date +%s)
  _log_setup "GDScript" "gdscript"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Game Tool" "GDScript" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect GDScript files
  if ! has_lang_files "*.gd"; then
    log_summary "Game Tool" "GDScript" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # GDScript is native to Godot.
  # We focus on detection and presence of Godot if applicable.
  local _STAT_GD_RT="✅ Detected"

  local _DUR_GD_RT
  _DUR_GD_RT=$(($(date +%s) - _T0_GD_RT))
  log_summary "Game Tool" "GDScript" "$_STAT_GD_RT" "-" "$_DUR_GD_RT"
}

# Purpose: Checks if GDScript files are present.
check_runtime_gdscript() {
  local _TOOL_DESC_GD="${1:-GDScript}"
  if ! has_lang_files "*.gd"; then
    return 1
  fi
  return 0
}
