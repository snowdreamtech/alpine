#!/usr/bin/env sh
# Assembly Logic Module

# Purpose: Sets up Assembly environment for project.
setup_assembly() {
  local _T0_ASM_RT
  _T0_ASM_RT=$(date +%s)
  _log_setup "Assembly" "assembly"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "System Tool" "Assembly" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Assembly files
  if ! has_lang_files "*.s *.asm"; then
    log_summary "System Tool" "Assembly" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Assembly is foundational. We focus on detection.
  local _STAT_ASM_RT="✅ Detected"

  local _DUR_ASM_RT
  _DUR_ASM_RT=$(($(date +%s) - _T0_ASM_RT))
  log_summary "System Tool" "Assembly" "$_STAT_ASM_RT" "-" "$_DUR_ASM_RT"
}

# Purpose: Checks if Assembly files are present.
check_runtime_assembly() {
  local _TOOL_DESC_ASM="${1:-Assembly}"
  if ! has_lang_files "*.s *.asm"; then
    return 1
  fi
  return 0
}
