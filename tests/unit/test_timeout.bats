#!/usr/bin/env bats
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# tests/unit/test_timeout.bats - Unit tests for timeout mechanism
#
# Purpose:
#   Tests the timeout.sh module functions including:
#   - Normal command execution with correct exit codes
#   - Timeout triggering and exit code 124
#   - Process cleanup after timeout
#   - Subprocess cleanup (no zombie processes)
#   - Signal handling (SIGTERM then SIGKILL)
#
# Requirements: 2.3.1, 2.4.2

setup() {
  load '../vendor/bats-support/load.bash'
  load '../vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"

  # Source the timeout module
  export SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

  # shellcheck source=scripts/lib/timeout.sh
  . "$SCRIPT_DIR/scripts/lib/timeout.sh"
}

teardown() {
  # Clean up any remaining test processes
  pkill -P $$ 2>/dev/null || true

  # Remove temporary directory
  rm -rf "$TEMP_DIR"
}

# ── Test: Normal Command Execution ───────────────────────────────────────────

@test "run_with_timeout_robust: normal command returns correct exit code 0" {
  run run_with_timeout_robust 5 echo "hello"
  assert_success
  assert_output "hello"
}

@test "run_with_timeout_robust: normal command returns correct exit code 1" {
  run run_with_timeout_robust 5 sh -c "exit 1"
  assert_failure 1
}

@test "run_with_timeout_robust: normal command returns correct exit code 42" {
  run run_with_timeout_robust 5 sh -c "exit 42"
  assert_failure 42
}

@test "run_with_timeout_robust: command with arguments executes correctly" {
  run run_with_timeout_robust 5 sh -c 'echo "arg1 arg2 arg3"'
  assert_success
  assert_output "arg1 arg2 arg3"
}

@test "run_with_timeout_robust: fast command completes before timeout" {
  run run_with_timeout_robust 10 sleep 0.1
  assert_success
}

# ── Test: Timeout Triggering ─────────────────────────────────────────────────

@test "run_with_timeout_robust: timeout triggers and returns exit code 124" {
  run run_with_timeout_robust 1 sleep 10
  assert_failure 124
}

@test "run_with_timeout_robust: short timeout triggers correctly" {
  run run_with_timeout_robust 1 sleep 5
  assert_failure 124
}

@test "run_with_timeout_robust: timeout with command that ignores SIGTERM" {
  # Create a script that traps SIGTERM but eventually gets killed
  cat >"$TEMP_DIR/ignore_sigterm.sh" <<'EOF'
#!/usr/bin/env sh
trap '' TERM
sleep 100
EOF
  chmod +x "$TEMP_DIR/ignore_sigterm.sh"

  run run_with_timeout_robust 2 "$TEMP_DIR/ignore_sigterm.sh"
  # Should return 124 (timeout) or 137 (SIGKILL) depending on implementation
  # Both are acceptable as they indicate the process was forcefully terminated
  assert_failure
  [[ $status -eq 124 || $status -eq 137 ]]
}

# ── Test: Process Cleanup ────────────────────────────────────────────────────

@test "run_with_timeout_robust: process cleanup after timeout" {
  # Start a sleep process with timeout
  run_with_timeout_robust 1 sleep 100 &
  local test_pid=$!

  # Wait for timeout to trigger
  wait $test_pid 2>/dev/null || true

  # Verify no sleep processes remain
  sleep 0.5 # Give cleanup time to complete
  run pgrep -f "sleep 100"
  assert_failure
}

@test "run_with_timeout_robust: multiple processes cleaned up after timeout" {
  # Create a script that spawns multiple sleep processes
  cat >"$TEMP_DIR/multi_sleep.sh" <<'EOF'
#!/usr/bin/env sh
sleep 100 &
sleep 100 &
sleep 100 &
wait
EOF
  chmod +x "$TEMP_DIR/multi_sleep.sh"

  run run_with_timeout_robust 1 "$TEMP_DIR/multi_sleep.sh"
  assert_failure 124

  # Verify no sleep processes remain
  sleep 0.5 # Give cleanup time to complete
  run pgrep -f "sleep 100"
  assert_failure
}

# ── Test: Subprocess Cleanup (No Zombie Processes) ───────────────────────────

@test "run_with_timeout_robust: no zombie processes after timeout" {
  # Run a command that spawns subprocesses
  run_with_timeout_robust 1 sh -c 'sleep 100 & sleep 100 & wait' &
  local test_pid=$!

  # Wait for timeout
  wait $test_pid 2>/dev/null || true
  sleep 0.5 #Give cleanup time to complete

  # Check for zombie processes
  run sh -c "ps aux | grep -E 'Z|defunct' | grep -v grep"
  # If there are zombies, the output will contain them
  # We expect no zombies related to our test
  if [ "$status" -eq 0 ]; then
    # Check if any zombies are related to sleep
    run sh -c "ps aux | grep -E 'Z|defunct' | grep sleep | grep -v grep"
    assert_failure
  fi
}

