#!/usr/bin/env sh
# Nix Logic Module

# Purpose: Nix is usually managed externally, this verifies it.
install_runtime_nix() {
  if command -v nix >/dev/null 2>&1; then
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would check for Nix availability."
    return 0
  fi

  log_warn "Nix not found. Please install Nix from https://nixos.org/"
  return 1
}

# Purpose: Sets up Nix environment for project.
setup_nix() {
  local _T0_NIX_RT
  _T0_NIX_RT=$(date +%s)
  _log_setup "Nix" "nix"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Nix" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Nix files
  if ! has_lang_files "flake.nix shell.nix default.nix" "*.nix"; then
    log_summary "Runtime" "Nix" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_NIX_RT="✅ Available"
  install_runtime_nix || _STAT_NIX_RT="⚠️ Missing"

  local _DUR_NIX_RT
  _DUR_NIX_RT=$(($(date +%s) - _T0_NIX_RT))

  local _NIX_VER="-"
  if command -v nix >/dev/null 2>&1; then
    _NIX_VER=$(nix --version | awk '{print $3}')
  fi

  log_summary "Runtime" "Nix" "$_STAT_NIX_RT" "$_NIX_VER" "$_DUR_NIX_RT"
}

# Purpose: Checks if Nix is available.
check_runtime_nix() {
  local _TOOL_DESC_NIX="${1:-Nix}"
  if ! command -v nix >/dev/null 2>&1; then
    log_warn "Required runtime 'nix' for $_TOOL_DESC_NIX is missing. Skipping."
    return 1
  fi
  return 0
}
