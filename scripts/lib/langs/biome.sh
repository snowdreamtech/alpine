#!/usr/bin/env sh
# scripts/lib/langs/biome.sh - Biome Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Biome development prerequisites.
# Examples:
#   check_biome
check_biome() {
  log_info "🔍 Checking Biome environment..."

  # Check for Node.js (Prerequisite)
  if ! command -v node >/dev/null 2>&1; then
    log_warn "⚠️  Biome requires Node.js. Please install it first."
    return 1
  fi

  # Check for Biome binary or configuration files
  if command -v biome >/dev/null 2>&1; then
    log_success "✅ Biome binary detected."
  elif [ -f "biome.json" ]; then
    log_success "✅ Biome configuration file detected."
  elif [ -f "package.json" ] && grep -q "\"@biomejs/biome\"" package.json; then
    log_success "✅ Biome found in package.json."
  else
    log_info "⏭️  Biome: Skipped (no Biome tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Biome CLI globally.
# Examples:
#   install_biome
install_biome() {
  log_info "🚀 Setting up Biome CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g @biomejs/biome"
    return 0
  fi

  if ! npm install -g @biomejs/biome; then
    log_warn "⚠️ Failed to install Biome globally. Project-local check recommended."
  else
    log_success "✅ Biome CLI installed successfully."
  fi
}
