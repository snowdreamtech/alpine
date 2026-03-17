#!/usr/bin/env sh
# scripts/lib/langs/strapi.sh - Strapi Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Strapi development prerequisites.
# Examples:
#   check_strapi
check_strapi() {
  log_info "🔍 Checking Strapi environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Strapi requires Node.js. Please install it first."
    return 1
  fi

  # Check for Strapi in package.json
  if [ -f "package.json" ] && grep -q "\"@strapi/strapi\"" package.json; then
    log_success "✅ Strapi detected as project dependency."
  elif [ -d "src/admin" ] && [ -d "src/api" ]; then
    log_success "✅ Strapi project structure detected."
  else
    log_info "⏭️  Strapi: Skipped (no Strapi files found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Strapi setup.
# Examples:
#   install_strapi
install_strapi() {
  log_info "🚀 Strapi setup usually happens via: npx create-strapi-app@latest my-project"
  log_info "Checking if strapi is already in environment..."

  if [ -f "package.json" ] && grep -q "\"@strapi/strapi\"" package.json; then
    log_success "✅ Strapi is already configured in this project."
  else
    log_info "Strapi not found; initialization recommended."
  fi
}
