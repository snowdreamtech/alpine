#!/usr/bin/env sh
# scripts/lib/langs/noco-db.sh - NocoDB Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for NocoDB development prerequisites.
# Examples:
#   check_noco_db
check_noco_db() {
  log_info "🔍 Checking NocoDB environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  NocoDB requires Node.js. Please install it first."
    return 1
  fi

  # Check for NocoDB in package.json
  if [ -f "package.json" ] && grep -q "\"nocodb\"" package.json; then
    log_success "✅ NocoDB detected as project dependency."
  elif [ -f "docker-compose.yml" ] && grep -qi "nocodb" docker-compose.yml; then
    log_success "✅ NocoDB detected in docker-compose.yml."
  else
    log_info "⏭️  NocoDB: Skipped (no NocoDB dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for NocoDB setup.
# Examples:
#   install_noco_db
install_noco_db() {
  log_info "🚀 NocoDB setup: npm install nocodb (as library) or use Docker/Npx."
  if is_dry_run; then
    log_info "DRY-RUN: npx nocodb"
    return 0
  fi
}
