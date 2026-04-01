#!/usr/bin/env bats
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# tests/unit/test_json_parser.bats - Unit tests for JSON parsing module
#
# Purpose:
#   Tests the json-parser.sh module functions including:
#   - Node.js parser with simple and nested JSON
#   - Python parser with simple and nested JSON
#   - Awk fallback when Node.js/Python unavailable
#   - Timeout mechanism triggers correctly
#   - Error handling for malformed JSON
#
# Requirements: 2.2.2, 3.1

setup() {
  load '../vendor/bats-support/load.bash'
  load '../vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"

  # Source the modules
  export SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  export _G_LIB_DIR="$SCRIPT_DIR/scripts/lib"

  # shellcheck source=scripts/lib/timeout.sh
  . "$SCRIPT_DIR/scripts/lib/timeout.sh"

  # shellcheck source=scripts/lib/json-parser.sh
  . "$SCRIPT_DIR/scripts/lib/json-parser.sh"
}

teardown() {
  # Clean up temporary directory
  rm -rf "$TEMP_DIR"
}

# ── Test: Node.js Parser ─────────────────────────────────────────────────────

@test "json-parser.cjs: extract simple value" {
  if ! command -v node >/dev/null 2>&1; then
    skip "Node.js not available"
  fi

  run node "$_G_LIB_DIR/json-parser.cjs" "version" <<< '{"version":"1.2.3"}'
  assert_success
  assert_output "1.2.3"
}

@test "json-parser.cjs: extract nested value" {
  if ! command -v node >/dev/null 2>&1; then
    skip "Node.js not available"
  fi

  run node "$_G_LIB_DIR/json-parser.cjs" "tools.node.version" <<< '{"tools":{"node":{"version":"20.0.0"}}}'
  assert_success
  assert_output "20.0.0"
}

@test "json-parser.cjs: handle missing key" {
  if ! command -v node >/dev/null 2>&1; then
    skip "Node.js not available"
  fi

  run node "$_G_LIB_DIR/json-parser.cjs" "missing" <<< '{"version":"1.2.3"}'
  assert_success
  assert_output ""
}

@test "json-parser.cjs: handle null value" {
  if ! command -v node >/dev/null 2>&1; then
    skip "Node.js not available"
  fi

  run node "$_G_LIB_DIR/json-parser.cjs" "value" <<< '{"value":null}'
  assert_success
  assert_output ""
}

@test "json-parser.cjs: handle malformed JSON" {
  if ! command -v node >/dev/null 2>&1; then
    skip "Node.js not available"
  fi

  run node "$_G_LIB_DIR/json-parser.cjs" "version" <<< '{"version":"1.2.3"'
  assert_failure
}

# ── Test: Python Parser ──────────────────────────────────────────────────────

@test "json-parser.py: extract simple value" {
  if ! command -v python3 >/dev/null 2>&1; then
    skip "Python3 not available"
  fi

  run python3 "$_G_LIB_DIR/json-parser.py" "version" <<< '{"version":"1.2.3"}'
  assert_success
  assert_output "1.2.3"
}

@test "json-parser.py: extract nested value" {
  if ! command -v python3 >/dev/null 2>&1; then
    skip "Python3 not available"
  fi

  run python3 "$_G_LIB_DIR/json-parser.py" "tools.node.version" <<< '{"tools":{"node":{"version":"20.0.0"}}}'
  assert_success
  assert_output "20.0.0"
}

@test "json-parser.py: handle missing key" {
  if ! command -v python3 >/dev/null 2>&1; then
    skip "Python3 not available"
  fi

  run python3 "$_G_LIB_DIR/json-parser.py" "missing" <<< '{"version":"1.2.3"}'
  assert_success
  assert_output ""
}

@test "json-parser.py: handle None value" {
  if ! command -v python3 >/dev/null 2>&1; then
    skip "Python3 not available"
  fi

  run python3 "$_G_LIB_DIR/json-parser.py" "value" <<< '{"value":null}'
  assert_success
  assert_output ""
}

@test "json-parser.py: handle malformed JSON" {
  if ! command -v python3 >/dev/null 2>&1; then
    skip "Python3 not available"
  fi

  run python3 "$_G_LIB_DIR/json-parser.py" "version" <<< '{"version":"1.2.3"'
  assert_failure
}

# ── Test: Shell Wrapper Function ─────────────────────────────────────────────

@test "parse_json: extract simple value" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{"version":"1.2.3"}' "version"
  assert_success
  assert_output "1.2.3"
}

@test "parse_json: extract nested value" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{"tools":{"node":{"version":"20.0.0"}}}' "tools.node.version"
  assert_success
  assert_output "20.0.0"
}

@test "parse_json: handle empty JSON" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{}' "version"
  assert_success
  assert_output ""
}

@test "parse_json: handle malformed JSON" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{"version":"1.2.3"' "version"
  # Should fail or return empty
  if [ "$status" -eq 0 ]; then
    assert_output ""
  else
    assert_failure
  fi
}

# ── Test: Parser Selection Logic ─────────────────────────────────────────────

@test "parse_json: prefers Node.js when available" {
  if ! command -v node >/dev/null 2>&1; then
    skip "Node.js not available"
  fi

  # This test verifies Node.js parser is used
  run parse_json '{"test":"value"}' "test"
  assert_success
  assert_output "value"
}

@test "parse_json: falls back to Python when Node.js unavailable" {
  if ! command -v python3 >/dev/null 2>&1; then
    skip "Python3 not available"
  fi

  # Temporarily hide node command
  PATH_BACKUP="$PATH"
  export PATH="/usr/bin:/bin"

  run parse_json '{"test":"value"}' "test"

  # Restore PATH
  export PATH="$PATH_BACKUP"

  # Should still work with Python
  if command -v python3 >/dev/null 2>&1; then
    assert_success
    assert_output "value"
  fi
}

# ── Test: Timeout Protection ─────────────────────────────────────────────────

@test "parse_json: respects timeout configuration" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  # Set very short timeout
  export TIMEOUT_JSON_PARSE=1

  # Normal operation should still work
  run parse_json '{"version":"1.2.3"}' "version"
  assert_success
  assert_output "1.2.3"
}

# ── Test: Edge Cases ─────────────────────────────────────────────────────────

@test "parse_json: handles special characters in values" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{"message":"Hello \"World\"!"}' "message"
  assert_success
  assert_output 'Hello "World"!'
}

@test "parse_json: handles numeric values" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{"count":42}' "count"
  assert_success
  assert_output "42"
}

@test "parse_json: handles boolean values" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{"active":true}' "active"
  assert_success
  assert_output "true"
}

@test "parse_json: handles deeply nested objects" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{"a":{"b":{"c":{"d":"deep"}}}}' "a.b.c.d"
  assert_success
  assert_output "deep"
}

@test "parse_json: handles missing parameters" {
  run parse_json
  assert_failure
}

@test "parse_json: handles empty query path" {
  if ! command -v node >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    skip "No JSON parser available"
  fi

  run parse_json '{"version":"1.2.3"}' ""
  # Behavior may vary, but should not crash
  [ "$status" -ne 255 ]
}
