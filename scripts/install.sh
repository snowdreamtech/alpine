#!/bin/sh
# scripts/install.sh - Unified Project Dependency Installer
# Consolidates pnpm, pip, and other dependency managers into a professional CLI.
# Features: POSIX compliant, Execution Guard, SSoT Architecture, Professional UX.

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=1 # 0: quiet, 1: normal, 2: verbose

# Logging functions
log_info() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$BLUE" "$1" "$NC"; fi
}
log_success() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$GREEN" "$1" "$NC"; fi
}
log_warn() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; fi
}
log_error() {
  printf "%b%s%b\n" "$RED" "$1" "$NC" >&2
}
log_debug() {
  if [ "$VERBOSE" -ge 2 ]; then printf "[DEBUG] %s\n" "$1"; fi
}

# 1. Execution Context Guard
if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
  log_error "Error: This script must be run from the project root."
  exit 1
fi

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Installs project-level dependencies for all supported language stacks.

Options:
  -q, --quiet      Only show installation summary/errors.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

Environment Variables:
  NPM              NPM client to use (default: pnpm)
  PYTHON           Python executable (default: python3)
  VENV             Virtualenv directory (default: .venv)

EOF
}

# Argument parsing
for arg in "$@"; do
  case "$arg" in
  -q | --quiet) VERBOSE=0 ;;
  -v | --verbose) VERBOSE=2 ;;
  -h | --help)
    show_help
    exit 0
    ;;
  esac
done

log_info "📦 Installing Project Dependencies...\n"

# 2. Node.js dependencies
if [ -f "package.json" ]; then
  NPM=${NPM:-pnpm}
  log_info "── Installing Node.js dependencies ($NPM) ──"
  if command -v "$NPM" >/dev/null 2>&1; then
    "$NPM" install
  else
    log_warn "Warning: $NPM not found. Skipping Node.js dependencies."
  fi
fi

# 3. Python dependencies
if [ -f "requirements-dev.txt" ] || [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  printf "\n"
  log_info "── Installing Python dependencies ──"
  VENV=${VENV:-.venv}
  PYTHON=${PYTHON:-python3}

  if [ ! -d "$VENV" ]; then
    log_info "Creating virtual environment in $VENV..."
    "$PYTHON" -m venv "$VENV"
  fi

  if [ -x "$VENV/bin/pip" ]; then
    PIP="$VENV/bin/pip"
  elif [ -x "$VENV/Scripts/pip.exe" ]; then
    PIP="$VENV/Scripts/pip.exe"
  else
    log_error "Error: pip not found in $VENV."
    exit 1
  fi

  if [ -f "requirements-dev.txt" ]; then
    "$PIP" install -r requirements-dev.txt
  elif [ -f "requirements.txt" ]; then
    "$PIP" install -r requirements.txt
  fi
fi

# 4. Git Hooks (if setup script already ran)
if [ -d ".git/hooks" ] && command -v pre-commit >/dev/null 2>&1; then
  printf "\n"
  log_info "── Installing pre-commit hooks ──"
  pre-commit install
fi

log_success "\n✨ All dependencies installed successfully!"
