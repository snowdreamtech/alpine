#!/bin/sh
# scripts/check-env.sh - Environment Health Check Script
# Validates the development environment and required tool versions.
# Features: POSIX compliant, Execution Guard, Multi-Language check, Professional UX.

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

Validates the development environment and required tool versions.

Options:
  -q, --quiet      Only show errors.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

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

log_info "🔍 Checking Development Environment Health...\n"

HEALTHY=0

check_version() {
  _NAME="$1"
  _CMD="$2"
  _MIN_VER="$3"
  _VER_CMD="$4"

  log_debug "Checking $_NAME (min: $_MIN_VER)..."

  if ! command -v "$_CMD" >/dev/null 2>&1; then
    log_error "❌ $_NAME: Not found. Please install it."
    HEALTHY=1
    return 1
  fi

  _CURRENT_VER=$($_VER_CMD | sed 's/[^0-9.]//g' | cut -d. -f1-3)

  # Simple version comparison using sort -V (POSIX doesn't have sort -V, but we can use a helper)
  _LOWER_VER=$(printf "%s\n%s" "$_MIN_VER" "$_CURRENT_VER" | sort -n -t. -k1,1 -k2,2 -k3,3 | head -n1)

  if [ "$_LOWER_VER" = "$_MIN_VER" ] || [ "$_CURRENT_VER" = "$_MIN_VER" ]; then
    log_success "✅ $_NAME: v$_CURRENT_VER (matches/exceeds v$_MIN_VER)"
  else
    log_warn "⚠️  $_NAME: v$_CURRENT_VER (below recommended v$_MIN_VER)"
    HEALTHY=1
  fi
}

# 2. Tool Checks
check_version "Node.js" "node" "20.0.0" "node -v"
check_version "pnpm" "pnpm" "9.0.0" "pnpm -v"
check_version "Python" "python3" "3.10.0" "python3 --version"
check_version "Git" "git" "2.30.0" "git --version"

if command -v go >/dev/null 2>&1; then
  check_version "Go" "go" "1.21.0" "go version"
fi

if command -v make >/dev/null 2>&1; then
  log_success "✅ Make: Installed"
else
  log_error "❌ Make: Not found."
  HEALTHY=1
fi

if command -v docker >/dev/null 2>&1; then
  log_success "✅ Docker: Installed"
else
  log_warn "⚠️  Docker: Not found (optional for some tasks)"
fi

# 3. Project File Integrity
log_info "\n📁 Checking Project Integrity..."
for f in "Makefile" "package.json" "README.md" ".agent/rules/01-general.md"; do
  if [ -f "$f" ]; then
    log_debug "Found $f"
  else
    log_error "❌ Missing critical file: $f"
    HEALTHY=1
  fi
done

if [ "$HEALTHY" -eq 0 ]; then
  log_success "\n✨ Environment is HEALTHY! Ready for development."
else
  log_warn "\n🛠️  Environment has issues. Please address the errors above."
  exit 1
fi
