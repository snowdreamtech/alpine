#!/bin/sh
# scripts/release.sh - Standardized Release Manager
# Automates versioning, tagging, and pre-release verification.
# Features: POSIX compliant, Execution Guard, Dry-run support, Professional UX.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

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

main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  _TARGET_VERSION=""
  for _arg in "$@"; do
    case "$_arg" in
    [0-9]* | v[0-9]*)
      _TARGET_VERSION="$_arg"
      ;;
    esac
  done
  parse_common_args "$@"

  log_info "📦 Starting Standardized Release Process...\n"

  # 3. Pre-release verification
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

  # 4. Versioning & Tagging logic
  run_release() {
    log_info "── Action: Creating release $_TARGET_VERSION ──"

    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "DRY-RUN: Would tag version $_TARGET_VERSION and push to origin."
      log_info "DRY-RUN: Would trigger GitHub Actions release-please-manual workflow."
    else
      if [ -n "$_TARGET_VERSION" ]; then
        log_info "Tagging local repository..."
        git tag -a "$_TARGET_VERSION" -m "chore(release): $_TARGET_VERSION"
        log_info "Pushing tags to origin..."
        git push origin "$_TARGET_VERSION"
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
  printf "\n"

  # Optional: run npm release if extra tools are defined in package.json
  run_npm_script "release"

  log_success "\n✨ Release process completed successfully!"

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bgit push --tags%b to publish the version tag.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
