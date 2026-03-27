#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/sync-lock.sh - Mise Lockfile Synchronizer
#
# Purpose:
#   Synchronizes mise.lock with the comprehensive manifest (Tier 1 + Tier 2).
#   Ensures all tools are cryptographically locked for all supported platforms.

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "${0:-}")" && pwd)
. "${SCRIPT_DIR:-}/lib/common.sh"

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Synchronizes mise.lock for all supported platforms.
# Params:
#   $@ - Optional additional tools to lock
# Examples:
#   run_sync_lock
run_sync_lock() {
  log_info "Synchronizing mise.lock for all platforms..."

  # 1. Manifest Aggregation
  local _TMP_MANIFEST=".mise.toml.lock.temp"
  ./scripts/gen-full-manifest.sh >"${_TMP_MANIFEST:-}"

  # 2. List Extraction
  local _TOOLS
  _TOOLS=$(grep "=" "${_TMP_MANIFEST:-}" | cut -d= -f1 | tr -d '" ' | xargs)

  # 3. Multi-Platform Locking
  # Platforms: Ubuntu/Debian (glibc), Alpine (musl), macOS (x64/arm64), Windows (x64).
  # shellcheck disable=SC2086
  MISE_CONFIG="${_TMP_MANIFEST:-}" mise lock --platform linux-x64,linux-arm64,linux-x64-musl,linux-arm64-musl,macos-x64,macos-arm64,windows-x64 ${_TOOLS:-} "$@"

  # 4. Cleanup
  rm -f "${_TMP_MANIFEST:-}"

  log_success "mise.lock synchronized successfully for all platforms."
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  guard_project_root
  run_sync_lock "$@"
}

main "$@"
