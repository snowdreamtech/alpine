#!/usr/bin/env sh
# scripts/lib/langs/testcafe.sh - TestCafe Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for TestCafe development prerequisites.
# Examples:
#   check_testcafe
check_testcafe() {
  log_info "🔍 Checking TestCafe environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  TestCafe requires Node.js. Please install it first."
    return 1
  fi

  # Check for TestCafe binary or project files
  if command -v testcafe >/dev/null 2>&1; then
    log_success "✅ TestCafe binary detected."
  elif [ -f "package.json" ] && grep -q "\"testcafe\"" package.json; then
    log_success "✅ TestCafe detected as project dependency."
  else
    log_info "⏭️  TestCafe: Skipped (no TestCafe tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs TestCafe CLI globally.
# Examples:
#   install_testcafe
install_testcafe() {
  log_info "🚀 Setting up TestCafe CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g testcafe"
    return 0
  fi

  if ! npm install -g testcafe; then
    log_warn "⚠️ Failed to install TestCafe globally. Project-local check recommended."
  else
    log_success "✅ TestCafe CLI installed successfully."
  fi
}
