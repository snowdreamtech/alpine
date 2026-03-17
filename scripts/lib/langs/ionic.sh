#!/usr/bin/env sh
# scripts/lib/langs/ionic.sh - Ionic Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Ionic development prerequisites.
# Examples:
#   check_ionic
check_ionic() {
  log_info "🔍 Checking Ionic environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Ionic requires Node.js. Please install it first."
    return 1
  fi

  # Check for ionic-cli or project dependency
  if command -v ionic >/dev/null 2>&1; then
    log_success "✅ Ionic CLI detected."
  elif [ -f "ionic.config.json" ] || ([ -f "package.json" ] && grep -q "\"@ionic/angular\"\|\"@ionic/react\"\|\"@ionic/vue\"" package.json); then
    log_success "✅ Ionic detected as project dependency."
  else
    log_info "⏭️  Ionic: Skipped (no Ionic dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Ionic CLI globally.
# Examples:
#   install_ionic
install_ionic() {
  log_info "🚀 Setting up Ionic CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g @ionic/cli"
    return 0
  fi

  if ! npm install -g @ionic/cli; then
    log_error "❌ Failed to install Ionic CLI."
    exit 1
  fi

  log_success "✅ Ionic CLI installed successfully."
}
