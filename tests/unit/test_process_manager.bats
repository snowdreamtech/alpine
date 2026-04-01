#!/usr/bin/env bats
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# tests/unit/test_process_manager.bats - Unit tests for process management module
#
# Purpose:
#   Tests the process-manager.sh module functions including:
#   - Process cleanup with SIGTERM
#   - SIGKILL escalation after timeout
#   - Child process cleanup
#   - Zombie process prevention
#
# Requirements: 2.4.1, 2.4.2

setup() {
  load '../vendor/bats-support/load.bash'
  load '../vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"

  # Source the module
  export SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

  # shellcheck source=scripts/lib/process-manager.sh
  . "$SCRIPT_DIR/scripts/lib/process-manager.sh"
}

teardown() {
  # Clean up any remaining test processes
  pkill -P $$ 2>/dev/null || true

  # Remove temporary directory
  rm -rf "$TEMP_DIR"
}

# ── Test: Process Cleanup with SIGTERM ───────────────────────────────────────

@test "cleanup_process_tree: terminates process with SIGTERM" {
  # Start a long-running process
  sleep 100 &
  local pid=$!

  # Give process time to start
  sleep 0.2

  # Verify process is running
  run kill -0 $pid 2>/dev/null
  assert_success

  # Clean up with grace period
  run cleanup_process_tree $pid 2
  assert_success

  # Verify process is terminated
  sleep 0.5
  run kill -0 $pid 2>/dev/null
  assert_failure
}

@test "cleanup_process_tree: handles graceful shutdown" {
  # Create a script that handles SIGTERM gracefully
  cat >"$TEMP_DIR/graceful.sh" <<'EOF'
#!/usr/bin/env sh
trap 'exit 0' TERM
sleep 100
EOF
  chmod +x "$TEMP_DIR/graceful.sh"

  "$TEMP_DIR/graceful.sh" &
  local pid=$!
  sleep 0.2

  # Clean up
  run cleanup_process_tree $pid 1
  assert_success

  # Process should be gone
  sleep 0.5
  run kill -0 $pid 2>/dev/null
  assert_failure
}

# ── Test: SIGKILL Escalation ─────────────────────────────────────────────────

@test "cleanup_process_tree: escalates to SIGKILL after timeout" {
  # Create a script that ignores SIGTERM
  cat >"$TEMP_DIR/stubborn.sh" <<'EOF'
#!/usr/bin/env sh
trap '' TERM
sleep 100
EOF
  chmod +x "$TEMP_DIR/stubborn.sh"

  "$TEMP_DIR/stubborn.sh" &
  local pid=$!
  sleep 0.2

  # Clean up with short grace period (should escalate to SIGKILL)
  run cleanup_process_tree $pid 1
  assert_success

  # Process should be forcefully killed
  sleep 0.5
  run kill -0 $pid 2>/dev/null
  assert_failure
}

@test "cleanup_process_tree: SIGKILL works when SIGTERM ignored" {
  # Start a process that traps SIGTERM
  cat >"$TEMP_DIR/ignore_term.sh" <<'EOF'
#!/usr/bin/env sh
trap '' TERM
while true; do sleep 1; done
EOF
  chmod +x "$TEMP_DIR/ignore_term.sh"

  "$TEMP_DIR/ignore_term.sh" &
  local pid=$!
  sleep 0.2

  # Cleanup should eventually kill it
  run cleanup_process_tree $pid 1
  assert_success

  # Verify it's dead
  sleep 1
  run kill -0 $pid 2>/dev/null
  assert_failure
}

# ── Test: Child Process Cleanup ──────────────────────────────────────────────

@test "cleanup_process_tree: cleans up child processes" {
  # Create a script that spawns children
  cat >"$TEMP_DIR/parent.sh" <<'EOF'
#!/usr/bin/env sh
sleep 100 &
sleep 100 &
sleep 100 &
wait
EOF
  chmod +x "$TEMP_DIR/parent.sh"

  "$TEMP_DIR/parent.sh" &
  local pid=$!
  sleep 0.5

  # Verify children are running
  local child_count
  child_count=$(pgrep -P $pid | wc -l)
  [ "$child_count" -gt 0 ]

  # Clean up parent
  run cleanup_process_tree $pid 1
  assert_success

  # Verify all children are cleaned up
  sleep 0.5
  run pgrep -P $pid
  assert_failure
}

@test "cleanup_process_tree: handles nested process tree" {
  # Create nested process structure
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

  "$TEMP_DIR/nested.sh" &
  local pid=$!
  sleep 0.5

  # Clean up
  run cleanup_process_tree $pid 1
  assert_success

  # Verify all processes cleaned up
  sleep 0.5
  run pgrep -f "sleep 100"
  assert_failure
}

