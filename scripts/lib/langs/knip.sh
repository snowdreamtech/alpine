#!/usr/bin/env sh
# scripts/lib/langs/knip.sh - Knip Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Knip development prerequisites.
# Examples:
#   check_knip
check_knip() {
  log_info "🔍 Checking Knip environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Knip requires Node.js. Please install it first."
    return 1
  fi

  # Check for Knip binary or configuration files
  if command -v knip >/dev/null 2>&1; then
    log_success "✅ Knip binary detected."
  elif [ -f "knip.json" ] || [ -f "knip.jsonc" ] || [ -f "knip.config.ts" ] || [ -f "knip.config.js" ]; then
    log_success "✅ Knip configuration file detected."
  elif [ -f "package.json" ] && grep -q "\"knip\"" package.json; then
    log_success "✅ Knip found in package.json."
  else
    log_info "⏭️  Knip: Skipped (no Knip tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Knip CLI globally.
# Examples:
#   install_knip
install_knip() {
  log_info "🚀 Setting up Knip CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g knip"
    return 0
  fi

  if ! npm install -g knip; then
    log_warn "⚠️ Failed to install Knip globally. Project-local check recommended."
  else
    log_success "✅ Knip CLI installed successfully."
  fi
}
