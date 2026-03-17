#!/usr/bin/env sh
# scripts/lib/langs/fastify.sh - Fastify Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Fastify development prerequisites.
# Examples:
#   check_fastify
check_fastify() {
  log_info "🔍 Checking Fastify environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Fastify requires Node.js. Please install it first."
    return 1
  fi

  # Check for fastify-cli or project dependency
  if command -v fastify >/dev/null 2>&1; then
    log_success "✅ Fastify CLI detected."
  elif [ -f "package.json" ] && grep -q "\"fastify\"" package.json; then
    log_success "✅ Fastify detected as project dependency."
  else
    log_info "⏭️  Fastify: Skipped (no Fastify dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Fastify CLI globally.
# Examples:
#   install_fastify
install_fastify() {
  log_info "🚀 Setting up Fastify CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g fastify-cli"
    return 0
  fi

  if ! npm install -g fastify-cli; then
    log_error "❌ Failed to install Fastify CLI."
    exit 1
  fi

  log_success "✅ Fastify CLI installed successfully."
}
