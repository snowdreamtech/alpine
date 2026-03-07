#!/bin/sh
# scripts/docs.sh - Documentation Management Script
# Professional CLI wrapper for VitePress dev, build, and preview.
# Features: POSIX compliant, Execution Guard, SSoT Architecture, Professional UX.

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=1 # 0: quiet, 1: normal, 2: verbose

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
log_debug() {
  if [ "$VERBOSE" -ge 2 ]; then printf "[DEBUG] %s\n" "$1"; fi
}

# 1. Execution Context Guard
if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
  log_error "Error: This script must be run from the project root."
  exit 1
fi

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] [COMMAND]

Manages the VitePress documentation site.

Commands:
  dev              Start VitePress development server (default).
  build            Build the documentation site.
  preview          Preview the production build.

Options:
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

Environment Variables:
  NPM              NPM client (default: pnpm)
  DOCS_DIR         Documentation directory (default: docs)

EOF
}

# Argument parsing
COMMAND="dev"
for arg in "$@"; do
  case "$arg" in
  dev | build | preview) COMMAND="$arg" ;;
  -q | --quiet) VERBOSE=0 ;;
  -v | --verbose) VERBOSE=2 ;;
  -h | --help)
    show_help
    exit 0
    ;;
  esac
done

log_info "📖 Documentation Manager ($COMMAND)...\n"

# 2. Check for dependencies
NPM=${NPM:-pnpm}
DOCS_DIR=${DOCS_DIR:-docs}

if [ ! -d "$DOCS_DIR" ]; then
  log_error "Error: Documentation directory '$DOCS_DIR' not found."
  exit 1
fi

if ! command -v "$NPM" >/dev/null 2>&1; then
  log_error "Error: $NPM client not found."
  exit 1
fi

# 3. Execute VitePress via NPM
case "$COMMAND" in
dev)
  log_info "Starting development server..."
  "$NPM" exec vitepress dev "$DOCS_DIR"
  ;;
build)
  log_info "Building documentation site..."
  "$NPM" exec vitepress build "$DOCS_DIR"
  log_success "\n✨ Build complete! Artifacts are in $DOCS_DIR/.vitepress/dist"
  ;;
preview)
  log_info "Previewing production build..."
  "$NPM" exec vitepress preview "$DOCS_DIR"
  ;;
esac
