#!/usr/bin/env sh
# Ballerina Logic Module

# Purpose: Installs Ballerina via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_ballerina() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Ballerina via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "ballerina@$(get_mise_tool_version ballerina)"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Ballerina environment for project.
setup_ballerina() {
  if ! has_lang_files "Ballerina.toml" "*.bal"; then
    return 0
  fi

  local _T0_BAL_RT
  _T0_BAL_RT=$(date +%s)
  _log_setup "Ballerina" "bal"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Ballerina" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_BAL_RT="✅ Installed"
  install_runtime_ballerina || _STAT_BAL_RT="❌ Failed"

  local _DUR_BAL_RT
  _DUR_BAL_RT=$(($(date +%s) - _T0_BAL_RT))
  log_summary "Runtime" "Ballerina" "$_STAT_BAL_RT" "$(get_version bal version | head -n 1 | awk '{print $NF}')" "$_DUR_BAL_RT"
}

# Purpose: Checks if Ballerina is available.
# Examples:
#   check_runtime_ballerina "Linter"
check_runtime_ballerina() {
  local _TOOL_DESC_BAL="${1:-Ballerina}"
  if ! command -v bal >/dev/null 2>&1; then
    log_warn "Required runtime 'bal' for $_TOOL_DESC_BAL is missing. Skipping."
    return 1
  fi
  return 0
}
