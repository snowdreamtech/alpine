#!/usr/bin/env sh
# Luau Logic Module

# Purpose: Installs Luau via mise.
install_runtime_luau() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Luau via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "luau@${MISE_TOOL_VERSION_LUAU}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Luau environment for project.
setup_luau() {
  local _T0_LUAU_RT
  _T0_LUAU_RT=$(date +%s)
  _log_setup "Luau" "luau"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Luau" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Luau files
  if ! has_lang_files "*.luau"; then
    log_summary "Runtime" "Luau" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_LUAU_RT="✅ Installed"
  install_runtime_luau || _STAT_LUAU_RT="❌ Failed"

  local _DUR_LUAU_RT
  _DUR_LUAU_RT=$(($(date +%s) - _T0_LUAU_RT))
  log_summary "Runtime" "Luau" "$_STAT_LUAU_RT" "$(get_version luau --version)" "$_DUR_LUAU_RT"
}

# Purpose: Checks if Luau is available.
check_runtime_luau() {
  local _TOOL_DESC_LUAU="${1:-Luau}"
  if ! command -v luau >/dev/null 2>&1; then
    log_warn "Required runtime 'luau' for $_TOOL_DESC_LUAU is missing. Skipping."
    return 1
  fi
  return 0
}
