#!/usr/bin/env sh
# Java Logic Module

# Purpose: Installs Java runtime via mise (version pinned in scripts/lib/versions.sh).
install_runtime_java() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Java runtime."
    return 0
  fi
  run_mise install "java@${VER_JAVA}"
}

# Purpose: Installs google-java-format for Java project linting (version in versions.sh).
# WARNING: google-java-format has no prebuilt binary for linux/arm64.
#          On ARM64 Linux, this step may fail. Use: java -jar google-java-format.jar
install_java_lint() {
  local _T0_JAVA
  _T0_JAVA=$(date +%s)
  local _TITLE="Java Lint"
  local _PROVIDER="${VER_JAVA_FORMAT_PROVIDER}"
  local _REQ_VER="${VER_JAVA_FORMAT}"

  # Fallback for linux/arm64 which lacks native google-java-format binaries
  if [ "$_G_OS" = "linux" ] && { [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; }; then
    local _BIN_PATH="$HOME/.local/bin/google-java-format"
    local _JAR_PATH="$HOME/.local/share/java/google-java-format-${_REQ_VER}-all-deps.jar"

    if [ -x "$_BIN_PATH" ] && [ -f "$_JAR_PATH" ]; then
      log_summary "Java" "Java Lint" "✅ Exists (Jar)" "$_REQ_VER" "0"
      return 0
    fi

    _log_setup "$_TITLE" "jar-fallback"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_summary "Java" "Java Lint" "⚖️ Previewed" "-" "0"
      return 0
    fi

    mkdir -p "$(dirname "$_BIN_PATH")" "$(dirname "$_JAR_PATH")"
    local _URL="https://github.com/google/google-java-format/releases/download/v${_REQ_VER}/google-java-format-${_REQ_VER}-all-deps.jar"
    [ "${ENABLE_GITHUB_PROXY}" = "1" ] || [ "${ENABLE_GITHUB_PROXY}" = "true" ] && _URL="${GITHUB_PROXY}${_URL}"

    local _STAT_JAVA="✅ Installed (Jar wrapper)"
    if command -v curl >/dev/null 2>&1; then
      run_quiet curl --retry 5 --retry-delay 2 --retry-connrefused -fSL --connect-timeout 15 -o "$_JAR_PATH" "$_URL" || _STAT_JAVA="❌ Failed"
    else
      run_quiet wget --tries=5 --waitretry=2 -q --timeout=15 -O "$_JAR_PATH" "$_URL" || _STAT_JAVA="❌ Failed"
    fi

    if [ "$_STAT_JAVA" != "❌ Failed" ]; then
      printf '#!/usr/bin/env sh\nexec java -jar "%s" "$@"\n' "$_JAR_PATH" >"$_BIN_PATH"
      chmod +x "$_BIN_PATH"
      log_summary "Java" "Java Lint" "$_STAT_JAVA" "$_REQ_VER" "$(($(date +%s) - _T0_JAVA))"
    else
      log_summary "Java" "Java Lint" "❌ Failed" "-" "$(($(date +%s) - _T0_JAVA))"
    fi
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version google-java-format)

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

  # Dynamically register Java in .mise.toml if not already present.
  setup_registry_java

  local _T0_JAVA_RT
  _T0_JAVA_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version java)
  local _REQ_VER="${VER_JAVA}"

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
