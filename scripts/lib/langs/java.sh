#!/usr/bin/env sh
# Java Logic Module

# Purpose: Installs Java runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_java() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Java runtime."
    return 0
  fi

  # Runtime initialization
  run_mise install java
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Java runtime and mandatory linting tools.
# Delegate: Managed by mise (.mise.toml)
setup_java() {
  local _T0_JAVA_RT
  _T0_JAVA_RT=$(date +%s)
  _log_setup "Java Runtime" "java"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Java" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "pom.xml build.gradle" "*.java"; then
    log_summary "Runtime" "Java" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_JAVA_RT="✅ Installed"
  install_runtime_java || _STAT_JAVA_RT="❌ Failed"

  local _DUR_JAVA_RT
  _DUR_JAVA_RT=$(($(date +%s) - _T0_JAVA_RT))
  log_summary "Runtime" "Java" "$_STAT_JAVA_RT" "$(get_version java)" "$_DUR_JAVA_RT"

  # Also ensure linting tools are present
  install_java_lint
}
# Purpose: Checks if Java runtime is available.
# Examples:
#   check_runtime_java "Linter"
check_runtime_java() {
  local _TOOL_DESC_JAVA="${1:-Java}"
  if ! command -v java >/dev/null 2>&1; then
    log_warn "Required runtime 'java' for $_TOOL_DESC_JAVA is missing. Skipping."
    return 1
  fi
  return 0
}
