#!/usr/bin/env sh
# scripts/lib/langs/semgrep.sh - Semgrep Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Semgrep development prerequisites.
# Examples:
#   check_semgrep
check_runtime_semgrep() {
  log_info "🔍 Checking Semgrep environment..."

  # Check for semgrep binary or configuration files
  if command -v semgrep >/dev/null 2>&1; then
    log_success "✅ Semgrep binary detected."
  elif [ -f ".semgrep.yml" ] || [ -d ".semgrep" ]; then
    log_success "✅ Semgrep configuration detected."
  else
    log_info "⏭️  Semgrep: Skipped (no Semgrep tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Semgrep CLI (Placeholder/Platform-dependent).
# Examples:
#   install_semgrep
install_semgrep() {
  log_info "🚀 Semgrep setup usually happens via: pip install semgrep or brew install semgrep"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_info "DRY-RUN: Skip Semgrep installation."
    return 0
  fi
}
