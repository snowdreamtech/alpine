#!/usr/bin/env sh
# scripts/lib/langs/actix.sh - Actix Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Actix development prerequisites.
# Examples:
#   check_actix
check_actix() {
  log_info "🔍 Checking Actix environment..."

  # Check for Rust (Prerequisite)
  if ! command -v cargo >/dev/null 2>&1; then
    log_warn "⚠️  Actix requires Rust and Cargo. Please install them first."
    return 1
  fi

  # Check for Actix in Cargo.toml
  if [ -f "Cargo.toml" ] && grep -q "\"actix-web\"" Cargo.toml; then
    log_success "✅ Actix-web detected in Cargo.toml."
  else
    log_info "⏭️  Actix: Skipped (no Actix dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Actix setup.
# Examples:
#   install_actix
install_actix() {
  log_info "🚀 Actix setup usually happens via: cargo add actix-web"
  log_info "Checking if actix is already in environment..."

  if [ -f "Cargo.toml" ] && grep -q "\"actix-web\"" Cargo.toml; then
    log_success "✅ Actix-web is already configured in this project."
  else
    log_info "Actix not found; dependency addition recommended."
  fi
}
