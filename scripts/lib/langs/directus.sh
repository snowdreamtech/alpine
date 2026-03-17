#!/usr/bin/env sh
# scripts/lib/langs/directus.sh - Directus Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Directus development prerequisites.
# Examples:
#   check_directus
check_directus() {
  log_info "🔍 Checking Directus environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Directus requires Node.js. Please install it first."
    return 1
  fi

  # Check for Directus in package.json or docker-compose
  if [ -f "package.json" ] && grep -q "\"directus\"" package.json; then
    log_success "✅ Directus detected as project dependency."
  elif [ -f "docker-compose.yml" ] && grep -qi "directus" docker-compose.yml; then
    log_success "✅ Directus detected in docker-compose.yml."
  else
    log_info "⏭️  Directus: Skipped (no Directus dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Directus setup.
# Examples:
#   install_directus
install_directus() {
  log_info "🚀 Directus setup: npx create-directus-project@latest"
  if is_dry_run; then
    log_info "DRY-RUN: npx create-directus-project"
    return 0
  fi
}
