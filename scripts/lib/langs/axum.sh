#!/usr/bin/env sh
# scripts/lib/langs/axum.sh - Axum Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Axum development prerequisites.
# Examples:
#   check_axum
check_axum() {
  log_info "🔍 Checking Axum environment..."

  # Check for Rust (Prerequisite)
  if ! command -v cargo >/dev/null 2>&1; then
    log_warn "⚠️  Axum requires Rust and Cargo. Please install them first."
    return 1
  fi

  # Check for Axum in Cargo.toml
  if [ -f "Cargo.toml" ] && grep -q "\"axum\"" Cargo.toml; then
    log_success "✅ Axum detected in Cargo.toml."
  else
    log_info "⏭️  Axum: Skipped (no Axum dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Axum setup.
# Examples:
#   install_axum
install_axum() {
  log_info "🚀 Axum setup usually happens via: cargo add axum tokio --features full"
  log_info "Checking if axum is already in environment..."

  if [ -f "Cargo.toml" ] && grep -q "\"axum\"" Cargo.toml; then
    log_success "✅ Axum is already configured in this project."
  else
    log_info "Axum not found; dependency addition recommended."
  fi
}
