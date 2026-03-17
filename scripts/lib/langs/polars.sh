#!/usr/bin/env sh
# scripts/lib/langs/polars.sh - Polars Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Polars development prerequisites.
# Examples:
#   check_polars
check_polars() {
  log_info "🔍 Checking Polars environment..."

  # Check for Python or Rust (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1 && ! command -v cargo >/dev/null 2>&1; then
    log_warn "⚠️  Polars requires Python or Rust. Please install one of them first."
    return 1
  fi

  # Check for Polars in project
  if [ -f "requirements.txt" ] && grep -qi "polars" requirements.txt; then
    log_success "✅ Polars detected in requirements.txt."
  elif [ -f "pyproject.toml" ] && grep -qi "polars" pyproject.toml; then
    log_success "✅ Polars detected in pyproject.toml."
  elif [ -f "Cargo.toml" ] && grep -qi "polars" Cargo.toml; then
    log_success "✅ Polars detected in Cargo.toml."
  else
    log_info "⏭️  Polars: Skipped (no Polars dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Polars setup.
# Examples:
#   install_polars
install_polars() {
  log_info "🚀 Polars setup: pip install polars (Python) or cargo add polars (Rust)"
  log_info "Checking if polars is already in environment..."

  if python3 -c "import polars" >/dev/null 2>&1; then
    log_success "✅ Polars is already installed in Python environment."
  else
    log_info "Polars not found; installation recommended."
  fi
}
