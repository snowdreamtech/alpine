#!/usr/bin/env sh
# scripts/lib/langs/solidstart.sh - SolidStart Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for SolidStart development prerequisites.
# Examples:
#   check_solidstart
check_solidstart() {
  log_info "🔍 Checking SolidStart environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  SolidStart requires Node.js. Please install it first."
    return 1
  fi

  # Check for SolidStart project files
  if [ -f "app.config.ts" ] || [ -f "app.config.js" ]; then
    log_success "✅ SolidStart configuration file detected."
  elif [ -f "package.json" ] && grep -q "\"@solidjs/start\"" package.json; then
    log_success "✅ SolidStart detected as project dependency."
  else
    log_info "⏭️  SolidStart: Skipped (no SolidStart files found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for SolidStart setup.
# Examples:
#   install_solidstart
install_solidstart() {
  log_info "🚀 SolidStart setup usually happens via: npx digit solidjs/templates/app-ts"
  log_info "Checking if solidstart is already in environment..."

  if [ -f "package.json" ] && grep -q "\"@solidjs/start\"" package.json; then
    log_success "✅ SolidStart is already configured in this project."
  else
    log_info "SolidStart not found; initialization recommended."
  fi
}
