#!/usr/bin/env sh
# MLflow Logic Module

# Purpose: Sets up MLflow environment for project.
setup_mlflow() {
  local _T0_MLFLOW_RT
  _T0_MLFLOW_RT=$(date +%s)
  _log_setup "MLflow" "mlflow"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "AI Tool" "MLflow" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect MLflow: check for 'import mlflow' or 'mlruns' directory
  if [ -d "mlruns" ] || grep -rq "import mlflow" . --include="*.py" 2>/dev/null; then
    :
  else
    log_summary "AI Tool" "MLflow" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_MLFLOW_RT="✅ Detected"

  local _DUR_MLFLOW_RT
  _DUR_MLFLOW_RT=$(($(date +%s) - _T0_MLFLOW_RT))
  log_summary "AI Tool" "MLflow" "$_STAT_MLFLOW_RT" "-" "$_DUR_MLFLOW_RT"
}

# Purpose: Checks if MLflow is relevant.
check_runtime_mlflow() {
  local _TOOL_DESC_MLFLOW="${1:-MLflow}"
  if [ -d "mlruns" ] || grep -rq "import mlflow" . --include="*.py" 2>/dev/null; then
    return 0
  fi
  return 1
}
