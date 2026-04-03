#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License.

# scripts/lib/json-parser.sh - JSON parsing wrapper with fallback chain
#
# Purpose:
#   Provides robust JSON parsing by trying multiple parsers in order:
#   Node.js > Python > jq > awk (fallback)
#
# Features:
#   - Automatic parser selection
#   - Timeout protection
#   - Graceful degradation
#   - Performance optimization

# Timeout for JSON parsing operations (seconds)
TIMEOUT_JSON_PARSE="${TIMEOUT_JSON_PARSE:-3}"

# Purpose: Parses JSON and extracts value using query path.
# Params:
#   $1 - JSON string
#   $2 - Query path (dot notation, e.g., "tools.node.version")
# Returns:
#   Extracted value, or empty string if not found
# Examples:
#   VAL=$(parse_json "$JSON" "tools.node.version")
#   VAL=$(parse_json "$JSON" "version")
parse_json() {
  local _JSON="${1:-}"
  local _QUERY="${2:-}"

  [ -z "${_JSON:-}" ] && return 1

  # Source timeout module if not already loaded
  if ! command -v run_with_timeout_robust >/dev/null 2>&1; then
    # shellcheck source=./timeout.sh
    . "${_G_LIB_DIR:-}/timeout.sh"
  fi

  local _RESULT=""

  # Strategy 1: Node.js (fastest and most reliable)
  if command -v node >/dev/null 2>&1; then
    _RESULT=$(echo "${_JSON:-}" | run_with_timeout_robust "${TIMEOUT_JSON_PARSE:-}" \
      node "${_G_LIB_DIR:-}/json-parser.cjs" "${_QUERY:-}" 2>/dev/null) || true
    if [ -n "${_RESULT:-}" ]; then
      echo "${_RESULT:-}"
      return 0
    fi
  fi

  # Strategy 2: Python (widely available)
  if command -v python3 >/dev/null 2>&1; then
    _RESULT=$(echo "${_JSON:-}" | run_with_timeout_robust "${TIMEOUT_JSON_PARSE:-}" \
      python3 "${_G_LIB_DIR:-}/json-parser.py" "${_QUERY:-}" 2>/dev/null) || true
    if [ -n "${_RESULT:-}" ]; then
      echo "${_RESULT:-}"
      return 0
    fi
  fi

  # Strategy 3: jq (if available)
  if command -v jq >/dev/null 2>&1; then
    local _JQ_QUERY
    # Convert dot notation to jq syntax
    _JQ_QUERY=$(echo "${_QUERY:-}" | sed 's/\./\./g')
    _RESULT=$(echo "${_JSON:-}" | run_with_timeout_robust "${TIMEOUT_JSON_PARSE:-}" \
      jq -r ".${_JQ_QUERY:-}" 2>/dev/null) || true
    if [ -n "${_RESULT:-}" ] && [ "${_RESULT:-}" != "null" ]; then
      echo "${_RESULT:-}"
      return 0
    fi
  fi

  # Strategy 4: awk fallback (basic support only)
  # Only supports simple queries like "version" or "tools.node.version"
  _RESULT=$(_parse_json_awk "${_JSON:-}" "${_QUERY:-}") || true
  if [ -n "${_RESULT:-}" ]; then
    echo "${_RESULT:-}"
    return 0
  fi

  return 1
}

# Purpose: Basic awk-based JSON parser (fallback only).
# Params:
#   $1 - JSON string
#   $2 - Query path
# Returns:
#   Extracted value or empty
_parse_json_awk() {
  local _JSON_AWK="${1:-}"
  local _QUERY_AWK="${2:-}"

  # Simple key extraction (no nested support)
  echo "${_JSON_AWK:-}" | awk -F'"' -v key="${_QUERY_AWK:-}" '
    $0 ~ "\"" key "\"" {
      for (i=1; i<=NF; i++) {
        if ($i ~ key) {
          print $(i+2);
          exit;
        }
      }
    }
  ' 2>/dev/null || true
}

# Safe log_debug call - only if function exists
if command -v log_debug >/dev/null 2>&1; then
  log_debug "json-parser.sh loaded"
fi
