#!/usr/bin/env sh
# Airflow Logic Module

# Purpose: Sets up Airflow environment for project.
setup_airflow() {
  local _T0_AIRFLOW_RT
  _T0_AIRFLOW_RT=$(date +%s)
  _log_setup "Airflow" "airflow"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "Airflow" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Airflow: check for 'DAG' or 'airflow' in *.py, or dags/ folder
  if [ -d "dags" ] || grep -rq "from airflow" . --include="*.py" 2>/dev/null; then
    :
  else
    log_summary "Data Tool" "Airflow" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_AIRFLOW_RT="✅ Detected"

  local _DUR_AIRFLOW_RT
  _DUR_AIRFLOW_RT=$(($(date +%s) - _T0_AIRFLOW_RT))
  log_summary "Data Tool" "Airflow" "$_STAT_AIRFLOW_RT" "-" "$_DUR_AIRFLOW_RT"
}

# Purpose: Checks if Airflow is relevant.
check_runtime_airflow() {
  local _TOOL_DESC_AIRFLOW="${1:-Airflow}"
  if [ -d "dags" ] || grep -rq "from airflow" . --include="*.py" 2>/dev/null; then
    return 0
  fi
  return 1
}
