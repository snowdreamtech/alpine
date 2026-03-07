#!/bin/sh
# scripts/update.sh - Tooling Update Manager
# Standardizes updating of global and project tools (pnpm, pre-commit, brew, etc.).

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# ── Configuration ────────────────────────────────────────────────────────────

# Help Message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Standardizes updating of global and project tools.

Options:
  --dry-run        Preview updates without applying them.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# 2. Argument Parsing
parse_common_args "$@"

log_info "🔄 Starting Tooling Update Manager...\n"

run_update() {
  _CMD="$1"
  _DESC="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would run $_DESC [$_CMD]"
  else
    log_info "Updating $_DESC..."
    eval "$_CMD"
  fi
}

# 3. Core Package Managers
if command -v "$NPM" >/dev/null 2>&1; then
  run_update "$NPM self-update" "$NPM (self-update)"
fi

if command -v brew >/dev/null 2>&1; then
  run_update "brew update" "Homebrew"
fi

# 4. Git Hooks & Tooling
if [ -x "$VENV/bin/pre-commit" ]; then
  run_update "$VENV/bin/pre-commit autoupdate" "pre-commit hooks"
elif command -v pre-commit >/dev/null 2>&1; then
  run_update "pre-commit autoupdate" "pre-commit hooks"
fi

log_success "\n✨ Update process finished."
