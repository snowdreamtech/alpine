#!/bin/sh
# scripts/env.sh - Environment Configuration Manager
# Manages .env files, validation, and template synchronization.
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
Usage: $0 [OPTIONS] [COMMAND]

Manages environment configuration files (.env).

Commands:
  setup            Create .env from .env.example if it doesn't exist.
  check            Validate .env against .env.example (check for missing keys).
  sync             Interactively sync missing keys from .env.example to .env.

Options:
  --dry-run        Preview changes without applying them.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# Argument parsing
COMMAND="setup"
for _arg in "$@"; do
  case "$_arg" in
  setup | check | sync) COMMAND="$_arg" ;;
  esac
done
parse_common_args "$@"

log_info "🔧 Environment Configuration Manager ($COMMAND)...\n"

# 2. Logic implementations
run_setup() {
  if [ ! -f ".env.example" ]; then
    log_warn "Warning: .env.example not found. Skipping setup."
    return
  fi

  if [ -f ".env" ]; then
    log_info ".env already exists. No action needed."
  else
    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "DRY-RUN: Would copy .env.example to .env"
    else
      log_info "Creating .env from .env.example..."
      cp ".env.example" ".env"
      log_success "Successfully created .env"
    fi
  fi
}

run_check() {
  if [ ! -f ".env.example" ]; then
    log_error "Error: .env.example not found."
    exit 1
  fi
  if [ ! -f ".env" ]; then
    log_warn ".env not found. Please run 'scripts/env.sh setup' first."
    return
  fi

  log_info "Checking .env for missing keys from .env.example..."
  MISSING=0
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    case "$line" in
    \#* | '') continue ;;
    esac

    # Extract key
    KEY=$(echo "$line" | cut -d'=' -f1)
    if ! grep -q "^$KEY=" ".env" && ! grep -q "^$KEY =" ".env"; then
      log_warn "Missing key: $KEY"
      MISSING=$((MISSING + 1))
    fi
  done <".env.example"

  if [ "$MISSING" -eq 0 ]; then
    log_success "All environment keys are present."
  else
    log_error "Validation failed: $MISSING keys missing from .env"
    exit 1
  fi
}

case "$COMMAND" in
setup) run_setup ;;
check) run_check ;;
sync)
  log_info "Sync command placeholder. Please manually update .env for now."
  run_check
  ;;
esac

log_success "\n✨ Environment management task complete."
