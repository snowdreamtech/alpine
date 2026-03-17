#!/usr/bin/env sh
# scripts/lib/langs/tarantool.sh - Tarantool Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Tarantool development prerequisites.
# Examples:
#   check_tarantool
check_runtime_tarantool() {
  log_info "🔍 Checking Tarantool environment..."

  # Check for Tarantool binary
  if command -v tarantool >/dev/null 2>&1; then
    log_success "✅ Tarantool binary detected."
  elif command -v tt >/dev/null 2>&1; then
    log_success "✅ Tarantool (tt) CLI detected."
  elif [ -f "docker-compose.yml" ] && grep -qi "tarantool" docker-compose.yml; then
    log_success "✅ Tarantool detected in docker-compose.yml."
  else
    log_info "⏭️  Tarantool: Skipped (no Tarantool tools found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Tarantool setup.
# Examples:
#   install_tarantool
install_tarantool() {
  log_info "🚀 Tarantool setup usually involves Docker or system binary."
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_info "DRY-RUN: brew install tarantool"
    return 0
  fi
}
