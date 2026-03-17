#!/usr/bin/env sh
# scripts/lib/langs/nx.sh - Nx Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Nx development prerequisites.
# Examples:
#   check_nx
check_nx() {
  log_info "🔍 Checking Nx environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Nx requires Node.js. Please install it first."
    return 1
  fi

  # Check for Nx binary or configuration files
  if command -v nx >/dev/null 2>&1; then
    log_success "✅ Nx binary detected."
  elif [ -f "nx.json" ]; then
    log_success "✅ Nx configuration file detected."
  elif [ -f "workspace.json" ]; then
    log_success "✅ Nx workspace.json detected."
  elif [ -f "package.json" ] && grep -q "\"nx\"" package.json; then
    log_success "✅ Nx found in package.json."
  else
    log_info "⏭️  Nx: Skipped (no Nx tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Nx CLI globally.
# Examples:
#   install_nx
install_nx() {
  log_info "🚀 Setting up Nx CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g nx"
    return 0
  fi

  if ! npm install -g nx; then
    log_warn "⚠️ Failed to install Nx globally. Project-local check recommended."
  else
    log_success "✅ Nx CLI installed successfully."
  fi
}
