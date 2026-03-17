#!/usr/bin/env sh
# scripts/lib/langs/nats.sh - NATS Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for NATS development prerequisites.
# Examples:
#   check_nats
check_runtime_nats() {
  log_info "🔍 Checking NATS environment..."

  # Check for nats binary or related files
  if command -v nats >/dev/null 2>&1 || command -v nats-server >/dev/null 2>&1; then
    log_success "✅ NATS binaries detected."
  elif [ -f "docker-compose.yml" ] && grep -qi "nats" docker-compose.yml; then
    log_success "✅ NATS detected in docker-compose.yml."
  else
    log_info "⏭️  NATS: Skipped (no NATS tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs NATS CLI (Placeholder/Platform-dependent).
# Examples:
#   install_nats
install_nats() {
  log_info "🚀 NATS CLI installation: curl -sfL https://raw.githubusercontent.com/nats-io/natscli/main/install.sh | sh"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_info "DRY-RUN: Skip NATS installation."
    return 0
  fi
}
