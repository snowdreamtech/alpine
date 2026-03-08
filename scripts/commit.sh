#!/bin/sh
# scripts/commit.sh - Structured Committer Script
# Professional CLI wrapper for Commitizen and pre-commit health checks.
# Features: POSIX compliant, Execution Guard, SSoT Architecture, Professional UX.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Starts the interactive Commitizen CLI to create a structured commit message.
Performs a quick environment check before starting.

Options:
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

Environment Variables:
  NPM              NPM client (default: pnpm)

EOF
}

# Argument parsing
parse_common_args "$@"

log_info "📝 Starting Structured Commit Guide...\n"

# 2. Pre-check: Environment
if command -v sh >/dev/null 2>&1 && [ -f "scripts/check-env.sh" ]; then
  log_info "Running quick environment check..."
  sh scripts/check-env.sh --quiet || {
    log_warn "Warning: Environment check found issues. Committing anyway..."
  }
fi

# 3. Check for dependencies
NPM=${NPM:-pnpm}
if ! command -v "$NPM" >/dev/null 2>&1; then
  log_error "Error: $NPM client not found."
  exit 1
fi

# 4. Launch Commitizen
if [ "$DRY_RUN" -eq 1 ]; then
  log_success "DRY-RUN: Would launch interactive Commitizen CLI."
  if [ -f "package.json" ] && grep -q '"commit":' package.json; then
    log_info "Command: $NPM run commit"
  else
    log_info "Command: $NPM exec cz"
  fi
  exit 0
fi

log_info "Launching interactive CLI..."
if [ -f "package.json" ] && grep -q '"commit":' package.json; then
  "$NPM" run commit
else
  # Fallback to direct npx if script not found
  "$NPM" exec cz
fi
