#!/bin/sh
# scripts/docs.sh - Documentation Management Script
# Professional CLI wrapper for VitePress dev, build, and preview.
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
for _arg in "$@"; do
  case "$_arg" in
  dev | build | preview) COMMAND="$_arg" ;;
  esac
done
parse_common_args "$@"

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
