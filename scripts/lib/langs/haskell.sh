#!/usr/bin/env sh
# Haskell Logic Module

# Purpose: Installs Haskell (GHC) runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_haskell() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Haskell runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "ghc@${MISE_TOOL_VERSION_GHC}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Haskell runtime.
setup_haskell() {
  if ! has_lang_files "package.yaml stack.yaml *.cabal" "*.hs"; then
    return 0
  fi

  local _T0_HASKELL_RT
  _T0_HASKELL_RT=$(date +%s)
  _log_setup "Haskell Runtime" "haskell"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Haskell" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_HASKELL_RT="✅ Installed"
  install_runtime_haskell || _STAT_HASKELL_RT="❌ Failed"

  local _DUR_HASKELL_RT
  _DUR_HASKELL_RT=$(($(date +%s) - _T0_HASKELL_RT))
  log_summary "Runtime" "Haskell" "$_STAT_HASKELL_RT" "$(get_version ghc --version)" "$_DUR_HASKELL_RT"
}
# Purpose: Checks if Haskell runtime is available.
# Examples:
#   check_runtime_haskell "Linter"
check_runtime_haskell() {
  local _TOOL_DESC_GHC="${1:-Haskell}"
  if ! command -v ghc >/dev/null 2>&1; then
    log_warn "Required runtime 'ghc' for $_TOOL_DESC_GHC is missing. Skipping."
    return 1
  fi
  return 0
}
