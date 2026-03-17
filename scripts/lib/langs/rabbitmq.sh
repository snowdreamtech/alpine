#!/usr/bin/env sh
# scripts/lib/langs/rabbitmq.sh - RabbitMQ Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for RabbitMQ development prerequisites.
# Examples:
#   check_rabbitmq
check_rabbitmq() {
  log_info "🔍 Checking RabbitMQ environment..."

  # Check for RabbitMQ binary or related files
  if command -v rabbitmqctl >/dev/null 2>&1 || command -v rabbitmq-server >/dev/null 2>&1; then
    log_success "✅ RabbitMQ binaries detected."
  elif [ -f "docker-compose.yml" ] && grep -qi "rabbitmq" docker-compose.yml; then
    log_success "✅ RabbitMQ detected in docker-compose.yml."
  else
    log_info "⏭️  RabbitMQ: Skipped (no RabbitMQ tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs RabbitMQ (Placeholder/Platform-dependent).
# Examples:
#   install_rabbitmq
install_rabbitmq() {
  log_info "🚀 RabbitMQ installation is platform dependent."
  if is_macos; then
    log_info "MacOS detected. Consider: brew install rabbitmq"
  else
    log_info "Linux detected. Consider: apt install rabbitmq-server"
  fi
}
