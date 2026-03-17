#!/usr/bin/env sh
# scripts/lib/langs/gorm.sh - Gorm Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Gorm development prerequisites.
# Examples:
#   check_gorm
check_gorm() {
  log_info "🔍 Checking Gorm environment..."

  # Check for Go (Prerequisite)
  if ! command -v go >/dev/null 2>&1; then
    log_warn "⚠️  Gorm requires Go. Please install it first."
    return 1
  fi

  # Check for Gorm in go.mod
  if [ -f "go.mod" ] && grep -q "gorm.io/gorm" go.mod; then
    log_success "✅ Gorm detected in go.mod."
  else
    log_info "⏭️  Gorm: Skipped (no Gorm dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Gorm setup.
# Examples:
#   install_gorm
install_gorm() {
  log_info "🚀 Gorm setup usually happens via: go get gorm.io/gorm"
  log_info "Checking if gorm is already in environment..."

  if [ -f "go.mod" ] && grep -q "gorm.io/gorm" go.mod; then
    log_success "✅ Gorm is already configured in this project."
  else
    log_info "Gorm not found; dependency addition recommended."
  fi
}
