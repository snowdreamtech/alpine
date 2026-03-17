#!/usr/bin/env sh
# Crystal Logic Module

# Purpose: Installs Crystal and Shards via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_crystal() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Crystal via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "crystal@${MISE_TOOL_VERSION_CRYSTAL}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Crystal environment for project.
setup_crystal() {
  local _T0_CRY_RT
  _T0_CRY_RT=$(date +%s)
  _log_setup "Crystal" "crystal"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Crystal" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Crystal files
  if ! has_lang_files "shard.yml" "*.cr"; then
    log_summary "Runtime" "Crystal" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_CRY_RT="✅ Installed"
  install_runtime_crystal || _STAT_CRY_RT="❌ Failed"

  local _DUR_CRY_RT
  _DUR_CRY_RT=$(($(date +%s) - _T0_CRY_RT))
  log_summary "Runtime" "Crystal" "$_STAT_CRY_RT" "$(get_version crystal --version | head -n 1 | awk '{print $2}')" "$_DUR_CRY_RT"
}

# Purpose: Checks if Crystal is available.
# Examples:
#   check_runtime_crystal "Linter"
check_runtime_crystal() {
  local _TOOL_DESC_CRY="${1:-Crystal}"
  if ! command -v crystal >/dev/null 2>&1; then
    log_warn "Required runtime 'crystal' for $_TOOL_DESC_CRY is missing. Skipping."
    return 1
  fi
  return 0
}
