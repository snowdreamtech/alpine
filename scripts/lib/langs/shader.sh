#!/usr/bin/env sh
# Shader Logic Module

# Purpose: Sets up Shader environment for project.
setup_shader() {
  local _T0_SHD_RT
  _T0_SHD_RT=$(date +%s)
  _log_setup "Shader" "shader"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Graphics Tool" "Shader" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Shader files
  if ! has_lang_files "*.hlsl *.glsl *.vert *.frag *.comp"; then
    log_summary "Graphics Tool" "Shader" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Shaders are typically compiled by dxc or glslangValidator.
  # We focus on detection and availability of common tools.
  local _STAT_SHD_RT="✅ Detected"

  local _DUR_SHD_RT
  _DUR_SHD_RT=$(($(date +%s) - _T0_SHD_RT))
  log_summary "Graphics Tool" "Shader" "$_STAT_SHD_RT" "-" "$_DUR_SHD_RT"
}

# Purpose: Checks if Shader files are present.
check_runtime_shader() {
  local _TOOL_DESC_SHD="${1:-Shader}"
  if ! has_lang_files "*.hlsl *.glsl *.vert *.frag *.comp"; then
    return 1
  fi
  return 0
}
