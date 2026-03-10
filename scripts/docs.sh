#!/bin/sh
# scripts/docs.sh - Documentation Lifecycle Manager
# Unified entrance for VitePress development, artifact building, and previews.
#
# Usage:
#   sh scripts/docs.sh [OPTIONS] [COMMAND]
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Automated VitePress installation checks.
#   - Environment-aware routing for local and CI docs.
#   - Professional UX for project documentation maintenance.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Purpose: Displays usage information for the documentation manager.
# Examples:
#   show_help
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

# Purpose: Main entry point for the documentation management engine.
#          Routes to appropriate VitePress commands based on user input.
# Params:
#   $@ - Command line arguments and optional command
# Examples:
#   main build
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _COMMAND_DOC="dev"
  local _arg_doc
  for _arg_doc in "$@"; do
    case "$_arg_doc" in
    dev | build | preview) _COMMAND_DOC="$_arg_doc" ;;
    esac
  done
  parse_common_args "$@"

  log_info "📖 Documentation Manager ($_COMMAND_DOC)...\n"

  # 3. Check for dependencies
  if [ ! -d "$DOCS_DIR" ]; then
    log_error "Error: Documentation directory '$DOCS_DIR' not found."
    exit 1
  fi

  if ! command -v "$NPM" >/dev/null 2>&1; then
    log_error "Error: $NPM client not found."
    exit 1
  fi

  # 4. Execute VitePress via NPM
  case "$_COMMAND_DOC" in
  dev)
    if [ "$DRY_RUN" -eq 1 ]; then
      log_success "DRY-RUN: Would start VitePress dev server on $DOCS_DIR"
    else
      log_info "Starting development server..."
      "$NPM" exec vitepress dev "$DOCS_DIR"
    fi
    ;;
  build)
    if [ "$DRY_RUN" -eq 1 ]; then
      log_success "DRY-RUN: Would build VitePress site from $DOCS_DIR"
    else
      log_info "Building documentation site..."
      "$NPM" exec vitepress build "$DOCS_DIR"
      log_success "\n✨ Build complete! Artifacts are in $DOCS_DIR/.vitepress/dist"
    fi
    ;;
  preview)
    if [ "$DRY_RUN" -eq 1 ]; then
      log_success "DRY-RUN: Would preview VitePress site in $DOCS_DIR"
    else
      log_info "Previewing production build..."
      "$NPM" exec vitepress preview "$DOCS_DIR"
    fi
    ;;
  esac
}

main "$@"
