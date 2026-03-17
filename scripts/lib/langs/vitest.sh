#!/usr/bin/env sh
# scripts/lib/langs/vitest.sh - Vitest Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Vitest development prerequisites.
# Examples:
#   check_vitest
check_vitest() {
  log_info "🔍 Checking Vitest environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Vitest requires Node.js. Please install it first."
    return 1
  fi

  # Check for vitest command or project dependency
  if command -v vitest >/dev/null 2>&1; then
    log_success "✅ Vitest binary detected."
  elif [ -f "package.json" ] && grep -q "\"vitest\"" package.json; then
    log_success "✅ Vitest detected as project dependency."
  else
    log_info "⏭️  Vitest: Skipped (no Vitest dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Vitest globally/project-wide.
# Examples:
#   install_vitest
install_vitest() {
  log_info "🚀 Setting up Vitest..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g vitest"
    return 0
  fi

  if ! npm install -g vitest; then
    log_error "❌ Failed to install Vitest CLI."
    exit 1
  fi

  log_success "✅ Vitest setup successfully."
}
