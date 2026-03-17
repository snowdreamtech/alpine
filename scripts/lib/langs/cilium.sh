#!/usr/bin/env sh
# scripts/lib/langs/cilium.sh - Cilium Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Cilium development prerequisites.
# Examples:
#   check_cilium
check_runtime_cilium() {
  log_info "🔍 Checking Cilium environment..."

  # Check for Cilium CLI binary
  if command -v cilium >/dev/null 2>&1; then
    log_success "✅ Cilium CLI binary detected."
  elif command -v hubble >/dev/null 2>&1; then
    log_success "✅ Hubble (Cilium observability) detected."
  else
    log_info "⏭️  Cilium: Skipped (no Cilium tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Cilium CLI.
# Examples:
#   install_cilium
install_cilium() {
  log_info "🚀 Setting up Cilium CLI..."

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_info "DRY-RUN: curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-darwin-amd64.tar.gz"
    return 0
  fi

  log_info "Please install Cilium CLI manually following official docs for your OS."
}
