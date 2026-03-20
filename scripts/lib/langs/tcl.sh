#!/usr/bin/env sh
# Tcl Logic Module

# Purpose: Installs Tcl via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_tcl() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Tcl via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "tcl@$(get_mise_tool_version tcl)"
}

# Purpose: Sets up Tcl environment for project.
setup_tcl() {
  if ! has_lang_files "" "*.tcl *.tk"; then
    return 0
  fi

  local _T0_TCL_RT
  _T0_TCL_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version tclsh)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "tclsh")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Tcl" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "Tcl" "tclsh"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Tcl" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_TCL_RT="✅ Installed"
  install_runtime_tcl || _STAT_TCL_RT="❌ Failed"

  local _DUR_TCL_RT
  _DUR_TCL_RT=$(($(date +%s) - _T0_TCL_RT))
  log_summary "Runtime" "Tcl" "$_STAT_TCL_RT" "$(get_version tclsh "echo 'puts [info patchlevel]' | tclsh" | awk '{print $NF}')" "$_DUR_TCL_RT"
}

# Purpose: Checks if Tcl is available.
# Examples:
#   check_runtime_tcl "Linter"
check_runtime_tcl() {
  local _TOOL_DESC_TCL="${1:-Tcl}"
  if ! command -v tclsh >/dev/null 2>&1; then
    log_warn "Required runtime 'tclsh' for $_TOOL_DESC_TCL is missing. Skipping."
    return 1
  fi
  return 0
}
