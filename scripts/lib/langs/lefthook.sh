#!/usr/bin/env sh
# scripts/lib/langs/lefthook.sh - Lefthook Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Lefthook development prerequisites.
# Examples:
#   check_lefthook
check_lefthook() {
  log_info "🔍 Checking Lefthook environment..."

  # Check for Lefthook binary or configuration files
  if command -v lefthook >/dev/null 2>&1; then
    log_success "✅ Lefthook binary detected."
  elif [ -f "lefthook.yml" ] || [ -f "lefthook.yaml" ]; then
    log_success "✅ Lefthook configuration file detected."
  elif [ -f "package.json" ] && grep -q "\"lefthook\"" package.json; then
    log_success "✅ Lefthook found in package.json."
  else
    log_info "⏭️  Lefthook: Skipped (no Lefthook tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Lefthook CLI globally.
# Examples:
#   install_lefthook
install_lefthook() {
  log_info "🚀 Setting up Lefthook CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: npm install -g lefthook"
    return 0
  fi

  if ! npm install -g lefthook; then
    log_warn "⚠️ Failed to install Lefthook globally. Project-local check recommended."
  else
    log_success "✅ Lefthook CLI installed successfully."
  fi
}
