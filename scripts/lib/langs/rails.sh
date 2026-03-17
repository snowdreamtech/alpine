#!/usr/bin/env sh
# scripts/lib/langs/rails.sh - Rails Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Rails development prerequisites.
# Examples:
#   check_rails
check_rails() {
  log_info "🔍 Checking Rails environment..."

  # Check for Ruby (Prerequisite)
  if ! command -v ruby >/dev/null 2>&1; then
    log_warn "⚠️  Rails requires Ruby. Please install it first."
    return 1
  fi

  # Check for rails CLI or project dependency
  if command -v rails >/dev/null 2>&1; then
    log_success "✅ Rails CLI detected."
  elif [ -f "Gemfile" ] && grep -q "gem ['\"]rails['\"]" Gemfile; then
    log_success "✅ Rails detected as project dependency."
  else
    log_info "⏭️  Rails: Skipped (no Rails dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Rails gem globally.
# Examples:
#   install_rails
install_rails() {
  log_info "🚀 Setting up Rails gem..."

  if is_dry_run; then
    log_info "DRY-RUN: gem install rails"
    return 0
  fi

  if ! gem install rails; then
    log_error "❌ Failed to install Rails gem."
    exit 1
  fi

  log_success "✅ Rails gem installed successfully."
}
