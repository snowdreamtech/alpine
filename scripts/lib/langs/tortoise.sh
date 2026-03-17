#!/usr/bin/env sh
# scripts/lib/langs/tortoise.sh - Tortoise ORM Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Tortoise ORM development prerequisites.
# Examples:
#   check_tortoise
check_tortoise() {
  log_info "🔍 Checking Tortoise ORM environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  Tortoise ORM requires Python 3. Please install it first."
    return 1
  fi

  # Check for Tortoise ORM in project
  if [ -f "requirements.txt" ] && grep -qi "tortoise-orm" requirements.txt; then
    log_success "✅ Tortoise ORM detected in requirements.txt."
  elif [ -f "pyproject.toml" ] && grep -qi "tortoise-orm" pyproject.toml; then
    log_success "✅ Tortoise ORM detected in pyproject.toml."
  else
    log_info "⏭️  Tortoise ORM: Skipped (no Tortoise ORM dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Tortoise ORM setup.
# Examples:
#   install_tortoise
install_tortoise() {
  log_info "🚀 Tortoise ORM setup usually happens via: pip install tortoise-orm"
  log_info "Checking if tortoise-orm is already in environment..."

  if python3 -c "import tortoise" >/dev/null 2>&1; then
    log_success "✅ Tortoise ORM is already installed in Python environment."
  else
    log_info "Tortoise ORM not found; installation recommended in virtual environment."
  fi
}
