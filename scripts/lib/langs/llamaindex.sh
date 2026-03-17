#!/usr/bin/env sh
# scripts/lib/langs/llamaindex.sh - LlamaIndex Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for LlamaIndex development prerequisites.
# Examples:
#   check_llamaindex
check_llamaindex() {
  log_info "🔍 Checking LlamaIndex environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  LlamaIndex requires Python 3. Please install it first."
    return 1
  fi

  # Check for LlamaIndex in project
  if [ -f "requirements.txt" ] && grep -qi "llama-index" requirements.txt; then
    log_success "✅ LlamaIndex detected in requirements.txt."
  elif [ -f "pyproject.toml" ] && grep -qi "llama-index" pyproject.toml; then
    log_success "✅ LlamaIndex detected in pyproject.toml."
  else
    log_info "⏭️  LlamaIndex: Skipped (no LlamaIndex dependency found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for LlamaIndex setup.
# Examples:
#   install_llamaindex
install_llamaindex() {
  log_info "🚀 LlamaIndex setup usually happens via: pip install llama-index"
  log_info "Checking if llama-index is already in environment..."

  if python3 -c "import llama_index" >/dev/null 2>&1; then
    log_success "✅ LlamaIndex is already installed in Python environment."
  else
    log_info "LlamaIndex not found; installation recommended in virtual environment."
  fi
}
