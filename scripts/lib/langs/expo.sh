#!/usr/bin/env sh
# scripts/lib/langs/expo.sh - Expo Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Expo development prerequisites.
# Examples:
#   check_expo
check_expo() {
  log_info "🔍 Checking Expo environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Expo requires Node.js. Please install it first."
    return 1
  fi

  # Check for expo-cli or project dependency
  if command -v expo >/dev/null 2>&1; then
    log_success "✅ Expo CLI detected."
  elif [ -f "package.json" ] && grep -q "\"expo\"" package.json; then
    log_success "✅ Expo detected as project dependency."
  else
    log_info "⏭️  Expo: Skipped (no Expo dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Expo CLI globally.
# Examples:
#   install_expo
install_expo() {
  log_info "🚀 Setting up Expo CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g expo-cli"
    return 0
  fi

  if ! npm install -g expo-cli; then
    log_error "❌ Failed to install Expo CLI."
    exit 1
  fi

  log_success "✅ Expo CLI installed successfully."
}
