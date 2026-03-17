#!/usr/bin/env sh
# Typst Logic Module

# Purpose: Installs Typst via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_typst() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Typst via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "typst@${MISE_TOOL_VERSION_TYPST}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Typst environment for project.
setup_typst() {
  local _T0_TYPST_RT
  _T0_TYPST_RT=$(date +%s)
  _log_setup "Typst" "typst"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Doc Tool" "Typst" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Typst files
  if ! has_lang_files "" "*.typ"; then
    log_summary "Doc Tool" "Typst" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TYPST_RT="✅ Installed"
  install_runtime_typst || _STAT_TYPST_RT="❌ Failed"

  local _DUR_TYPST_RT
  _DUR_TYPST_RT=$(($(date +%s) - _T0_TYPST_RT))
  log_summary "Doc Tool" "Typst" "$_STAT_TYPST_RT" "$(get_version typst --version | awk '{print $2}')" "$_DUR_TYPST_RT"
}

# Purpose: Checks if Typst is available.
# Examples:
#   check_runtime_typst "Linter"
check_runtime_typst() {
  local _TOOL_DESC_TYPST="${1:-Typst}"
  if ! command -v typst >/dev/null 2>&1; then
    log_warn "Required tool 'typst' for $_TOOL_DESC_TYPST is missing. Skipping."
    return 1
  fi
  return 0
}
