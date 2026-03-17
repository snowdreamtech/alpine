#!/usr/bin/env sh
# scripts/lib/langs/appium.sh - Appium Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Appium development prerequisites.
# Examples:
#   check_appium
check_appium() {
  log_info "🔍 Checking Appium environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Appium requires Node.js. Please install it first."
    return 1
  fi

  # Check for appium binary or library in package.json
  if command -v appium >/dev/null 2>&1; then
    log_success "✅ Appium binary detected."
  elif [ -f "package.json" ] && grep -q "\"appium\"" package.json; then
    log_success "✅ Appium detected as project dependency."
  else
    log_info "⏭️  Appium: Skipped (no Appium tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Appium CLI globally.
# Examples:
#   install_appium
install_appium() {
  log_info "🚀 Setting up Appium CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g appium"
    return 0
  fi

  if ! npm install -g appium; then
    log_warn "⚠️ Failed to install Appium globally. Project-local check recommended."
  else
    log_success "✅ Appium CLI installed successfully."
  fi
}
