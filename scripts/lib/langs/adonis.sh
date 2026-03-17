#!/usr/bin/env sh
# scripts/lib/langs/adonis.sh - AdonisJS Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for AdonisJS development prerequisites.
# Examples:
#   check_adonis
check_adonis() {
  log_info "🔍 Checking AdonisJS environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  AdonisJS requires Node.js. Please install it first."
    return 1
  fi

  # Check for AdonisJS in package.json
  if [ -f "package.json" ] && grep -q "\"@adonisjs/core\"" package.json; then
    log_success "✅ AdonisJS detected as project dependency."
  elif [ -f "ace" ]; then
    log_success "✅ AdonisJS 'ace' CLI detected in root."
  else
    log_info "⏭️  AdonisJS: Skipped (no AdonisJS files found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for AdonisJS setup.
# Examples:
#   install_adonis
install_adonis() {
  log_info "🚀 AdonisJS setup usually happens via: npm init adonisjs@latest"
  log_info "Checking if adonis is already in environment..."

  if [ -f "package.json" ] && grep -q "\"@adonisjs/core\"" package.json; then
    log_success "✅ AdonisJS is already configured in this project."
  else
    log_info "AdonisJS not found; initialization recommended."
  fi
}
