#!/bin/sh
# scripts/release.sh - Standardized Release Manager
# Automates semantic versioning, git tagging, and pre-release verification.
#
# Usage:
#   sh scripts/release.sh [OPTIONS] [VERSION]
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Automated version extraction from manifests.
#   - Guarded git operations with dry-run support.
#   - Professional UX with clear next-action prompts.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Displays usage information for the release manager.
# Examples:
#   show_help
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

# Purpose: Executes pre-flight health checks before allowing a release.
# Examples:
#   run_release_verify
run_release_verify() {
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

# Purpose: Handles the actual git tagging and remote synchronization logic.
# Params:
#   $1 - The target version string
# Examples:
#   perform_git_release "v1.0.0"
perform_git_release() {
  local _LV_TARGET_VERSION="$1"
  log_info "── Action: Creating release $_LV_TARGET_VERSION ──"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would tag version $_LV_TARGET_VERSION and push to origin."
    log_info "DRY-RUN: Would trigger GitHub Actions release-please-manual workflow."
  else
    if [ -n "$_LV_TARGET_VERSION" ]; then
      log_info "Tagging local repository..."
      git tag -a "$_LV_TARGET_VERSION" -m "chore(release): $_LV_TARGET_VERSION"
      log_info "Pushing tags to origin..."
      git push origin "$_LV_TARGET_VERSION"
    else
      log_info "No version specified. Relying on remote release-please automation."
      # Placeholder for triggering manual workflow via CLI if needed
      if command -v gh >/dev/null 2>&1; then
        gh workflow run release-please-manual.yml --ref main
      fi
    fi
  fi
}

# Purpose: Main entry point for the release management engine.
# Params:
#   $@ - Command line arguments and optional version
# Examples:
#   main v1.2.3
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _REL_TARGET_VERSION=""
  local _arg_rel
  for _arg_rel in "$@"; do
    case "$_arg_rel" in
    [0-9]* | v[0-9]*)
      _REL_TARGET_VERSION="$_arg_rel"
      ;;
    esac
  done
  parse_common_args "$@"

  log_info "📦 Starting Standardized Release Process...\n"

  # 3. Pre-release verification
  run_release_verify

  printf "\n"

  # 4. Versioning & Tagging logic
  perform_git_release "$_REL_TARGET_VERSION"

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
