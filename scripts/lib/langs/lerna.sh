#!/usr/bin/env sh
# scripts/lib/langs/lerna.sh - Lerna Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Lerna development prerequisites.
# Examples:
#   check_lerna
check_lerna() {
  log_info "🔍 Checking Lerna environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Lerna requires Node.js. Please install it first."
    return 1
  fi

  # Check for Lerna binary or configuration files
  if command -v lerna >/dev/null 2>&1; then
    log_success "✅ Lerna binary detected."
  elif [ -f "lerna.json" ]; then
    log_success "✅ Lerna configuration file (lerna.json) detected."
  elif [ -f "package.json" ] && grep -q "\"lerna\"" package.json; then
    log_success "✅ Lerna found in package.json."
  else
    log_info "⏭️  Lerna: Skipped (no Lerna tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Lerna globally.
# Examples:
#   install_lerna
install_lerna() {
  log_info "🚀 Setting up Lerna CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g lerna"
    return 0
  fi

  if ! npm install -g lerna; then
    log_warn "⚠️ Failed to install Lerna globally."
  else
    log_success "✅ Lerna installed successfully."
  fi
}
