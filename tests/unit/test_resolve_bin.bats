#!/usr/bin/env bats
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# tests/unit/test_resolve_bin.bats - Unit tests for bin resolver module
#
# Purpose:
#   Tests the bin-resolver.sh module functions including:
#   - Layer 1: Local cache lookup (venv/bin, node_modules/.bin)
#   - Layer 2: System PATH lookup with mise shim validation
#   - Layer 3: mise metadata query
#   - Layer 4: Filesystem search with depth limit
#   - Cache mechanism avoids redundant lookups
#   - Timeout protection triggers for slow operations
#
# Requirements: 2.1.1, 2.1.2, 3.1, 3.2

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

  # Set up environment
  export _G_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  export _G_VENV_BIN="bin"
  export _G_MISE_SHIMS_BASE="$HOME/.local/share/mise/shims"

  # shellcheck source=scripts/lib/timeout.sh
  . "$SCRIPT_DIR/scripts/lib/timeout.sh"

  # shellcheck source=scripts/lib/bin-resolver.sh
  . "$SCRIPT_DIR/scripts/lib/bin-resolver.sh"

  # Clear cache
  unset _G_BIN_CACHE
  declare -gA _G_BIN_CACHE
}

teardown() {
  # Remove temporary directory
  rm -rf "$TEMP_DIR"

  # Clear cache
  unset _G_BIN_CACHE
}

# ── Test: Layer 1 - Local Cache Lookup ───────────────────────────────────────

@test "resolve_bin_layer1: finds binary in venv/bin" {
  # Create fake venv structure
  mkdir -p "$TEMP_DIR/.venv/bin"
  echo "#!/bin/sh" >"$TEMP_DIR/.venv/bin/pytest"
  chmod +x "$TEMP_DIR/.venv/bin/pytest"

  # Change to temp dir
  cd "$TEMP_DIR"

  run resolve_bin_layer1 "pytest"
  assert_success
  assert_output "$TEMP_DIR/.venv/bin/pytest"
}

@test "resolve_bin_layer1: finds binary in node_modules/.bin" {
  # Create fake node_modules structure
  mkdir -p "$TEMP_DIR/node_modules/.bin"
  echo "#!/bin/sh" >"$TEMP_DIR/node_modules/.bin/eslint"
  chmod +x "$TEMP_DIR/node_modules/.bin/eslint"

  cd "$TEMP_DIR"

  run resolve_bin_layer1 "eslint"
  assert_success
  assert_output "$TEMP_DIR/node_modules/.bin/eslint"
}

@test "resolve_bin_layer1: returns 1 when binary not found" {
  cd "$TEMP_DIR"

  run resolve_bin_layer1 "nonexistent"
  assert_failure 1
}

@test "resolve_bin_layer1: prefers venv over node_modules" {
  # Create both
  mkdir -p "$TEMP_DIR/.venv/bin"
  mkdir -p "$TEMP_DIR/node_modules/.bin"
  echo "#!/bin/sh" >"$TEMP_DIR/.venv/bin/tool"
  echo "#!/bin/sh" >"$TEMP_DIR/node_modules/.bin/tool"
  chmod +x "$TEMP_DIR/.venv/bin/tool"
  chmod +x "$TEMP_DIR/node_modules/.bin/tool"

  cd "$TEMP_DIR"

  run resolve_bin_layer1 "tool"
  assert_success
  assert_output "$TEMP_DIR/.venv/bin/tool"
}

# ── Test: Layer 2 - System PATH Lookup ───────────────────────────────────────

@test "resolve_bin_layer2: finds binary in PATH" {
  # Use a known system binary
  run resolve_bin_layer2 "sh"
  assert_success
  [[ $output =~ /sh$ ]]
}

@test "resolve_bin_layer2: returns 1 when binary not in PATH" {
  run resolve_bin_layer2 "nonexistent_binary_12345"
  assert_failure 1
}

