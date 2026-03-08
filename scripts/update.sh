#!/bin/sh
# scripts/update.sh - Tooling Update Manager
# Standardizes updating of global and project tools (pnpm, pre-commit, brew, etc.).

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# ── Configuration ────────────────────────────────────────────────────────────

# Help Message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Standardizes updating of global and project tools.

Options:
  --dry-run        Preview updates without applying them.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# 2. Argument Parsing
parse_common_args "$@"

log_info "🔄 Starting Tooling Update Manager...\n"

run_update() {
  _CMD="$1"
  _DESC="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would run $_DESC [$_CMD]"
  else
    log_info "Updating $_DESC..."
    # shellcheck disable=SC2086
    eval $_CMD
  fi
}

# 3. Core Package Managers
if command -v "$NPM" >/dev/null 2>&1; then
  if [ "$NPM" = "pnpm" ]; then
    # Intelligent pnpm update: detects if managed by corepack
    if command -v corepack >/dev/null 2>&1 && pnpm self-update --help 2>&1 | grep -q "corepack" >/dev/null 2>&1; then
      # Note: corepack doesn't allow self-update, use corepack prepare
      run_update "corepack prepare pnpm@latest --activate" "pnpm (via corepack)"
    else
      # Attempt self-update, fallback to corepack if it fails with the specific error
      if [ "$DRY_RUN" -eq 1 ]; then
        log_info "DRY-RUN: Would run pnpm self-update"
      else
        log_info "Updating pnpm (self-update)..."
        if ! pnpm self-update 2>&1 | grep -q "ERR_PNPM_CANT_SELF_UPDATE_IN_COREPACK"; then
          log_success "pnpm updated successfully."
        else
          log_warn "pnpm is managed by corepack. Switching to corepack update..."
          run_update "corepack prepare pnpm@latest --activate" "pnpm (via corepack)"
        fi
      fi
    fi
  else
    run_update "$NPM self-update" "$NPM (self-update)"
  fi
fi

if command -v brew >/dev/null 2>&1; then
  run_update "brew update" "Homebrew"
fi

# 4. Git Hooks & Tooling
if [ -x "$VENV/bin/pre-commit" ]; then
  run_update "$VENV/bin/pre-commit autoupdate" "pre-commit hooks"
elif command -v pre-commit >/dev/null 2>&1; then
  run_update "pre-commit autoupdate" "pre-commit hooks"
fi

# Optional: run npm update if defined
run_npm_script "update"

log_success "\n✨ Update process finished."
