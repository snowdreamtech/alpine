#!/usr/bin/env sh
# scripts/lib/langs/pandas.sh - Pandas Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Pandas development prerequisites.
# Examples:
#   check_pandas
check_pandas() {
  log_info "🔍 Checking Pandas environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  Pandas requires Python 3. Please install it first."
    return 1
  fi

  # Check for Pandas in project
  if [ -f "requirements.txt" ] && grep -qi "pandas" requirements.txt; then
    log_success "✅ Pandas detected in requirements.txt."
  elif [ -f "pyproject.toml" ] && grep -qi "pandas" pyproject.toml; then
    log_success "✅ Pandas detected in pyproject.toml."
  else
    log_info "⏭️  Pandas: Skipped (no Pandas dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Pandas setup.
# Examples:
#   install_pandas
install_pandas() {
  log_info "🚀 Pandas setup usually happens via: pip install pandas"
  log_info "Checking if pandas is already in environment..."

  if python3 -c "import pandas" >/dev/null 2>&1; then
    log_success "✅ Pandas is already installed in Python environment."
  else
    log_info "Pandas not found; installation recommended."
  fi
}
