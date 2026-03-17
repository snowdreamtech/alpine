#!/usr/bin/env sh
# MATLAB Logic Module

# Purpose: Sets up MATLAB environment for project.
setup_matlab() {
  local _T0_MATLAB_RT
  _T0_MATLAB_RT=$(date +%s)
  _log_setup "MATLAB" "matlab"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Technical Tool" "MATLAB" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect MATLAB: check for *.m files.
  # Note: .m is also used by Octave and Objective-C, but we treat it as MATLAB here
  # if no specific Objective-C markers are found.
  if ! has_lang_files "*.m"; then
    log_summary "Technical Tool" "MATLAB" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_MATLAB_RT="✅ Detected"

  local _DUR_MATLAB_RT
  _DUR_MATLAB_RT=$(($(date +%s) - _T0_MATLAB_RT))
  log_summary "Technical Tool" "MATLAB" "$_STAT_MATLAB_RT" "-" "$_DUR_MATLAB_RT"
}

# Purpose: Checks if MATLAB is relevant.
check_runtime_matlab() {
  local _TOOL_DESC_MATLAB="${1:-MATLAB}"
  if has_lang_files "*.m"; then
    return 0
  fi
  return 1
}
