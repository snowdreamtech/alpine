#!/bin/sh
# scripts/release.sh - Standardized Release Manager
# Automates versioning, tagging, and pre-release verification.
# Features: POSIX compliant, Execution Guard, Dry-run support, Professional UX.

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=1 # 0: quiet, 1: normal, 2: verbose
DRY_RUN=0

# Logging functions
log_info() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$BLUE" "$1" "$NC"; fi
}
log_success() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$GREEN" "$1" "$NC"; fi
}
log_warn() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; fi
}
log_error() {
  printf "%b%s%b\n" "$RED" "$1" "$NC" >&2
}

# 1. Execution Context Guard
if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
  log_error "Error: This script must be run from the project root."
  exit 1
fi

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] [VERSION]

Standardized release manager for versioning and tagging.

Options:
  --dry-run        Preview release actions without executing them.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

VERSION:
  A semantic version (e.g., 1.2.3 or v1.2.3). If omitted,
  release-please or standard versioning metadata is used.

EOF
}

# Argument parsing
TARGET_VERSION=""
for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=1
    log_warn "Running in DRY-RUN mode. No changes will be applied."
    ;;
  -q | --quiet) VERBOSE=0 ;;
  -v | --verbose) VERBOSE=2 ;;
  -h | --help)
    show_help
    exit 0
    ;;
  [0-9]* | v[0-9]*)
    TARGET_VERSION="$arg"
    ;;
  esac
done

log_info "📦 Starting Standardized Release Process...\n"

# 2. Pre-release verification
run_verify() {
  log_info "── Verification: Running pre-flight checks ──"
  if [ -f "scripts/verify.sh" ]; then
    sh scripts/verify.sh --quiet || {
      log_error "Error: Verification failed. Cannot proceed with release."
      exit 1
    }
  else
    log_warn "Warning: scripts/verify.sh not found. Proceeding with caution."
  fi
}

# 3. Versioning & Tagging logic
run_release() {
  log_info "── Action: Creating release $TARGET_VERSION ──"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would tag version $TARGET_VERSION and push to origin."
    log_info "DRY-RUN: Would trigger GitHub Actions release-please-manual workflow."
  else
    if [ -n "$TARGET_VERSION" ]; then
      log_info "Tagging local repository..."
      git tag -a "$TARGET_VERSION" -m "chore(release): $TARGET_VERSION"
      log_info "Pushing tags to origin..."
      git push origin "$TARGET_VERSION"
    else
      log_info "No version specified. Relying on remote release-please automation."
      # Placeholder for triggering manual workflow via CLI if needed
      if command -v gh >/dev/null 2>&1; then
        gh workflow run release-please-manual.yml --ref main
      fi
    fi
  fi
}

run_verify
printf "\n"
run_release

log_success "\n✨ Release process completed successfully!"
