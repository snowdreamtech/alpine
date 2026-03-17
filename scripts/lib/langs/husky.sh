#!/usr/bin/env sh
# scripts/lib/langs/husky.sh - Husky Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Husky development prerequisites.
# Examples:
#   check_husky
check_husky() {
  log_info "🔍 Checking Husky environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Husky requires Node.js. Please install it first."
    return 1
  fi

  # Check for Husky directory or in package.json
  if [ -d ".husky" ]; then
    log_success "✅ .husky directory detected."
  elif [ -f "package.json" ] && grep -q "\"husky\"" package.json; then
    log_success "✅ Husky found in package.json."
  else
    log_info "⏭️  Husky: Skipped (no Husky configuration found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Husky.
# Examples:
#   install_husky
install_husky() {
  log_info "🚀 Setting up Husky..."

  if is_dry_run; then
    log_info "DRY-RUN: npx husky-init && npm install"
    return 0
  fi

  if ! npx -y husky-init; then
    log_warn "⚠️ Failed to initialize Husky."
  else
    log_success "✅ Husky initialized successfully."
  fi
}
