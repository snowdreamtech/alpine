#!/usr/bin/env sh
# scripts/lib/langs/gunicorn.sh - Gunicorn Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Gunicorn development prerequisites.
# Examples:
#   check_gunicorn
check_gunicorn() {
  log_info "🔍 Checking Gunicorn environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  Gunicorn requires Python. Please install it first."
    return 1
  fi

  # Check for gunicorn binary or in configuration
  if command -v gunicorn >/dev/null 2>&1; then
    log_success "✅ Gunicorn binary detected."
  elif [ -f "requirements.txt" ] && grep -q "gunicorn" requirements.txt; then
    log_success "✅ Gunicorn found in requirements.txt."
  else
    log_info "⏭️  Gunicorn: Skipped (no Gunicorn tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Gunicorn.
# Examples:
#   install_gunicorn
install_gunicorn() {
  log_info "🚀 Setting up Gunicorn..."

  if is_dry_run; then
    log_info "DRY-RUN: pip install gunicorn"
    return 0
  fi

  if ! pip install gunicorn; then
    log_warn "⚠️ Failed to install Gunicorn using pip."
  else
    log_success "✅ Gunicorn installed successfully."
  fi
}
