#!/bin/sh
# scripts/cleanup.sh - Deep Project Cleanup Script
# Removes temporary files, build artifacts, and caches across all supported stacks.
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
parse_common_args "$@"

log_info "🧹 Starting deep project cleanup...\n"

clean_item() {
  _PATH="$1"
  _DESC="$2"

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

# Finding and removing __pycache__ and .pyc files
if [ "$DRY_RUN" -eq 1 ]; then
  log_success "DRY-RUN: Would search and remove all __pycache__ and *.pyc files."
else
  find . -type d -name "__pycache__" -not -path "*/.*" -exec rm -rf {} + 2>/dev/null || true
  find . -type f -name "*.pyc" -not -path "*/.*" -exec rm -f {} + 2>/dev/null || true
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
  find . -type f -name ".DS_Store" -not -path "*/.*" -exec rm -f {} + 2>/dev/null || true
  find . -type f -name "Thumbs.db" -not -path "*/.*" -exec rm -f {} + 2>/dev/null || true
fi

log_success "\n✨ Cleanup complete!"
