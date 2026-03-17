#!/usr/bin/env sh
# scripts/lib/langs/single-spa.sh - Single-spa Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Single-spa development prerequisites.
# Examples:
#   check_single_spa
check_single_spa() {
  log_info "🔍 Checking Single-spa environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Single-spa requires Node.js. Please install it first."
    return 1
  fi

  # Check for Single-spa binary or in package.json
  if command -v single-spa >/dev/null 2>&1; then
    log_success "✅ Single-spa binary detected."
  elif [ -f "package.json" ] && grep -q "\"single-spa\"" package.json; then
    log_success "✅ Single-spa detected as project dependency."
  else
    log_info "⏭️  Single-spa: Skipped (no Single-spa dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Single-spa globally.
# Examples:
#   install_single_spa
install_single_spa() {
  log_info "🚀 Setting up Single-spa-cli..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g create-single-spa"
    return 0
  fi

  if ! npm install -g create-single-spa; then
    log_warn "⚠️ Failed to install create-single-spa globally."
  else
    log_success "✅ create-single-spa installed successfully."
  fi
}
