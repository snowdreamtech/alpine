#!/usr/bin/env sh
# scripts/lib/langs/storybook.sh - Storybook Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Storybook development prerequisites.
# Examples:
#   check_storybook
check_storybook() {
  log_info "🔍 Checking Storybook environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Storybook requires Node.js. Please install it first."
    return 1
  fi

  # Check for Storybook project files
  if [ -d ".storybook" ]; then
    log_success "✅ Storybook configuration directory detected."
  elif [ -f "package.json" ] && grep -q "\"storybook\"" package.json; then
    log_success "✅ Storybook detected as project dependency."
  else
    log_info "⏭️  Storybook: Skipped (no Storybook files found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Storybook setup.
# Examples:
#   install_storybook
install_storybook() {
  log_info "🚀 Storybook setup usually happens via: npx storybook init"
  log_info "Checking if storybook is already in environment..."

  if [ -f "package.json" ] && grep -q "\"storybook\"" package.json; then
    log_success "✅ Storybook is already configured in this project."
  else
    log_info "Storybook not found; initialization recommended."
  fi
}
