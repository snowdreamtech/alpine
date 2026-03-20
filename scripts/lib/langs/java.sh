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
}

# Purpose: Installs google-java-format for Java project linting.
# Delegate: Managed by mise (.mise.toml)
# WARNING: google-java-format has no prebuilt binary for linux/arm64.
#          On ARM64 Linux, this step may fail. Use: java -jar google-java-format.jar
install_java_lint() {
  local _T0_JAVA
  _T0_JAVA=$(date +%s)
  local _TITLE="Java Lint"
  local _PROVIDER="github:google/google-java-format"

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version google-java-format)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Java" "Java Lint" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Java" "Java Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi
  local _STAT_JAVA="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_JAVA="❌ Failed"
  log_summary "Java" "Java Lint" "$_STAT_JAVA" "$(get_version google-java-format)" "$(($(date +%s) - _T0_JAVA))"
}

# Purpose: Sets up Java runtime and mandatory linting tools.
# Delegate: Managed by mise (.mise.toml)
setup_java() {
  if ! has_lang_files "pom.xml build.gradle" "*.java"; then
    return 0
  fi

  local _T0_JAVA_RT
  _T0_JAVA_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version java)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "java")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Runtime" "Java" "✅ Detected" "$_CUR_VER" "0"
  else
    _log_setup "Java Runtime" "java"

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_summary "Runtime" "Java" "⚖️ Previewed" "-" "0"
    else
      local _STAT_JAVA_RT="✅ Installed"
      install_runtime_java || _STAT_JAVA_RT="❌ Failed"

      local _DUR_JAVA_RT
      _DUR_JAVA_RT=$(($(date +%s) - _T0_JAVA_RT))
      log_summary "Runtime" "Java" "$_STAT_JAVA_RT" "$(get_version java)" "$_DUR_JAVA_RT"
    fi
  fi

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
