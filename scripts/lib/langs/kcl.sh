#!/usr/bin/env sh
# KCL Logic Module

# Purpose: Installs KCL via mise.
install_runtime_kcl() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install KCL via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "kclvm@${MISE_TOOL_VERSION_KCL}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up KCL environment for project.
setup_kcl() {
  if ! has_lang_files "kcl.mod" "*.k"; then
    return 0
  fi

  local _T0_KCL_RT
  _T0_KCL_RT=$(date +%s)
  _log_setup "KCL" "kcl"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "KCL" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_KCL_RT="✅ Installed"
  install_runtime_kcl || _STAT_KCL_RT="❌ Failed"

  local _DUR_KCL_RT
  _DUR_KCL_RT=$(($(date +%s) - _T0_KCL_RT))
  log_summary "Runtime" "KCL" "$_STAT_KCL_RT" "$(get_version kcl --version | head -n 1 | awk '{print $3}')" "$_DUR_KCL_RT"
}

# Purpose: Checks if KCL is available.
check_runtime_kcl() {
  local _TOOL_DESC_KCL="${1:-KCL}"
  if ! command -v kcl >/dev/null 2>&1; then
    log_warn "Required runtime 'kcl' for $_TOOL_DESC_KCL is missing. Skipping."
    return 1
  fi
  return 0
}
