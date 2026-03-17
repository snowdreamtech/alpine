#!/usr/bin/env sh
# scripts/lib/langs/react-native.sh - React Native Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for React Native development prerequisites.
# Examples:
#   check_react_native
check_react_native() {
  log_info "🔍 Checking React Native environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  React Native requires Node.js. Please install it first."
    return 1
  fi

  # Check for react-native-cli or project dependency
  if command -v react-native >/dev/null 2>&1; then
    log_success "✅ React Native CLI detected."
  elif [ -f "package.json" ] && grep -q "\"react-native\"" package.json; then
    log_success "✅ React Native detected as project dependency."
  else
    log_info "⏭️  React Native: Skipped (no React Native dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs React Native CLI globally.
# Examples:
#   install_react_native
install_react_native() {
  log_info "🚀 Setting up React Native CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g react-native-cli"
    return 0
  fi

  if ! npm install -g react-native-cli; then
    log_error "❌ Failed to install React Native CLI."
    exit 1
  fi

  log_success "✅ React Native CLI installed successfully."
}
