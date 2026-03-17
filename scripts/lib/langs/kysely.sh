#!/usr/bin/env sh
# scripts/lib/langs/kysely.sh - Kysely Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Kysely development prerequisites.
# Examples:
#   check_kysely
check_kysely() {
  log_info "🔍 Checking Kysely environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Kysely requires Node.js. Please install it first."
    return 1
  fi

  # Check for Kysely in package.json
  if [ -f "package.json" ] && grep -q "\"kysely\"" package.json; then
    log_success "✅ Kysely detected as project dependency."
  else
    log_info "⏭️  Kysely: Skipped (no Kysely dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Kysely setup.
# Examples:
#   install_kysely
install_kysely() {
  log_info "🚀 Kysely setup usually involves: npm install kysely"
  log_info "Checking if Kysely is already in environment..."

  if [ -f "package.json" ] && grep -q "\"kysely\"" package.json; then
    log_success "✅ Kysely is already configured in this project."
  else
    log_info "Kysely not found; dependency addition recommended."
  fi
}
