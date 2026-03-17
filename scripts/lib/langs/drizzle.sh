#!/usr/bin/env sh
# scripts/lib/langs/drizzle.sh - Drizzle Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Drizzle development prerequisites.
# Examples:
#   check_drizzle
check_drizzle() {
  log_info "🔍 Checking Drizzle environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Drizzle requires Node.js. Please install it first."
    return 1
  fi

  # Check for drizzle-kit or project dependency
  if command -v drizzle-kit >/dev/null 2>&1; then
    log_success "✅ Drizzle Kit detected."
  elif [ -f "package.json" ] && grep -q "\"drizzle-orm\"" package.json; then
    log_success "✅ Drizzle ORM detected as project dependency."
  else
    log_info "⏭️  Drizzle: Skipped (no Drizzle dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Drizzle Kit globally.
# Examples:
#   install_drizzle
install_drizzle() {
  log_info "🚀 Setting up Drizzle Kit..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g drizzle-kit"
    return 0
  fi

  if ! npm install -g drizzle-kit; then
    log_error "❌ Failed to install Drizzle Kit."
    exit 1
  fi

  log_success "✅ Drizzle Kit installed successfully."
}