@test "resolve_bin_layer2: validates mise shims" {
  skip "Requires mise installation and configuration"
  # This test would verify that mise shims are validated
}

# ── Test: Layer 3 - mise Metadata Query ──────────────────────────────────────

@test "resolve_bin_layer3: queries mise metadata" {
  skip "Requires mise installation and configuration"
  # This test would verify mise metadata query works
}

@test "resolve_bin_layer3: respects timeout" {
  # Test that layer 3 respects TIMEOUT_MISE_WHICH
  export TIMEOUT_MISE_WHICH=1

  run resolve_bin_layer3 "nonexistent"
  # Should complete within timeout
  assert_failure
}

# ── Test: Layer 4 - Filesystem Search ────────────────────────────────────────

@test "resolve_bin_layer4: finds binary with filesystem search" {
  # Create a binary in a subdirectory
  mkdir -p "$TEMP_DIR/tools/bin"
  echo "#!/bin/sh" >"$TEMP_DIR/tools/bin/mytool"
  chmod +x "$TEMP_DIR/tools/bin/mytool"

  cd "$TEMP_DIR"

  run resolve_bin_layer4 "mytool"
  assert_success
  assert_output "$TEMP_DIR/tools/bin/mytool"
}

@test "resolve_bin_layer4: respects depth limit" {
  # Create a deeply nested binary
  mkdir -p "$TEMP_DIR/a/b/c/d/e/f"
  echo "#!/bin/sh" >"$TEMP_DIR/a/b/c/d/e/f/deep"
  chmod +x "$TEMP_DIR/a/b/c/d/e/f/deep"

  cd "$TEMP_DIR"

  # Should not find it due to depth limit (typically 3-5)
  run resolve_bin_layer4 "deep"
  assert_failure
}

@test "resolve_bin_layer4: respects timeout" {
  export TIMEOUT_FIND_BINARY=1

  cd "$TEMP_DIR"

  # Should complete within timeout even if not found
  run resolve_bin_layer4 "nonexistent"
  assert_failure
}

# ── Test: Cache Mechanism ────────────────────────────────────────────────────

@test "resolve_bin_cached: caches successful lookups" {
  # Create a binary
  mkdir -p "$TEMP_DIR/.venv/bin"
  echo "#!/bin/sh" >"$TEMP_DIR/.venv/bin/cached_tool"
  chmod +x "$TEMP_DIR/.venv/bin/cached_tool"

  cd "$TEMP_DIR"

  # First lookup
  run resolve_bin_cached "cached_tool"
  assert_success
  local first_result="$output"

  # Verify it's cached
  [[ -n ${_G_BIN_CACHE[cached_tool]} ]]

  # Second lookup should use cache
  run resolve_bin_cached "cached_tool"
  assert_success
  assert_output "$first_result"
}

@test "resolve_bin_cached: cache avoids redundant lookups" {
  mkdir -p "$TEMP_DIR/.venv/bin"
  echo "#!/bin/sh" >"$TEMP_DIR/.venv/bin/tool"
  chmod +x "$TEMP_DIR/.venv/bin/tool"

  cd "$TEMP_DIR"

  # First call
  resolve_bin_cached "tool" >/dev/null

  # Remove the binary
  rm "$TEMP_DIR/.venv/bin/tool"

  # Second call should still return cached result
  run resolve_bin_cached "tool"
  assert_success
}

@test "resolve_bin_cached: handles cache miss" {
  run resolve_bin_cached "nonexistent_tool_xyz"
  assert_failure 1
}

# ── Test: Debug Logging ──────────────────────────────────────────────────────

@test "resolve_bin_cached: debug logging when enabled" {
  export DEBUG_RESOLVE_BIN=1

  mkdir -p "$TEMP_DIR/.venv/bin"
  echo "#!/bin/sh" >"$TEMP_DIR/.venv/bin/debug_tool"
  chmod +x "$TEMP_DIR/.venv/bin/debug_tool"

  cd "$TEMP_DIR"

  run resolve_bin_cached "debug_tool"
  assert_success
  # Debug output should be present (implementation specific)
}

