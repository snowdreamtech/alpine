#!/usr/bin/env sh
# scripts/lib/langs/vector.sh - Vector Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Vector development prerequisites.
# Examples:
#   check_vector
check_runtime_vector() {
  log_info "🔍 Checking Vector environment..."

  # Check for Vector binary or configuration files
  if command -v vector >/dev/null 2>&1; then
    log_success "✅ Vector binary detected."
  elif [ -f "vector.yaml" ] || [ -f "vector.toml" ]; then
    log_success "✅ Vector configuration file detected."
  else
    log_info "⏭️  Vector: Skipped (no Vector tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Vector.
# Examples:
#   install_vector
install_vector() {
  log_info "🚀 Setting up Vector..."

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_info "DRY-RUN: curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | sh"
    return 0
  fi

  if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | sh -s -- -y; then
    log_warn "⚠️ Failed to install Vector automatically."
  else
    log_success "✅ Vector installed successfully."
  fi
}
