#!/usr/bin/env sh
# scripts/lib/langs/kong.sh - Kong Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Kong development prerequisites.
# Examples:
#   check_kong
check_runtime_kong() {
  log_info "🔍 Checking Kong environment..."

  # Check for kong binary or configuration files
  if command -v kong >/dev/null 2>&1; then
    log_success "✅ Kong binary detected."
  elif [ -f "kong.yml" ] || [ -f "kong.conf" ]; then
    log_success "✅ Kong configuration file detected."
  elif [ -f "docker-compose.yml" ] && grep -qi "kong" docker-compose.yml; then
    log_success "✅ Kong detected in docker-compose.yml."
  else
    log_info "⏭️  Kong: Skipped (no Kong tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Kong CLI (Placeholder/Platform-dependent).
# Examples:
#   install_kong
install_kong() {
  log_info "🚀 Kong installation is platform dependent."
  if is_macos; then
    log_info "MacOS detected. Consider: brew install kong"
  else
    log_info "Linux detected. Consider: curl -Lo kong-toolbelt.tar.gz https://github.com/Kong/kong-toolbelt/... "
  fi
}
