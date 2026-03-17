#!/usr/bin/env sh
# scripts/lib/langs/phoenix.sh - Phoenix Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Phoenix development prerequisites.
# Examples:
#   check_phoenix
check_phoenix() {
  log_info "🔍 Checking Phoenix environment..."

  # Check for Elixir (Prerequisite)
  if ! command -v elixir >/dev/null 2>&1; then
    log_warn "⚠️  Phoenix requires Elixir. Please install it first."
    return 1
  fi

  # Check for Phoenix in mix.exs
  if [ -f "mix.exs" ] && grep -q ":phoenix" mix.exs; then
    log_success "✅ Phoenix detected in mix.exs."
  else
    log_info "⏭️  Phoenix: Skipped (no Phoenix dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Phoenix setup.
# Examples:
#   install_phoenix
install_phoenix() {
  log_info "🚀 Phoenix setup usually happens via: mix phx.new my_app"
  log_info "Checking if phoenix is already in environment..."

  if [ -f "mix.exs" ] && grep -q ":phoenix" mix.exs; then
    log_success "✅ Phoenix is already configured in this project."
  else
    log_info "Phoenix not found; initialization recommended."
  fi
}