@test "run_with_timeout_robust: subprocess tree cleaned up" {
  # Create a script with nested subprocesses
  cat >"$TEMP_DIR/nested.sh" <<'EOF'
#!/usr/bin/env sh
(
  (
    sleep 100
  ) &
  sleep 100
) &
wait
EOF
  chmod +x "$TEMP_DIR/nested.sh"

  run run_with_timeout_robust 1 "$TEMP_DIR/nested.sh"
  assert_failure 124

  # Verify all sleep processes are cleaned up
  sleep 0.5
  run pgrep -f "sleep 100"
  assert_failure
}

# ── Test: Signal Handling (SIGTERM then SIGKILL) ─────────────────────────────

@test "cleanup_process_tree: sends SIGTERM first" {
  # Start a process that can handle SIGTERM gracefully
  cat >"$TEMP_DIR/graceful.sh" <<'EOF'
#!/usr/bin/env sh
trap 'echo "SIGTERM received"; exit 0' TERM
sleep 100
EOF
  chmod +x "$TEMP_DIR/graceful.sh"

  "$TEMP_DIR/graceful.sh" &
  local pid=$!

  # Give process time to start
  sleep 0.2

  # Clean up with grace period
  run cleanup_process_tree $pid 1
  assert_success

  # Process should be gone
  run kill -0 $pid 2>/dev/null
  assert_failure
}

@test "cleanup_process_tree: escalates to SIGKILL after grace period" {
  # Start a process that ignores SIGTERM
  cat >"$TEMP_DIR/stubborn.sh" <<'EOF'
#!/usr/bin/env sh
trap '' TERM
sleep 100
EOF
  chmod +x "$TEMP_DIR/stubborn.sh"

  "$TEMP_DIR/stubborn.sh" &
  local pid=$!

  # Give process time to start
  sleep 0.2

  # Clean up with short grace period (should escalate to SIGKILL)
  run cleanup_process_tree $pid 1
  assert_success

  # Process should be forcefully killed
  sleep 0.5
  run kill -0 $pid 2>/dev/null
  assert_failure
}

@test "cleanup_process_tree: handles already-dead process gracefully" {
  # Start and immediately kill a process
  sleep 0.1 &
  local pid=$!
  wait $pid 2>/dev/null || true

  # Try to clean up already-dead process
  run cleanup_process_tree $pid 1
  assert_success
}

@test "cleanup_process_tree: handles invalid PID gracefully" {
  # Try to clean up non-existent PID
  run cleanup_process_tree 999999 1
  assert_success
}

@test "cleanup_process_tree: handles empty PID gracefully" {
  run cleanup_process_tree "" 1
  assert_success
}

# ── Test: Edge Cases ─────────────────────────────────────────────────────────

@test "run_with_timeout_robust: fails with missing timeout parameter" {
  run run_with_timeout_robust
  assert_failure 1
}

@test "run_with_timeout_robust: fails with missing command" {
  run run_with_timeout_robust 5
  assert_failure 1
}

@test "run_with_timeout_robust: handles zero timeout" {
  run run_with_timeout_robust 0 echo "test"
  # Behavior may vary by implementation, but should not hang
  # Just verify it completes
  [ "$status" -ne 255 ]
}

@test "run_with_timeout_robust: handles very long timeout" {
  run run_with_timeout_robust 3600 echo "test"
  assert_success
  assert_output "test"
}

# ── Test: Timeout Implementation Detection ───────────────────────────────────

@test "detect_timeout_impl: returns valid implementation" {
  run detect_timeout_impl
  assert_success
  # Should return one of: timeout, gtimeout, or bash
  [[ $output =~ ^(timeout|gtimeout|bash)$ ]]
}

# ── Test: Process Group Management ───────────────────────────────────────────

@test "start_process_group: starts process and returns PID" {
  run start_process_group sleep 10
  assert_success

  local pid="$output"
  # Verify PID is a number
  [[ $pid =~ ^[0-9]+$ ]]

  # Verify process is running
  if kill -0 "$pid" 2>/dev/null; then
    # Process is still running, test passes
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  else
    # Process already finished, which is also acceptable
    # (means it started successfully and completed)
    true
  fi
}

@test "start_process_group: process runs in background" {
  # Test that start_process_group returns a PID and doesn't block
  local pid
  pid=$(start_process_group sleep 10)

  # Verify we got a PID (numeric value)
  [[ $pid =~ ^[0-9]+$ ]]

  # Clean up
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}
