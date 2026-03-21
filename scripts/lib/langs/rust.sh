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
}

# Purpose: Sets up Rust runtime for project.
# Delegate: Managed by mise (.mise.toml)
setup_rust() {
  if ! has_lang_files "Cargo.toml Cargo.lock" "*.rs"; then
    return 0
  fi

  # Dynamically register Rust in .mise.toml if not already present.
  setup_registry_rust

  local _T0_RUST_RT
  _T0_RUST_RT=$(date +%s)
  local _TITLE="Rust Runtime"
  local _PROVIDER="rust"

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version rust)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Runtime" "Rust" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

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
