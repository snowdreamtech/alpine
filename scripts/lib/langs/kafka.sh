#!/usr/bin/env sh
# scripts/lib/langs/kafka.sh - Kafka Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Kafka development prerequisites.
# Examples:
#   check_kafka
check_kafka() {
  log_info "🔍 Checking Kafka environment..."

  # Check for Kafka binary or related files
  if command -v kafka-topics >/dev/null 2>&1 || command -v kafka-server-start >/dev/null 2>&1; then
    log_success "✅ Kafka binaries detected."
  elif [ -f "docker-compose.yml" ] && grep -qi "kafka" docker-compose.yml; then
    log_success "✅ Kafka detected in docker-compose.yml."
  else
    log_info "⏭️  Kafka: Skipped (no Kafka tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Kafka (Placeholder/Platform-dependent).
# Examples:
#   install_kafka
install_kafka() {
  log_info "🚀 Kafka installation is platform dependent."
  if is_macos; then
    log_info "MacOS detected. Consider: brew install kafka"
  else
    log_info "Linux detected. Consider downloading from: https://kafka.apache.org/downloads"
  fi
}
