#!/usr/bin/env sh
# Prolog Logic Module

# Purpose: Installs SWI-Prolog via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_prolog() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install SWI-Prolog via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "swiprolog@${MISE_TOOL_VERSION_SWIPROLOG}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Prolog environment for project.
setup_prolog() {
  local _T0_PROLOG_RT
  _T0_PROLOG_RT=$(date +%s)
  _log_setup "Prolog" "swipl"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Prolog" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Prolog files
  if ! has_lang_files "" "*.pl *.pro *.prolog"; then
    log_summary "Runtime" "Prolog" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PROLOG_RT="✅ Installed"
  install_runtime_prolog || _STAT_PROLOG_RT="❌ Failed"

  local _DUR_PROLOG_RT
  _DUR_PROLOG_RT=$(($(date +%s) - _T0_PROLOG_RT))
  log_summary "Runtime" "Prolog" "$_STAT_PROLOG_RT" "$(get_version swipl --version | awk '{print $NF}')" "$_DUR_PROLOG_RT"
}

# Purpose: Checks if SWI-Prolog is available.
# Examples:
#   check_runtime_prolog "Linter"
check_runtime_prolog() {
  local _TOOL_DESC_PROLOG="${1:-Prolog}"
  if ! command -v swipl >/dev/null 2>&1; then
    log_warn "Required runtime 'swipl' for $_TOOL_DESC_PROLOG is missing. Skipping."
    return 1
  fi
  return 0
}
