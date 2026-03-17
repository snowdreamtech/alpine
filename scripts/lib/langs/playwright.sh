#!/usr/bin/env sh
# scripts/lib/langs/playwright.sh - Playwright Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Playwright development prerequisites.
# Examples:
#   check_playwright
check_playwright() {
  log_info "🔍 Checking Playwright environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Playwright requires Node.js. Please install it first."
    return 1
  fi

  # Check for playwright command or project dependency
  if command -v playwright >/dev/null 2>&1; then
    log_success "✅ Playwright binary detected."
  elif [ -f "package.json" ] && grep -q "\"@playwright/test\"" package.json; then
    log_success "✅ Playwright detected as project dependency."
  else
    log_info "⏭️  Playwright: Skipped (no Playwright dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Playwright globally/project-wide.
# Examples:
#   install_playwright
install_playwright() {
  log_info "🚀 Setting up Playwright..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g playwright && npx playwright install"
    return 0
  fi

  if ! npm install -g playwright; then
    log_error "❌ Failed to install Playwright CLI."
    exit 1
  fi

  if ! npx playwright install --with-deps; then
    log_error "❌ Failed to install Playwright browsers."
    exit 1
  fi

  log_success "✅ Playwright setup successfully."
}
