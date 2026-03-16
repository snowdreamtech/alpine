#!/usr/bin/env sh
# Swift Logic Module

# Purpose: Installs Swift runtime via mise.
install_runtime_swift() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Swift runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "swift@${MISE_TOOL_VERSION_SWIFT}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Swift runtime and mandatory linting tools.
# shellcheck disable=SC2329
setup_swift() {
  local _T0_SWIFT_RT
  _T0_SWIFT_RT=$(date +%s)
  _log_setup "Swift Runtime" "swift"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Swift" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Package.swift" "*.swift"; then
    log_summary "Runtime" "Swift" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SWIFT_RT="✅ Installed"
  install_runtime_swift || _STAT_SWIFT_RT="❌ Failed"

  local _DUR_SWIFT_RT
  _DUR_SWIFT_RT=$(($(date +%s) - _T0_SWIFT_RT))
  log_summary "Runtime" "Swift" "$_STAT_SWIFT_RT" "$(get_version swift --version | head -n 1)" "$_DUR_SWIFT_RT"

  # Also ensure linting tools are present
  install_swift_lint
}
# Purpose: Checks if Swift runtime is available.
# Examples:
#   check_runtime_swift "Linter"
check_runtime_swift() {
  local _TOOL_DESC_SWIFT="${1:-Swift}"
  if ! command -v swift >/dev/null 2>&1; then
    log_warn "Required runtime 'swift' for $_TOOL_DESC_SWIFT is missing. Skipping."
    return 1
  fi
  return 0
}
