#!/usr/bin/env sh
# Solidity Logic Module

# Purpose: Installs Solidity compiler (solc) via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_solidity() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Solidity compiler (solc) via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "solidity@${MISE_TOOL_VERSION_SOLIDITY}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Solidity environment for project.
setup_solidity() {
  local _T0_SOL_RT
  _T0_SOL_RT=$(date +%s)
  _log_setup "Solidity" "solc"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Solidity" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Solidity files
  if ! has_lang_files "" "*.sol"; then
    log_summary "Runtime" "Solidity" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SOL_RT="✅ Installed"
  install_runtime_solidity || _STAT_SOL_RT="❌ Failed"

  local _DUR_SOL_RT
  _DUR_SOL_RT=$(($(date +%s) - _T0_SOL_RT))
  log_summary "Runtime" "Solidity" "$_STAT_SOL_RT" "$(get_version solc)" "$_DUR_SOL_RT"
}

# Purpose: Checks if Solidity compiler is available.
# Examples:
#   check_runtime_solidity "Linter"
check_runtime_solidity() {
  local _TOOL_DESC_SOL="${1:-Solidity}"
  if ! command -v solc >/dev/null 2>&1; then
    log_warn "Required runtime 'solc' for $_TOOL_DESC_SOL is missing. Skipping."
    return 1
  fi
  return 0
}
