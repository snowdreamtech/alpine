#!/usr/bin/env sh
# OpenTelemetry Logic Module

# Purpose: Sets up OpenTelemetry environment for project.
setup_otel() {
  local _T0_OTEL_RT
  _T0_OTEL_RT=$(date +%s)
  _log_setup "OpenTelemetry" "otel"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "SRE Tool" "OpenTelemetry" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect OpenTelemetry: check for otel configuration or dependencies
  if [ -f "otel-config.yaml" ] || [ -f "otel-collector-config.yaml" ] || grep -q "opentelemetry" ./* 2>/dev/null; then
    :
  else
    log_summary "SRE Tool" "OpenTelemetry" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_OTEL_RT="✅ Detected"

  local _DUR_OTEL_RT
  _DUR_OTEL_RT=$(($(date +%s) - _T0_OTEL_RT))
  log_summary "SRE Tool" "OpenTelemetry" "$_STAT_OTEL_RT" "-" "$_DUR_OTEL_RT"
}

# Purpose: Checks if OpenTelemetry is relevant.
check_runtime_otel() {
  local _TOOL_DESC_OTEL="${1:-OpenTelemetry}"
  if [ -f "otel-config.yaml" ] || [ -f "otel-collector-config.yaml" ]; then
    return 0
  fi
  return 1
}
