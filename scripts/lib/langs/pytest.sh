#!/usr/bin/env sh
# scripts/lib/langs/pytest.sh - Pytest Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Pytest development prerequisites.
# Examples:
#   check_pytest
check_pytest() {
  log_info "🔍 Checking Pytest environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  Pytest requires Python. Please install it first."
    return 1
  fi

  # Check for pytest binary or configuration files
  if command -v pytest >/dev/null 2>&1; then
    log_success "✅ Pytest binary detected."
  elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] && grep -q "tool.pytest" pyproject.toml; then
    log_success "✅ Pytest configuration detected."
  elif [ -f "requirements.txt" ] && grep -q "pytest" requirements.txt; then
    log_success "✅ Pytest found in requirements.txt."
  else
    log_info "⏭️  Pytest: Skipped (no Pytest tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Pytest.
# Examples:
#   install_pytest
install_pytest() {
  log_info "🚀 Setting up Pytest..."

  if is_dry_run; then
    log_info "DRY-RUN: pip install pytest"
    return 0
  fi

  if ! pip install pytest; then
    log_warn "⚠️ Failed to install Pytest using pip."
  else
    log_success "✅ Pytest installed successfully."
  fi
}
