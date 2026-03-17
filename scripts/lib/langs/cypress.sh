#!/usr/bin/env sh
# scripts/lib/langs/cypress.sh - Cypress Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Cypress development prerequisites.
# Examples:
#   check_cypress
check_cypress() {
  log_info "🔍 Checking Cypress environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Cypress requires Node.js. Please install it first."
    return 1
  fi

  # Check for cypress command or project dependency
  if command -v cypress >/dev/null 2>&1; then
    log_success "✅ Cypress binary detected."
  elif [ -f "package.json" ] && grep -q "\"cypress\"" package.json; then
    log_success "✅ Cypress detected as project dependency."
  else
    log_info "⏭️  Cypress: Skipped (no Cypress dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Cypress globally/project-wide.
# Examples:
#   install_cypress
install_cypress() {
  log_info "🚀 Setting up Cypress..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g cypress"
    return 0
  fi

  if ! npm install -g cypress; then
    log_error "❌ Failed to install Cypress CLI."
    exit 1
  fi

  log_success "✅ Cypress setup successfully."
}
