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

  # Ensure PyYAML is installed
  if ! python3 -c "import yaml" >/dev/null 2>&1; then
    log_info "Installing PyYAML..."
    python3 -m pip install --quiet PyYAML || {
      log_error "Failed to install PyYAML"
      exit 1
    }
  fi

  local _SCRIPT="scripts/sync-harden-runner.py"

  if [ ! -f "${_SCRIPT:-}" ]; then
    log_error "Error: Python script ${_SCRIPT:-} not found"
    exit 1
  fi

  log_info "✓ Running Python synchronization script..."
  python3 "${_SCRIPT:-}" "$@"
}

main "$@"
