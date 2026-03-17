#!/usr/bin/env sh
# scripts/lib/langs/localstack.sh - LocalStack Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for LocalStack development prerequisites.
# Examples:
#   check_localstack
check_localstack() {
  log_info "🔍 Checking LocalStack environment..."

  # Check for localstack binary or docker-compose
  if command -v localstack >/dev/null 2>&1; then
    log_success "✅ LocalStack CLI detected."
  elif [ -f "docker-compose.yml" ] && grep -qi "localstack" docker-compose.yml; then
    log_success "✅ LocalStack detected in docker-compose.yml."
  else
    log_info "⏭️  LocalStack: Skipped (no LocalStack tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs LocalStack CLI.
# Examples:
#   install_localstack
install_localstack() {
  log_info "🚀 Setting up LocalStack CLI..."

  if is_dry_run; then
    log_info "DRY-RUN: pip install localstack"
    return 0
  fi

  if ! pip install localstack; then
    log_warn "⚠️ Failed to install LocalStack CLI using pip."
  else
    log_success "✅ LocalStack CLI installed successfully."
  fi
}
