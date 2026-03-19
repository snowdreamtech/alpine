#!/usr/bin/env sh
# Rust Logic Module

# Purpose: Installs Rust runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_rust() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Rust runtime."
    return 0
  fi

  # Runtime initialization
  run_mise install rust
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Rust runtime.
# Delegate: Managed by mise (.mise.toml)
setup_rust() {
  if ! has_lang_files "Cargo.toml" "*.rs"; then
    return 0
  fi

  local _T0_RUST_RT
  _T0_RUST_RT=$(date +%s)
  _log_setup "Rust Runtime" "rust"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Rust" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_RUST_RT="✅ Installed"
  install_runtime_rust || _STAT_RUST_RT="❌ Failed"

  local _DUR_RUST_RT
  _DUR_RUST_RT=$(($(date +%s) - _T0_RUST_RT))
  log_summary "Runtime" "Rust" "$_STAT_RUST_RT" "$(get_version rustc)" "$_DUR_RUST_RT"
}
# Purpose: Checks if Rust runtime is available.
# Examples:
#   check_runtime_rust "Linter"
check_runtime_rust() {
  local _TOOL_DESC_RUST="${1:-Rust}"
  if ! command -v cargo >/dev/null 2>&1; then
    log_warn "Required runtime 'rust' for $_TOOL_DESC_RUST is missing. Skipping."
    return 1
  fi
  return 0
}
