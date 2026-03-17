#!/usr/bin/env sh
# scripts/lib/langs/gin.sh - Gin Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Gin development prerequisites.
# Examples:
#   check_gin
check_gin() {
  log_info "🔍 Checking Gin environment..."

  # Check for Go (Prerequisite)
  if ! command -v go >/dev/null 2>&1; then
    log_warn "⚠️  Gin requires Go. Please install it first."
    return 1
  fi

  # Check for gin in go.mod or project
  if [ -f "go.mod" ] && grep -q "github.com/gin-gonic/gin" go.mod; then
    log_success "✅ Gin detected in go.mod."
  else
    log_info "⏭️  Gin: Skipped (no Gin dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Gin setup.
# Examples:
#   install_gin
install_gin() {
  log_info "🚀 Gin setup usually happens via: go get -u github.com/gin-gonic/gin"
  log_info "Checking if gin is already in project..."

  if [ -f "go.mod" ] && grep -q "github.com/gin-gonic/gin" go.mod; then
    log_success "✅ Gin is already present."
  else
    log_info "Gin not found in go.mod."
  fi
}
