#!/usr/bin/env sh
# AssemblyScript Logic Module

# Purpose: Installs AssemblyScript (asc) via mise (npm provider).
# Delegate: Managed by mise (.mise.toml)
install_runtime_assemblyscript() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install AssemblyScript (asc) via mise npm provider."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "npm:assemblyscript@${MISE_TOOL_VERSION_ASSEMBLYSCRIPT}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up AssemblyScript environment for project.
setup_assemblyscript() {
  if ! has_lang_files "asconfig.json" "*.as"; then
    return 0
  fi

  local _T0_AS_RT
  _T0_AS_RT=$(date +%s)
  _log_setup "AssemblyScript" "asc"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "AssemblyScript" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_AS_RT="✅ Installed"
  install_runtime_assemblyscript || _STAT_AS_RT="❌ Failed"

  local _DUR_AS_RT
  _DUR_AS_RT=$(($(date +%s) - _T0_AS_RT))
  log_summary "Runtime" "AssemblyScript" "$_STAT_AS_RT" "$(get_version asc --version)" "$_DUR_AS_RT"
}

# Purpose: Checks if AssemblyScript is available.
# Examples:
#   check_runtime_assemblyscript "Linter"
check_runtime_assemblyscript() {
  local _TOOL_DESC_AS="${1:-AssemblyScript}"
  if ! command -v asc >/dev/null 2>&1; then
    log_warn "Required runtime 'asc' for $_TOOL_DESC_AS is missing. Skipping."
    return 1
  fi
  return 0
}
