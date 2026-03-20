#!/usr/bin/env sh
# Common Lisp Logic Module

# Purpose: Installs SBCL via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_lisp() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install SBCL via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "sbcl@$(get_mise_tool_version sbcl)"
}

# Purpose: Sets up Common Lisp environment for project.
setup_lisp() {
  if ! has_lang_files "" "*.lisp *.cl *.asd"; then
    return 0
  fi

  setup_registry_sbcl

  local _T0_LISP_RT
  _T0_LISP_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version sbcl)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "sbcl")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Common Lisp" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "Common Lisp" "sbcl"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Common Lisp" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_LISP_RT="✅ Installed"
  install_runtime_lisp || _STAT_LISP_RT="❌ Failed"

  local _DUR_LISP_RT
  _DUR_LISP_RT=$(($(date +%s) - _T0_LISP_RT))
  log_summary "Runtime" "Common Lisp" "$_STAT_LISP_RT" "$(get_version sbcl --version | awk '{print $NF}')" "$_DUR_LISP_RT"
}

# Purpose: Checks if SBCL is available.
# Examples:
#   check_runtime_lisp "Linter"
check_runtime_lisp() {
  local _TOOL_DESC_LISP="${1:-Common Lisp}"
  if ! command -v sbcl >/dev/null 2>&1; then
    log_warn "Required runtime 'sbcl' for $_TOOL_DESC_LISP is missing. Skipping."
    return 1
  fi
  return 0
}
