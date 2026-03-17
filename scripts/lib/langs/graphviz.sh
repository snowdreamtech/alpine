#!/usr/bin/env sh
# Graphviz Logic Module

# Purpose: Sets up Graphviz environment for project.
setup_graphviz() {
  local _T0_GRAPHVIZ_RT
  _T0_GRAPHVIZ_RT=$(date +%s)
  _log_setup "Graphviz" "graphviz"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Visualization Tool" "Graphviz" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Graphviz: check for *.dot or *.gv files
  if ! has_lang_files "*.dot *.gv"; then
    log_summary "Visualization Tool" "Graphviz" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_GRAPHVIZ_RT="✅ Detected"

  local _DUR_GRAPHVIZ_RT
  _DUR_GRAPHVIZ_RT=$(($(date +%s) - _T0_GRAPHVIZ_RT))
  log_summary "Visualization Tool" "Graphviz" "$_STAT_GRAPHVIZ_RT" "-" "$_DUR_GRAPHVIZ_RT"
}

# Purpose: Checks if Graphviz is relevant.
check_runtime_graphviz() {
  local _TOOL_DESC_GRAPHVIZ="${1:-Graphviz}"
  if has_lang_files "*.dot *.gv"; then
    return 0
  fi
  return 1
}
