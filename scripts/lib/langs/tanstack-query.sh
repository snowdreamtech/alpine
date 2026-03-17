#!/usr/bin/env sh
# scripts/lib/langs/tanstack-query.sh - TanStack Query Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for TanStack Query development prerequisites.
# Examples:
#   check_tanstack_query
check_tanstack_query() {
  log_info "🔍 Checking TanStack Query environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  TanStack Query requires Node.js. Please install it first."
    return 1
  fi

  # Check for TanStack Query in package.json
  if [ -f "package.json" ] && (grep -q "\"@tanstack/react-query\"" package.json || grep -q "\"@tanstack/vue-query\"" package.json || grep -q "\"@tanstack/svelte-query\"" package.json); then
    log_success "✅ TanStack Query detected as project dependency."
  else
    log_info "⏭️  TanStack Query: Skipped (no TanStack Query dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for TanStack Query setup.
# Examples:
#   install_tanstack_query
install_tanstack_query() {
  log_info "🚀 TanStack Query setup: npm install @tanstack/react-query"
  log_info "Checking if tanstack-query is already in environment..."

  if [ -f "package.json" ] && grep -q "\"@tanstack/.*-query\"" package.json; then
    log_success "✅ TanStack Query is already configured in this project."
  else
    log_info "TanStack Query not found; dependency addition recommended."
  fi
}
