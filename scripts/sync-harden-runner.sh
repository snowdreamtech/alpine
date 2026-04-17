#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/sync-harden-runner.sh - Harden Runner Endpoint Synchronizer
#
# Purpose:
#   Synchronizes Harden Runner allowed-endpoints across all workflow files
#   using the centralized configuration in .github/harden-runner-endpoints.yml
#
# Usage:
#   sh scripts/sync-harden-runner.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic
#   - Reads from .github/harden-runner-endpoints.yml
#   - Updates all workflow files with appropriate endpoint profiles

set -eu

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "${0:-}")" && pwd)
. "${SCRIPT_DIR:-}/lib/common.sh"

# Purpose: Main entry point
main() {
  guard_project_root

  log_info "📋 Synchronizing Harden Runner endpoints from centralized config..."

  # Check if yq is available
  if ! command -v yq >/dev/null 2>&1; then
    log_error "Error: yq is required but not installed."
    log_info "Install with: brew install yq (macOS) or mise install yq"
    exit 1
  fi

  local _CONFIG=".github/harden-runner-endpoints.yml"

  if [ ! -f "${_CONFIG:-}" ]; then
    log_error "Error: Configuration file ${_CONFIG:-} not found"
    exit 1
  fi

  log_info "✓ Configuration file found: ${_CONFIG:-}"
  log_info ""
  log_info "This script requires manual implementation due to complexity."
  log_info "Please use the Python script instead: python3 scripts/sync-harden-runner.py"

  exit 0
}

main "$@"
