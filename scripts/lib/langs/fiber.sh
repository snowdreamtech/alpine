#!/usr/bin/env sh
# scripts/lib/langs/fiber.sh - Fiber Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Fiber development prerequisites.
# Examples:
#   check_fiber
check_fiber() {
  log_info "🔍 Checking Fiber environment..."

  # Check for Go (Prerequisite)
  if ! command -v go >/dev/null 2>&1; then
    log_warn "⚠️  Fiber requires Go. Please install it first."
    return 1
  fi

  # Check for fiber in go.mod or project
  if [ -f "go.mod" ] && grep -q "github.com/gofiber/fiber" go.mod; then
    log_success "✅ Fiber detected in go.mod."
  else
    log_info "⏭️  Fiber: Skipped (no Fiber dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Fiber setup.
# Examples:
#   install_fiber
install_fiber() {
  log_info "🚀 Fiber setup usually happens via: go get github.com/gofiber/fiber/v2"
  log_info "Checking if fiber is already in project..."

  if [ -f "go.mod" ] && grep -q "github.com/gofiber/fiber" go.mod; then
    log_success "✅ Fiber is already present."
  else
    log_info "Fiber not found in go.mod."
  fi
}
