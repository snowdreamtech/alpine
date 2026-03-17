#!/usr/bin/env sh
# scripts/lib/langs/bazel.sh - Bazel Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Bazel development prerequisites.
# Examples:
#   check_bazel
check_runtime_bazel() {
  log_info "🔍 Checking Bazel environment..."

  # Check for Bazel, Bazelisk or configuration files
  if command -v bazelisk >/dev/null 2>&1; then
    log_success "✅ Bazelisk (Bazel manager) detected."
  elif command -v bazel >/dev/null 2>&1; then
    log_success "✅ Bazel binary detected."
  elif [ -f "WORKSPACE" ] || [ -f "WORKSPACE.bazel" ] || [ -f "MODULE.bazel" ]; then
    log_success "✅ Bazel configuration file detected."
  else
    log_info "⏭️  Bazel: Skipped (no Bazel tools found)"
    return 0
  fi

  return 0
}

# Purpose: Setup Bazelisk (recommended way to use Bazel).
# Examples:
#   install_bazel
install_bazel() {
  log_info "🚀 Setting up Bazelisk..."

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_info "DRY-RUN: npm install -g @bazel/bazelisk"
    return 0
  fi

  if ! npm install -g @bazel/bazelisk; then
    log_warn "⚠️ Failed to install Bazelisk globally."
  else
    log_success "✅ Bazelisk installed successfully."
  fi
}
