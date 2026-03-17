#!/usr/bin/env sh
# scripts/lib/langs/nativescript.sh - NativeScript Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for NativeScript development prerequisites.
# Examples:
#   check_nativescript
check_nativescript() {
  log_info "🔍 Checking NativeScript environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  NativeScript requires Node.js. Please install it first."
    return 1
  fi

  # Check for ns (NativeScript CLI) or project files
  if command -v ns >/dev/null 2>&1 || command -v tns >/dev/null 2>&1; then
    log_success "✅ NativeScript CLI detected."
  elif [ -f "nsconfig.json" ] || [ -f "nativescript.config.ts" ]; then
    log_success "✅ NativeScript configuration file detected."
  else
    log_info "⏭️  NativeScript: Skipped (no NativeScript files found)"
    return 0
  fi

  return 0
}

# Purpose: Installs NativeScript CLI globally.
# Examples:
#   install_nativescript
install_nativescript() {
  log_info "🚀 Setting up NativeScript CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g nativescript"
    return 0
  fi

  if ! npm install -g nativescript; then
    log_error "❌ Failed to install NativeScript CLI."
    exit 1
  fi

  log_success "✅ NativeScript CLI installed successfully."
}
