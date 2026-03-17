#!/usr/bin/env sh
# scripts/lib/langs/flask.sh - Flask Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Flask development prerequisites.
# Examples:
#   check_flask
check_flask() {
  log_info "🔍 Checking Flask environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  Flask requires Python 3. Please install it first."
    return 1
  fi

  # Check for flask in project (usually via pip)
  if [ -f "requirements.txt" ] && grep -qi "flask" requirements.txt; then
    log_success "✅ Flask detected in requirements.txt."
  elif [ -f "pyproject.toml" ] && grep -qi "flask" pyproject.toml; then
    log_success "✅ Flask detected in pyproject.toml."
  else
    log_info "⏭️  Flask: Skipped (no Flask dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Flask setup.
# Examples:
#   install_flask
install_flask() {
  log_info "🚀 Flask setup usually happens via: pip install flask"
  log_info "Checking if flask is already in environment..."

  if python3 -c "import flask" >/dev/null 2>&1; then
    log_success "✅ Flask is already installed in Python environment."
  else
    log_info "Flask not found; installation recommended in virtual environment."
  fi
}
