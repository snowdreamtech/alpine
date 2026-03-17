#!/usr/bin/env sh
# scripts/lib/langs/typeorm.sh - TypeORM Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for TypeORM development prerequisites.
# Examples:
#   check_typeorm
check_typeorm() {
  log_info "🔍 Checking TypeORM environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  TypeORM requires Node.js. Please install it first."
    return 1
  fi

  # Check for typeorm CLI or project dependency
  if command -v typeorm >/dev/null 2>&1; then
    log_success "✅ TypeORM CLI detected."
  elif [ -f "package.json" ] && grep -q "\"typeorm\"" package.json; then
    log_success "✅ TypeORM detected as project dependency."
  else
    log_info "⏭️  TypeORM: Skipped (no TypeORM dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs TypeORM CLI globally.
# Examples:
#   install_typeorm
install_typeorm() {
  log_info "🚀 Setting up TypeORM CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g typeorm"
    return 0
  fi

  if ! npm install -g typeorm; then
    log_error "❌ Failed to install TypeORM CLI."
    exit 1
  fi

  log_success "✅ TypeORM CLI installed successfully."
}
