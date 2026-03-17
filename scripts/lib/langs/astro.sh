#!/usr/bin/env sh
# scripts/lib/langs/astro.sh - Astro Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Astro development prerequisites.
# Examples:
#   check_astro
check_astro() {
  log_info "🔍 Checking Astro environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Astro requires Node.js. Please install it first."
    return 1
  fi

  # Check for astro binary or project files
  if command -v astro >/dev/null 2>&1; then
    log_success "✅ Astro binary detected."
  elif [ -f "astro.config.mjs" ] || [ -f "astro.config.js" ] || [ -f "astro.config.ts" ]; then
    log_success "✅ Astro configuration file detected."
  elif [ -f "package.json" ] && grep -q "\"astro\"" package.json; then
    log_success "✅ Astro detected as project dependency."
  else
    log_info "⏭️  Astro: Skipped (no Astro files found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Astro CLI globally.
# Examples:
#   install_astro
install_astro() {
  log_info "🚀 Setting up Astro CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g astro"
    return 0
  fi

  if ! npm install -g astro; then
    log_error "❌ Failed to install Astro CLI."
    exit 1
  fi

  log_success "✅ Astro CLI installed successfully."
}
