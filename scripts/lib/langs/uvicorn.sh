#!/usr/bin/env sh
# scripts/lib/langs/uvicorn.sh - Uvicorn Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Uvicorn development prerequisites.
# Examples:
#   check_uvicorn
check_uvicorn() {
  log_info "🔍 Checking Uvicorn environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  Uvicorn requires Python. Please install it first."
    return 1
  fi

  # Check for uvicorn binary or in configuration
  if command -v uvicorn >/dev/null 2>&1; then
    log_success "✅ Uvicorn binary detected."
  elif [ -f "requirements.txt" ] && grep -q "uvicorn" requirements.txt; then
    log_success "✅ Uvicorn found in requirements.txt."
  else
    log_info "⏭️  Uvicorn: Skipped (no Uvicorn tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Uvicorn.
# Examples:
#   install_uvicorn
install_uvicorn() {
  log_info "🚀 Setting up Uvicorn..."

  if is_dry_run; then
    log_info "DRY-RUN: pip install uvicorn"
    return 0
  fi

  if ! pip install uvicorn; then
    log_warn "⚠️ Failed to install Uvicorn using pip."
  else
    log_success "✅ Uvicorn installed successfully."
  fi
}
