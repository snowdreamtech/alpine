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

# 3. Check for staged files
if [ "$DRY_RUN" -eq 0 ]; then
  if ! git diff --cached --quiet; then
    log_debug "Staged changes detected."
  else
    log_error "Error: No files added to staging! Did you forget to run 'git add'?"
    exit 1
  fi
fi

# 4. Check for dependencies
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
# We use direct exec to avoid recursion if the npm script points back here
"$NPM" exec cz

# Next Actions
if [ "$DRY_RUN" -eq 0 ]; then
  printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
  printf "  - Run %bgit push%b to upload your changes to the remote.\n" "${GREEN}" "${NC}"
fi