# ── Test: Zombie Process Prevention ──────────────────────────────────────────

@test "cleanup_process_tree: prevents zombie processes" {
  # Start a process
  sleep 100 &
  local pid=$!
  sleep 0.2

  # Clean up
  cleanup_process_tree $pid 1

  # Wait a bit for cleanup
  sleep 0.5

  # Check for zombies
  run sh -c "ps aux | grep -E 'Z|defunct' | grep $pid | grep -v grep"
  assert_failure
}

@test "cleanup_process_tree: no zombies with multiple children" {
  # Create script with multiple children
  cat >"$TEMP_DIR/multi.sh" <<'EOF'
#!/usr/bin/env sh
for i in 1 2 3 4 5; do
  sleep 100 &
done
wait
EOF
  chmod +x "$TEMP_DIR/multi.sh"

  "$TEMP_DIR/multi.sh" &
  local pid=$!
  sleep 0.5

  # Clean up
  cleanup_process_tree $pid 1
  sleep 0.5

  # Check for any zombies
  run sh -c "ps aux| grep -E 'Z|defunct' | grep sleep | grep -v grep"
  assert_failure
}

# ── Test: Helper Functions ───────────────────────────────────────────────────

@test "is_process_running: detects running process" {
  sleep 10 &
  local pid=$!

  run is_process_running $pid
  assert_success

  # Cleanup
  kill $pid 2>/dev/null || true
  wait $pid 2>/dev/null || true
}

@test "is_process_running: detects non-running process" {
  # Use a PID that doesn't exist
  run is_process_running 999999
  assert_failure
}

@test "is_process_running: handles empty PID" {
  run is_process_running ""
  assert_failure
}

@test "wait_for_process: waits for process to complete" {
  # Start a short process
  sleep 0.5 &
  local pid=$!

  # Wait for it
  run wait_for_process $pid 2
  assert_success
}

@test "wait_for_process: times out for long process" {
  # Start a long process
  sleep 100 &
  local pid=$!

  # Wait with short timeout
  run wait_for_process $pid 1
  assert_failure

  # Cleanup
  kill $pid 2>/dev/null || true
  wait $pid 2>/dev/null || true
}

@test "start_process_group: starts process in new group" {
  run start_process_group sleep 10
  assert_success

  local pid="$output"
  # Verify PID is numeric
  [[ "$pid" =~ ^[0-9]+$ ]]

  # Cleanup
  kill $pid 2>/dev/null || true
  wait $pid 2>/dev/null || true
}

# ── Test: Edge Cases ─────────────────────────────────────────────────────────

@test "cleanup_process_tree: handles already-dead process" {
  # Start and immediately kill a process
  sleep 0.1 &
  local pid=$!
  wait $pid 2>/dev/null || true

  # Try to clean up already-dead process
  run cleanup_process_tree $pid 1
  assert_success
}

@test "cleanup_process_tree: handles invalid PID" {
  run cleanup_process_tree 999999 1
  assert_success
}

@test "cleanup_process_tree: handles empty PID" {
  run cleanup_process_tree "" 1
  assert_success
}

@test "cleanup_process_tree: handles zero timeout" {
  sleep 100 &
  local pid=$!
  sleep 0.2

  # Cleanup with zero timeout (should immediately SIGKILL)
  run cleanup_process_tree $pid 0
  assert_success

  sleep 0.5
  run kill -0 $pid 2>/dev/null
  assert_failure
}

@test "cleanup_process_tree: handles negative PID" {
  run cleanup_process_tree -1 1
  assert_success
}

@test "cleanup_process_tree: handles non-numeric PID" {
  run cleanup_process_tree "abc" 1
  assert_success
}

# ── Test: Concurrent Cleanup ─────────────────────────────────────────────────

@test "cleanup_process_tree: handles concurrent cleanups" {
  # Start multiple processes
  sleep 100 &
  local pid1=$!
  sleep 100 &
  local pid2=$!
  sleep 100 &
  local pid3=$!

  sleep 0.2

  # Clean up all concurrently
  cleanup_process_tree $pid1 1 &
  cleanup_process_tree $pid2 1 &
  cleanup_process_tree $pid3 1 &
  wait

  # Verify all are cleaned up
  sleep 0.5
  run kill -0 $pid1 2>/dev/null
  assert_failure
  run kill -0 $pid2 2>/dev/null
  assert_failure
  run kill -0 $pid3 2>/dev/null
  assert_failure
}
