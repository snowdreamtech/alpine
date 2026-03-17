#!/usr/bin/env sh
# scripts/lib/langs/express.sh - Express Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Express development prerequisites.
# Examples:
#   check_express
check_express() {
  log_info "🔍 Checking Express environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Express requires Node.js. Please install it first."
    return 1
  fi

  # Check for express-generator or project dependency
  if command -v express >/dev/null 2>&1; then
    log_success "✅ Express Generator detected."
  elif [ -f "package.json" ] && grep -q "\"express\"" package.json; then
    log_success "✅ Express detected as project dependency."
  else
    log_info "⏭️  Express: Skipped (no Express dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Express generator globally.
# Examples:
#   install_express
install_express() {
  log_info "🚀 Setting up Express Generator..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g express-generator"
    return 0
  fi

  if ! npm install -g express-generator; then
    log_error "❌ Failed to install Express Generator."
    exit 1
  fi

  log_success "✅ Express Generator installed successfully."
}
