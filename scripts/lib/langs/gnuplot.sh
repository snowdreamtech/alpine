#!/usr/bin/env sh
# Gnuplot Logic Module

# Purpose: Sets up Gnuplot environment for project.
setup_gnuplot() {
  local _T0_GNUPLOT_RT
  _T0_GNUPLOT_RT=$(date +%s)
  _log_setup "Gnuplot" "gnuplot"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Visualization Tool" "Gnuplot" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Gnuplot: check for *.gp or *.gnuplot files
  if ! has_lang_files "*.gp *.gnuplot"; then
    log_summary "Visualization Tool" "Gnuplot" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_GNUPLOT_RT="✅ Detected"

  local _DUR_GNUPLOT_RT
  _DUR_GNUPLOT_RT=$(($(date +%s) - _T0_GNUPLOT_RT))
  log_summary "Visualization Tool" "Gnuplot" "$_STAT_GNUPLOT_RT" "-" "$_DUR_GNUPLOT_RT"
}

# Purpose: Checks if Gnuplot is relevant.
check_runtime_gnuplot() {
  local _TOOL_DESC_GNUPLOT="${1:-Gnuplot}"
  if has_lang_files "*.gp *.gnuplot"; then
    return 0
  fi
  return 1
}
