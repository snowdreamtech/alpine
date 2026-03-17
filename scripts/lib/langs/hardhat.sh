#!/usr/bin/env sh
# scripts/lib/langs/hardhat.sh - Hardhat Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Hardhat development prerequisites.
# Examples:
#   check_hardhat
check_hardhat() {
  log_info "🔍 Checking Hardhat environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Hardhat requires Node.js. Please install it first."
    return 1
  fi

  # Check for Hardhat binary or configuration files
  if command -v hardhat >/dev/null 2>&1; then
    log_success "✅ Hardhat binary detected."
  elif [ -f "hardhat.config.ts" ] || [ -f "hardhat.config.js" ]; then
    log_success "✅ Hardhat configuration file detected."
  elif [ -f "package.json" ] && grep -q "\"hardhat\"" package.json; then
    log_success "✅ Hardhat found in package.json."
  else
    log_info "⏭️  Hardhat: Skipped (no Hardhat tools found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Hardhat setup.
# Examples:
#   install_hardhat
install_hardhat() {
  log_info "🚀 Hardhat setup: npx hardhat"
  if is_dry_run; then
    log_info "DRY-RUN: npx hardhat"
    return 0
  fi
}
