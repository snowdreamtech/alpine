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

main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  _COMMAND="setup"
  for _arg in "$@"; do
    case "$_arg" in
    setup | check | sync) _COMMAND="$_arg" ;;
    esac
  done
  parse_common_args "$@"

  log_info "🔧 Environment Configuration Manager ($_COMMAND)...\n"

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
      log_error "Error: .env.example not found in the project root."
      log_info "💡 Ensure you are running this script from the workspace root."
      exit 1
    fi
    if [ ! -f ".env" ]; then
      log_warn ".env not found. Please run 'scripts/env.sh setup' first."
      return
    fi

    log_info "Checking .env for missing keys from .env.example..."
    _MISSING=0
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
      \#* | '') continue ;;
      esac

      _KEY=$(echo "$line" | cut -d'=' -f1 | sed 's/[[:space:]]*$//')
      if ! grep -q "^$_KEY=" ".env" && ! grep -q "^$_KEY =" ".env"; then
        log_warn "Missing key: $_KEY"
        _MISSING=$((_MISSING + 1))
      fi
    done <".env.example"

    if [ "$_MISSING" -eq 0 ]; then
      log_success "All environment keys are present."
    else
      log_error "Validation failed: $_MISSING keys missing from .env"
      log_info "💡 Run 'scripts/env.sh sync' to add missing keys (interactive)."
      exit 1
    fi
  }

  run_sync() {
    if [ ! -f ".env.example" ]; then
      log_error "Error: .env.example not found."
      exit 1
    fi
    if [ ! -f ".env" ]; then
      log_info "Initializing .env from .env.example..."
      cp ".env.example" ".env"
    fi

    log_info "Syncing missing keys from .env.example to .env..."
    _ADDED=0
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
      \#* | '') continue ;;
      esac

      _KEY=$(echo "$line" | cut -d'=' -f1 | sed 's/[[:space:]]*$//')
      if ! grep -q "^$_KEY=" ".env" && ! grep -q "^$_KEY =" ".env"; then
        if [ "$DRY_RUN" -eq 1 ]; then
          log_info "DRY-RUN: Would add $_KEY to .env"
        else
          printf "Missing key found: %b%s%b. Add to .env? (y/N): " "${YELLOW}" "$_KEY" "${NC}"
          read -r _CONFIRM
          case "$_CONFIRM" in
          [yY]*)
            echo "$line" >>.env
            log_success "Added $_KEY"
            _ADDED=$((_ADDED + 1))
            ;;
          *) log_info "Skipped $_KEY" ;;
          esac
        fi
      fi
    done <".env.example"
    log_success "Sync complete. $_ADDED keys added."
  }

  case "$_COMMAND" in
  setup) run_setup ;;
  check) run_check ;;
  sync) run_sync ;;
  esac

  log_success "\n✨ Environment management task complete."
}

main "$@"
