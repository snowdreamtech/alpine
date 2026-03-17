#!/usr/bin/env sh
# Jsonnet Logic Module

# Purpose: Installs go-jsonnet via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_jsonnet() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install go-jsonnet via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "go-jsonnet@${MISE_TOOL_VERSION_JSONNET}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Jsonnet environment for project.
# Delegate: Managed by mise (.mise.toml)
# Examples:
#   setup_jsonnet
setup_jsonnet() {
  local _T0_JSONNET_RT
  _T0_JSONNET_RT=$(date +%s)
  _log_setup "Jsonnet" "jsonnet"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Jsonnet" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Jsonnet files
  if ! has_lang_files "" "*.jsonnet *.libsonnet"; then
    log_summary "Runtime" "Jsonnet" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_JSONNET_RT="✅ Installed"
  install_runtime_jsonnet || _STAT_JSONNET_RT="❌ Failed"

  local _DUR_JSONNET_RT
  _DUR_JSONNET_RT=$(($(date +%s) - _T0_JSONNET_RT))
  log_summary "Runtime" "Jsonnet" "$_STAT_JSONNET_RT" "$(get_version jsonnet --version | head -n 1 | awk '{print $NF}')" "$_DUR_JSONNET_RT"
}

# Purpose: Checks if Jsonnet is available.
# Examples:
#   check_runtime_jsonnet "Linter"
check_runtime_jsonnet() {
  local _TOOL_DESC_JSONNET="${1:-Jsonnet}"
  if ! command -v jsonnet >/dev/null 2>&1; then
    log_warn "Required runtime 'jsonnet' for $_TOOL_DESC_JSONNET is missing. Skipping."
    return 1
  fi
  return 0
}
