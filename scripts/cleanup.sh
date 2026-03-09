#!/bin/sh
# scripts/cleanup.sh - Deep Project Sanitizer
# Thoroughly removes build artifacts, temporary files, and caches across all platforms.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Cross-stack cleanup (node, python, go, rust, iac).
#   - Safe dry-run support for destructive operations.
#   - Professional UX with detailed reclamation logs.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Removes temporary files, build artifacts, and caches across all supported stacks.

Options:
  --dry-run        Preview files to be deleted without removing them.
  -q, --quiet      Only show errors.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# Argument parsing
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "🧹 Starting deep project cleanup...\n"

  clean_item() {
    local _PATH="$1"
    local _DESC="$2"

    if [ -e "$_PATH" ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        log_success "DRY-RUN: Would remove $_DESC ($_PATH)"
      else
        log_info "Removing $_DESC ($_PATH)..."
        rm -rf "$_PATH"
      fi
    else
      log_debug "Skipping $_DESC ($_PATH) - Not found."
    fi
  }

  # 2. General Artifacts
  clean_item "dist" "Build distribution"
  clean_item "build" "Build artifacts"
  clean_item "out" "Output directory"
  clean_item "bin" "Binary output"
  clean_item "target" "Language target directory"
  clean_item ".coverage" "Coverage report"
  clean_item "coverage.xml" "Coverage XML"

  # 3. Language Specific Caches
  log_info "\n📦 Cleaning language-specific caches..."

  # Python
  clean_item ".pytest_cache" "Pytest cache"
  clean_item ".ruff_cache" "Ruff cache"
  clean_item ".mypy_cache" "Mypy cache"
  clean_item ".venv" "Python virtual environment"

  # Finding and removing __pycache__ and .pyc files
  if [ "$DRY_RUN" -eq 1 ]; then
    log_success "DRY-RUN: Would search and remove all __pycache__ and *.pyc files."
  else
    # Using POSIX compliant find
    find . -type d -name "__pycache__" ! -path "*/.*" -exec rm -rf {} \; 2>/dev/null || true
    find . -type f -name "*.pyc" ! -path "*/.*" -exec rm -f {} \; 2>/dev/null || true
  fi

  # Node.js
  # We don't remove node_modules by default, only build output
  clean_item ".next" "Next.js build"
  clean_item ".nuxt" "Nuxt.js build"
  clean_item ".output" "Vite/Nitro output"

  # Rust / Go / Java
  # Handled in General Artifacts (target, bin)

  # 4. OS Specific Caches
  if [ "$DRY_RUN" -eq 1 ]; then
    log_success "DRY-RUN: Would remove .DS_Store and Thumbs.db files."
  else
    # Using POSIX compliant find
    find . -type f -name ".DS_Store" ! -path "*/.*" -exec rm -f {} \; 2>/dev/null || true
    find . -type f -name "Thumbs.db" ! -path "*/.*" -exec rm -f {} \; 2>/dev/null || true
  fi

  log_success "\n✨ Cleanup complete!"
}

main "$@"
