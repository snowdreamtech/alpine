#!/usr/bin/env sh
# Haskell Logic Module

# Purpose: Installs Haskell (GHC) runtime via mise.
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
  local _T0_HASKELL_RT
  _T0_HASKELL_RT=$(date +%s)
  _log_setup "Haskell Runtime" "haskell"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Haskell" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "package.yaml stack.yaml *.cabal" "*.hs"; then
    log_summary "Runtime" "Haskell" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_HASKELL_RT="✅ Installed"
  install_runtime_haskell || _STAT_HASKELL_RT="❌ Failed"

  local _DUR_HASKELL_RT
  _DUR_HASKELL_RT=$(($(date +%s) - _T0_HASKELL_RT))
  log_summary "Runtime" "Haskell" "$_STAT_HASKELL_RT" "$(get_version ghc --version)" "$_DUR_HASKELL_RT"
}
