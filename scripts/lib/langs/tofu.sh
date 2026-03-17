#!/usr/bin/env sh
# OpenTofu Logic Module

# Purpose: Installs OpenTofu via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_tofu() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install OpenTofu."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "opentofu@${MISE_TOOL_VERSION_OPENTOFU}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up OpenTofu IaC.
setup_tofu() {
  local _T0_TO_RT
  _T0_TO_RT=$(date +%s)
  _log_setup "OpenTofu CLI" "tofu"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "IaC" "OpenTofu" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.tf"; then
    log_summary "IaC" "OpenTofu" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TO_RT="✅ Installed"
  install_runtime_tofu || _STAT_TO_RT="❌ Failed"

  local _DUR_TO_RT
  _DUR_TO_RT=$(($(date +%s) - _T0_TO_RT))
  log_summary "IaC" "OpenTofu" "$_STAT_TO_RT" "$(get_version tofu version)" "$_DUR_TO_RT"
}
# Purpose: Checks if OpenTofu is available.
# Examples:
#   check_runtime_tofu "Linter"
check_runtime_tofu() {
  local _TOOL_DESC_TOFU="${1:-OpenTofu}"
  if ! command -v tofu >/dev/null 2>&1; then
    log_warn "Required runtime 'tofu' for $_TOOL_DESC_TOFU is missing. Skipping."
    return 1
  fi
  return 0
}
