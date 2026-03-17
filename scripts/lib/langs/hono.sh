#!/usr/bin/env sh
# scripts/lib/langs/hono.sh - Hono Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Hono development prerequisites.
# Examples:
#   check_hono
check_hono() {
  log_info "🔍 Checking Hono environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Hono requires Node.js. Please install it first."
    return 1
  fi

  # Check for hono in package.json (usually integrated, no global CLI needed for basic use but we can check project)
  if [ -f "package.json" ] && grep -q "\"hono\"" package.json; then
    log_success "✅ Hono detected as project dependency."
  else
    log_info "⏭️  Hono: Skipped (no Hono dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Hono setup (usually via create-hono).
# Examples:
#   install_hono
install_hono() {
  log_info "🚀 Hono initialization usually happens via: npm create hono@latest"
  log_info "Checking if hono is already in project..."

  if [ -f "package.json" ] && grep -q "\"hono\"" package.json; then
    log_success "✅ Hono is already present."
  else
    log_info "Hono is not tracked globally; use project-level installation."
  fi
}
