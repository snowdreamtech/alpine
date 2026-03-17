#!/usr/bin/env sh
# scripts/lib/langs/typesense.sh - Typesense Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Typesense development prerequisites.
# Examples:
#   check_typesense
check_typesense() {
  log_info "🔍 Checking Typesense environment..."

  # Check for Typesense binary or configuration files
  if command -v typesense-server >/dev/null 2>&1; then
    log_success "✅ Typesense server binary detected."
  elif [ -f "docker-compose.yml" ] && grep -qi "typesense" docker-compose.yml; then
    log_success "✅ Typesense detected in docker-compose.yml."
  else
    log_info "⏭️  Typesense: Skipped (no Typesense tools found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Typesense setup.
# Examples:
#   install_typesense
install_typesense() {
  log_info "🚀 Typesense setup usually involves Docker or system binary."
  if is_dry_run; then
    log_info "DRY-RUN: docker run -d -p 8108:8108 typesense/typesense:0.25.1"
    return 0
  fi
}
