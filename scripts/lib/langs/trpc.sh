#!/usr/bin/env sh
# scripts/lib/langs/trpc.sh - tRPC Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for tRPC development prerequisites.
# Examples:
#   check_trpc
check_trpc() {
  log_info "🔍 Checking tRPC environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  tRPC requires Node.js. Please install it first."
    return 1
  fi

  # Check for tRPC in package.json
  if [ -f "package.json" ] && grep -q "\"@trpc/server\"" package.json; then
    log_success "✅ tRPC detected as project dependency."
  else
    log_info "⏭️  tRPC: Skipped (no tRPC dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for tRPC setup.
# Examples:
#   install_trpc
install_trpc() {
  log_info "🚀 tRPC setup usually involves: npm install @trpc/server @trpc/client zod"
  log_info "Checking if tRPC is already in environment..."

  if [ -f "package.json" ] && grep -q "\"@trpc/server\"" package.json; then
    log_success "✅ tRPC is already configured in this project."
  else
    log_info "tRPC not found; dependency addition recommended."
  fi
}
