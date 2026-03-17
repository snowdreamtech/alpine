#!/usr/bin/env sh
# scripts/lib/langs/turborepo.sh - Turborepo Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Turborepo development prerequisites.
# Examples:
#   check_turborepo
check_turborepo() {
  log_info "🔍 Checking Turborepo environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Turborepo requires Node.js. Please install it first."
    return 1
  fi

  # Check for Turborepo binary or configuration files
  if command -v turbo >/dev/null 2>&1; then
    log_success "✅ Turborepo binary detected."
  elif [ -f "turbo.json" ]; then
    log_success "✅ Turborepo configuration file detected."
  elif [ -f "package.json" ] && grep -q "\"turbo\"" package.json; then
    log_success "✅ Turborepo found in package.json."
  else
    log_info "⏭️  Turborepo: Skipped (no Turborepo tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Turborepo CLI globally.
# Examples:
#   install_turborepo
install_turborepo() {
  log_info "🚀 Setting up Turborepo CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g turbo"
    return 0
  fi

  if ! npm install -g turbo; then
    log_warn "⚠️ Failed to install Turborepo globally. Project-local check recommended."
  else
    log_success "✅ Turborepo CLI installed successfully."
  fi
}
