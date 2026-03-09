#!/bin/sh
# scripts/commit.sh - Guided Commit Manager
# Facilitates high-quality, conventional commits with Commitizen and health checks.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Pre-commit verification before guided entry.
#   - Node.js dependency detection and routing.
#   - Professional UX for streamlined version control.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

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
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
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
      # Check if there are ANY changes at all
      if [ -z "$(git status --porcelain)" ]; then
        log_success "Nothing to commit, working tree clean. ✨"
        exit 0
      else
        log_warn "⚠️  No files added to staging! Your changes are currently unstaged."
        log_info "Modified files:"
        git status --porcelain | grep -E '^ [MADRC]' || true
        printf "\n"
        log_info "💡 Run 'git add <file>' or 'make format' (which stages some files) before committing."
        exit 0
      fi
    fi
  fi

  # 4. Check for dependencies
  local _NPM_LOCAL
  _NPM_LOCAL=${NPM:-pnpm}
  if ! command -v "$_NPM_LOCAL" >/dev/null 2>&1; then
    log_error "Error: $_NPM_LOCAL client not found."
    exit 1
  fi

  # 5. Launch Commitizen
  if [ "$DRY_RUN" -eq 1 ]; then
    log_success "DRY-RUN: Would launch interactive Commitizen CLI."
    if [ -f "package.json" ] && grep -q '"commit":' package.json; then
      log_info "Command: $_NPM_LOCAL run commit"
    else
      log_info "Command: $_NPM_LOCAL exec cz"
    fi
    exit 0
  fi

  log_info "Launching interactive CLI..."
  # We use direct exec to avoid recursion if the npm script points back here
  "$_NPM_LOCAL" exec cz

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bgit push%b to upload your changes to the remote.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
