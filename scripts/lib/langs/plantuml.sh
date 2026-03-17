#!/usr/bin/env sh
# PlantUML Logic Module

# Purpose: Sets up PlantUML environment for project.
setup_plantuml() {
  local _T0_PLANTUML_RT
  _T0_PLANTUML_RT=$(date +%s)
  _log_setup "PlantUML" "plantuml"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Visualization Tool" "PlantUML" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect PlantUML: check for *.puml, *.plantuml, *.pu, *.iuml, *.tuml files
  if ! has_lang_files "*.puml *.plantuml *.pu *.iuml *.tuml"; then
    log_summary "Visualization Tool" "PlantUML" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PLANTUML_RT="✅ Detected"

  local _DUR_PLANTUML_RT
  _DUR_PLANTUML_RT=$(($(date +%s) - _T0_PLANTUML_RT))
  log_summary "Visualization Tool" "PlantUML" "$_STAT_PLANTUML_RT" "-" "$_DUR_PLANTUML_RT"
}

# Purpose: Checks if PlantUML is relevant.
check_runtime_plantuml() {
  local _TOOL_DESC_PLANTUML="${1:-PlantUML}"
  if has_lang_files "*.puml *.plantuml *.pu *.iuml *.tuml"; then
    return 0
  fi
  return 1
}
