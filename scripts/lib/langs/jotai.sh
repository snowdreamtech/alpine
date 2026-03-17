#!/usr/bin/env sh
# scripts/lib/langs/jotai.sh - Jotai Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Jotai development prerequisites.
# Examples:
#   check_jotai
check_jotai() {
  log_info "🔍 Checking Jotai environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Jotai requires Node.js. Please install it first."
    return 1
  fi

  # Check for Jotai in package.json
  if [ -f "package.json" ] && grep -q "\"jotai\"" package.json; then
    log_success "✅ Jotai detected as project dependency."
  else
    log_info "⏭️  Jotai: Skipped (no Jotai dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Jotai setup.
# Examples:
#   install_jotai
install_jotai() {
  log_info "🚀 Jotai setup: npm install jotai"
  log_info "Checking if jotai is already in environment..."

  if [ -f "package.json" ] && grep -q "\"jotai\"" package.json; then
    log_success "✅ Jotai is already configured in this project."
  else
    log_info "Jotai not found; dependency addition recommended."
  fi
}
