#!/usr/bin/env sh
# scripts/lib/langs/sequelize.sh - Sequelize Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Sequelize development prerequisites.
# Examples:
#   check_sequelize
check_sequelize() {
  log_info "🔍 Checking Sequelize environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Sequelize requires Node.js. Please install it first."
    return 1
  fi

  # Check for Sequelize binary or in package.json
  if command -v sequelize >/dev/null 2>&1; then
    log_success "✅ Sequelize CLI detected."
  elif [ -f "package.json" ] && grep -q "\"sequelize\"" package.json; then
    log_success "✅ Sequelize detected as project dependency."
  else
    log_info "⏭️  Sequelize: Skipped (no Sequelize dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Sequelize CLI globally.
# Examples:
#   install_sequelize
install_sequelize() {
  log_info "🚀 Setting up Sequelize CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g sequelize-cli"
    return 0
  fi

  if ! npm install -g sequelize-cli; then
    log_warn "⚠️ Failed to install Sequelize CLI globally."
  else
    log_success "✅ Sequelize CLI installed successfully."
  fi
}
