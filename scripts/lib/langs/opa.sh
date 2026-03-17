#!/usr/bin/env sh
# scripts/lib/langs/opa.sh - OPA Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for OPA (Open Policy Agent) development prerequisites.
# Examples:
#   check_opa
check_opa() {
  log_info "🔍 Checking OPA environment..."

  # Check for OPA binary
  if command -v opa >/dev/null 2>&1; then
    log_success "✅ OPA binary detected."
  elif [ -f "*.rego" ] || find . -maxdepth 3 -name "*.rego" -print -quit | grep -q .; then
    log_success "✅ OPA policy files (.rego) detected."
  else
    log_info "⏭️  OPA: Skipped (no OPA tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs OPA binary.
# Examples:
#   install_opa
install_opa() {
  log_info "🚀 Setting up OPA..."

  if is_dry_run; then
    log_info "DRY-RUN: curl -L -o opa https://openpolicyagent.org/downloads/v0.61.0/opa_darwin_amd64"
    return 0
  fi

  log_info "Please install OPA manually following official docs for your OS."
}
