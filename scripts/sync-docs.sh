#!/bin/sh
# scripts/sync-docs.sh - Documentation Sync Wrapper
#
# Purpose:
#   Provides a stable POSIX entry point for the Python documentation sync logic.
#   Ensures environment variables and project guards are handled consistently.
#
# Usage:
#   sh scripts/sync-docs.sh
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 03 (Architecture).

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

main() {
  guard_project_root

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_warn "DRY-RUN: Would synchronize Rules and Workflows to Docs."
    return 0
  fi

  python3 "$SCRIPT_DIR/sync-docs.py"

  log_success "\n✨ Documentation synchronization complete!"
}

main "$@"
