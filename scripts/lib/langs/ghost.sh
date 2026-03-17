#!/usr/bin/env sh
# scripts/lib/langs/ghost.sh - Ghost Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Ghost development prerequisites.
# Examples:
#   check_ghost
check_ghost() {
  log_info "🔍 Checking Ghost environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Ghost requires Node.js. Please install it first."
    return 1
  fi

  # Check for Ghost-CLI or configuration files
  if command -v ghost >/dev/null 2>&1; then
    log_success "✅ Ghost-CLI detected."
  elif [ -f "config.development.json" ] || [ -f "config.production.json" ]; then
    log_success "✅ Ghost configuration file detected."
  else
    log_info "⏭️  Ghost: Skipped (no Ghost tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Ghost-CLI globally.
# Examples:
#   install_ghost
install_ghost() {
  log_info "🚀 Setting up Ghost-CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g ghost-cli"
    return 0
  fi

  if ! npm install -g ghost-cli; then
    log_warn "⚠️ Failed to install Ghost-CLI globally."
  else
    log_success "✅ Ghost-CLI installed successfully."
  fi
}
