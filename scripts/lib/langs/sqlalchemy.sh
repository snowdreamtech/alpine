#!/usr/bin/env sh
# scripts/lib/langs/sqlalchemy.sh - SQLAlchemy Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for SQLAlchemy development prerequisites.
# Examples:
#   check_sqlalchemy
check_sqlalchemy() {
  log_info "🔍 Checking SQLAlchemy environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  SQLAlchemy requires Python 3. Please install it first."
    return 1
  fi

  # Check for sqlalchemy in project
  if [ -f "requirements.txt" ] && grep -qi "sqlalchemy" requirements.txt; then
    log_success "✅ SQLAlchemy detected in requirements.txt."
  elif [ -f "pyproject.toml" ] && grep -qi "sqlalchemy" pyproject.toml; then
    log_success "✅ SQLAlchemy detected in pyproject.toml."
  else
    log_info "⏭️  SQLAlchemy: Skipped (no SQLAlchemy dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for SQLAlchemy setup.
# Examples:
#   install_sqlalchemy
install_sqlalchemy() {
  log_info "🚀 SQLAlchemy setup usually happens via: pip install sqlalchemy"
  log_info "Checking if sqlalchemy is already in environment..."

  if python3 -c "import sqlalchemy" >/dev/null 2>&1; then
    log_success "✅ SQLAlchemy is already installed in Python environment."
  else
    log_info "SQLAlchemy not found; installation recommended in virtual environment."
  fi
}
