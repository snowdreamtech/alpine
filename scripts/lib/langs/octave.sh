#!/usr/bin/env sh
# Octave Logic Module

# Purpose: Sets up Octave environment for project.
setup_octave() {
  local _T0_OCT_RT
  _T0_OCT_RT=$(date +%s)
  _log_setup "Octave" "octave"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Engineering Tool" "Octave" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Octave files
  if ! has_lang_files "*.m"; then
    log_summary "Engineering Tool" "Octave" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Octave is typically installed via system package manager or mise.
  # We focus on detection and availability.
  local _STAT_OCT_RT="✅ Detected"

  local _DUR_OCT_RT
  _DUR_OCT_RT=$(($(date +%s) - _T0_OCT_RT))
  log_summary "Engineering Tool" "Octave" "$_STAT_OCT_RT" "-" "$_DUR_OCT_RT"
}

# Purpose: Checks if Octave is available.
check_runtime_octave() {
  local _TOOL_DESC_OCT="${1:-Octave}"
  if ! command -v octave >/dev/null 2>&1; then
    log_warn "Required tool 'octave' for $_TOOL_DESC_OCT is missing. Skipping."
    return 1
  fi
  return 0
}
