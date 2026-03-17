#!/usr/bin/env sh
# Apache Spark Logic Module

# Purpose: Installs Apache Spark via mise.
install_runtime_spark() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Apache Spark via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "spark@${MISE_TOOL_VERSION_SPARK}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Apache Spark environment for project.
setup_spark() {
  local _T0_SPARK_RT
  _T0_SPARK_RT=$(date +%s)
  _log_setup "Apache Spark" "spark-shell"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Apache Spark" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Spark/PySpark files
  if ! has_lang_files "spark-defaults.conf *.pyspark"; then
    log_summary "Runtime" "Apache Spark" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SPARK_RT="✅ Installed"
  install_runtime_spark || _STAT_SPARK_RT="❌ Failed"

  local _DUR_SPARK_RT
  _DUR_SPARK_RT=$(($(date +%s) - _T0_SPARK_RT))
  log_summary "Runtime" "Apache Spark" "$_STAT_SPARK_RT" "$(get_version spark-shell --version 2>&1 | grep "version" | head -1 | awk '{print $NF}')" "$_DUR_SPARK_RT"
}

# Purpose: Checks if Apache Spark is available.
check_runtime_spark() {
  local _TOOL_DESC_SPARK="${1:-Apache Spark}"
  if ! command -v spark-shell >/dev/null 2>&1; then
    log_warn "Required tool 'spark-shell' for $_TOOL_DESC_SPARK is missing. Skipping."
    return 1
  fi
  return 0
}