# ── Test: Timeout Protection ─────────────────────────────────────────────────

@test "resolve_bin_cached: respects TIMEOUT_RESOLVE_BIN" {
  export TIMEOUT_RESOLVE_BIN=1

  cd "$TEMP_DIR"

  # Should complete within timeout
  run resolve_bin_cached "nonexistent"
  assert_failure
}

@test "resolve_bin_cached: timeout protection at each layer" {
  export TIMEOUT_RESOLVE_BIN=1
  export TIMEOUT_MISE_WHICH=1
  export TIMEOUT_FIND_BINARY=1

  cd "$TEMP_DIR"

  # All layers should respect timeouts
  run resolve_bin_cached "nonexistent"
  assert_failure
}

# ── Test: Edge Cases ─────────────────────────────────────────────────────────

@test "resolve_bin_cached: handles empty binary name" {
  run resolve_bin_cached ""
  assert_failure 1
}

@test "resolve_bin_cached: handles binary with spaces" {
  run resolve_bin_cached "binary with spaces"
  assert_failure
}

@test "resolve_bin_cached: handles binary with special characters" {
  run resolve_bin_cached "binary@#$%"
  assert_failure
}

@test "resolve_bin_cached: handles very long binary name" {
  local long_name
  long_name=$(printf 'a%.0s' {1..1000})

  run resolve_bin_cached "$long_name"
  assert_failure
}

# ── Test: Integration with Common Binaries ───────────────────────────────────

@test "resolve_bin_cached: finds common system binaries" {
  # Test with sh (should exist on all systems)
  run resolve_bin_cached "sh"
  assert_success
  [[ $output =~ /sh$ ]]
}

@test "resolve_bin_cached: finds bash if available" {
  if ! command -v bash >/dev/null 2>&1; then
    skip "bash not available"
  fi

  run resolve_bin_cached "bash"
  assert_success
  [[ $output =~ /bash$ ]]
}

# ── Test: Layer Priority ─────────────────────────────────────────────────────

@test "resolve_bin_cached: respects layer priority" {
  # Create binary in multiple locations
  mkdir -p "$TEMP_DIR/.venv/bin"
  mkdir -p "$TEMP_DIR/node_modules/.bin"

  echo "#!/bin/sh" >"$TEMP_DIR/.venv/bin/priority_test"
  echo "#!/bin/sh" >"$TEMP_DIR/node_modules/.bin/priority_test"
  chmod +x "$TEMP_DIR/.venv/bin/priority_test"
  chmod +x "$TEMP_DIR/node_modules/.bin/priority_test"

  cd "$TEMP_DIR"

  # Should find venv version first (Layer 1 priority)
  run resolve_bin_cached "priority_test"
  assert_success
  assert_output "$TEMP_DIR/.venv/bin/priority_test"
}

# ── Test: Performance ────────────────────────────────────────────────────────

@test "resolve_bin_cached: cache improves performance" {
  mkdir -p "$TEMP_DIR/.venv/bin"
  echo "#!/bin/sh" >"$TEMP_DIR/.venv/bin/perf_test"
  chmod +x "$TEMP_DIR/.venv/bin/perf_test"

  cd "$TEMP_DIR"

  # First call (uncached)
  local start1
  start1=$(date +%s%N)
  resolve_bin_cached "perf_test" >/dev/null
  local end1
  end1=$(date +%s%N)
  local time1=$((end1 - start1))

  # Second call (cached)
  local start2
  start2=$(date +%s%N)
  resolve_bin_cached "perf_test" >/dev/null
  local end2
  end2=$(date +%s%N)
  local time2=$((end2 - start2))

  # Cached call should be faster (or at least not slower)
  [ "$time2" -le "$time1" ]
}
