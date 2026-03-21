#!/usr/bin/env sh
# Swift Logic Module

# Purpose: Installs Swift runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_swift() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Swift runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "swift@$(get_mise_tool_version swift)"
}

# Purpose: Sets up Swift runtime and mandatory linting tools.
# shellcheck disable=SC2329
setup_swift() {
  if ! has_lang_files "Package.swift" "*.swift"; then
    return 0
  fi

  setup_registry_swift

  local _T0_SWIFT_RT
  _T0_SWIFT_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version swift)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "swift")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Runtime" "Swift" "✅ Detected" "$_CUR_VER" "0"
  else
    _log_setup "Swift Runtime" "swift"

    if [ "${DRY_RUN:-0}" -eq 0 ]; then
      log_warn "Swift installation is large (~1GB+) and may take several minutes. Please wait..."
      install_runtime_swift || return 1
    fi
    log_summary "Runtime" "Swift" "✅ Installed" "$(get_version swift --version | head -n 1)" "$(($(date +%s) - _T0_SWIFT_RT))"
  fi

  # Also ensure linting tools are present
  install_swiftformat
  install_swiftlint
}

# Purpose: Installs swiftformat for Swift linting.
# Delegate: Managed by mise (.mise.toml)
install_swiftformat() {
  local _T0_SF
  _T0_SF=$(date +%s)
  local _TITLE="SwiftFormat"
  local _PROVIDER="github:nicklockwood/SwiftFormat"

  if ! has_lang_files "Package.swift" "*.swift"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version swiftformat)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Swift" "SwiftFormat" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SF="✅ mise"
  setup_registry_swiftformat
  run_mise install "$_PROVIDER" || _STAT_SF="❌ Failed"
  log_summary "Swift" "SwiftFormat" "$_STAT_SF" "$(get_version swiftformat)" "$(($(date +%s) - _T0_SF))"
}

# Purpose: Installs swiftlint for Swift linting.
# Delegate: Managed by mise (.mise.toml)
install_swiftlint() {
  local _T0_SL
  _T0_SL=$(date +%s)
  local _TITLE="SwiftLint"
  local _PROVIDER="github:realm/SwiftLint"

  if ! has_lang_files "Package.swift" "*.swift"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version swiftlint)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Swift" "SwiftLint" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SL="✅ mise"
  setup_registry_swiftlint
  run_mise install "$_PROVIDER" || _STAT_SL="❌ Failed"
  log_summary "Swift" "SwiftLint" "$_STAT_SL" "$(get_version swiftlint)" "$(($(date +%s) - _T0_SL))"
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
