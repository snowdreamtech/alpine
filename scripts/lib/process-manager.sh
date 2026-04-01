#!/usr/bin/env sh
# shellcheck disable=SC2034
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/lib/process-manager.sh - Process management module
#
# Purpose:
#   Provides robust process cleanup to prevent zombie processes and ensure
#   proper resource cleanup. Implements graceful shutdown with SIGTERM → SIGKILL
#   escalation and child process cleanup.
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Requirements: 2.4.1, 2.4.2

# ── 🛡️ Process Cleanup Functions ────────────────────────────────────────────

# Purpose: Cleans up a process and all its children with graceful shutdown
# Params:
#   $1 - Process PID (required)
#   $2 - Grace period in seconds (optional, default: 3)
# Returns:
#   0 - Process cleaned up successfully
#   0 - Process already terminated
# Examples:
#   cleanup_process_tree 12345
#   cleanup_process_tree 12345 5
# Notes:
#   - Sends SIGTERM first for graceful shutdown
#   - Waits for grace period (default 3 seconds)
#   - Escalates to SIGKILL if process doesn't terminate
#   - Cleans up all child processes using pkill -P
#   - Safe to call on non-existent PIDs
cleanup_process_tree() {
  local _PID="${1:-}"
  local _GRACE="${2:-3}"

  # Validate PID parameter
  [ -z "${_PID:-}" ] && return 0

  # Check if process exists
  if ! kill -0 "${_PID:-}" 2>/dev/null; then
    return 0
  fi

  # 1. Send SIGTERM to process group (graceful shutdown)
  # Try process group first (-PID), fallback to single process
  kill -TERM -"${_PID:-}" 2>/dev/null || kill -TERM "${_PID:-}" 2>/dev/null || true

  # 2. Wait for graceful shutdown with configurable timeout
  local _WAITED=0
  while [ "${_WAITED:-}" -lt "${_GRACE:-}" ]; do
    # Check if process has terminated
    if ! kill -0 "${_PID:-}" 2>/dev/null; then
      return 0
    fi
    sleep 1
    _WAITED=$((_WAITED + 1))
  done

  # 3. Escalate to SIGKILL for unresponsive processes
  # Try process group first, fallback to single process
  kill -KILL -"${_PID:-}" 2>/dev/null || kill -KILL "${_PID:-}" 2>/dev/null || true

  # 4. Clean up any remaining child processes
  if command -v pkill >/dev/null 2>&1; then
    pkill -KILL -P "${_PID:-}" 2>/dev/null || true
  fi

  return 0
}

# Purpose: Starts a command in a new process group for better isolation
# Params:
#   $@ - Command and arguments to execute
# Returns:
#   PID of the process group leader (via stdout)
# Examples:
#   PID=$(start_process_group sleep 100)
#   start_process_group ./long-running-script.sh
# Notes:
#   - Uses setsid if available for proper process group creation
#   - Falls back to subshell if setsid is not available
#   - Process runs in background, caller must wait or cleanup
start_process_group() {
  if command -v setsid >/dev/null 2>&1; then
    # Use setsid to create new session and process group
    # This provides better isolation and cleanup
    setsid "$@" &
  else
    # Fallback: use subshell for basic process grouping
    ("$@") &
  fi
  echo $!
}

# Purpose: Checks if a process is still running
# Params:
#   $1 - Process PID
# Returns:
#   0 - Process is running
#   1 - Process is not running
# Examples:
#   if is_process_running 12345; then
#     echo "Process is alive"
#   fi
is_process_running() {
  local _PID="${1:-}"
  [ -z "${_PID:-}" ] && return 1
  kill -0 "${_PID:-}" 2>/dev/null
}

# Purpose: Waits for a process to terminate with timeout
# Params:
#   $1 - Process PID
#   $2 - Timeout in seconds (optional, default: 10)
# Returns:
#   0 - Process terminated within timeout
#   1 - Process still running after timeout
# Examples:
#   wait_for_process 12345 5
#   if wait_for_process $PID 30; then
#     echo "Process finished"
#   fi
wait_for_process() {
  local _PID="${1:-}"
  local _TIMEOUT="${2:-10}"

  [ -z "${_PID:-}" ] && return 1

  local _WAITED=0
  while [ "${_WAITED:-}" -lt "${_TIMEOUT:-}" ]; do
    if ! kill -0 "${_PID:-}" 2>/dev/null; then
      return 0
    fi
    sleep 1
    _WAITED=$((_WAITED + 1))
  done

  return 1
}

# Export functions for use in other scripts
# Note: export -f is Bash-specific, but we provide the functions for sourcing
