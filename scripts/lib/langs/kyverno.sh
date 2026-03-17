#!/usr/bin/env sh
# scripts/lib/langs/verno.sh - Kyverno Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Kyverno development prerequisites.
# Examples:
#   check_kyverno
check_kyverno() {
  log_info "🔍 Checking Kyverno environment..."

  # Check for Kyverno CLI
  if command -v kyverno >/dev/null 2>&1; then
    log_success "✅ Kyverno CLI detected."
  elif [ -f "kyverno.yaml" ] || [ -d "charts/kyverno" ]; then
    log_success "✅ Kyverno manifest or chart detected."
  else
    log_info "⏭️  Kyverno: Skipped (no Kyverno tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Kyverno CLI.
# Examples:
#   install_kyverno
install_kyverno() {
  log_info "🚀 Setting up Kyverno CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: brew install kyverno"
    return 0
  fi

  log_info "Please install Kyverno CLI manually or via brew."
}
