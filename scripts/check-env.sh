#!/bin/sh
# scripts/check-env.sh - Environment Health Check Script
# Validates the development environment and required tool versions.
# Features: POSIX compliant, Execution Guard, Multi-Language check, Professional UX.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# Help message
# shellcheck disable=SC2329
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
parse_common_args "$@"

log_info "🔍 Checking Development Environment Health...\n"

HEALTHY=0

check_version() {
  _NAME="$1"
  _CMD="$2"
  _MIN_VER="$3"
  _VER_CMD="$4"
  _CRITICAL="${5:-0}"

  log_debug "Checking $_NAME (min: $_MIN_VER)..."

  if ! command -v "$_CMD" >/dev/null 2>&1; then
    log_warn "❌ $_NAME: Not found."
    HEALTHY=1
    [ "$_CRITICAL" -eq 1 ] && CORE_HEALTHY=1
    return 1
  fi

  _CURRENT_VER=$($_VER_CMD | sed 's/[^0-9.]//g' | cut -d. -f1-3)

  # Simple version comparison using sort -n
  _LOWER_VER=$(printf "%s\n%s" "$_MIN_VER" "$_CURRENT_VER" | sort -n -t. -k1,1 -k2,2 -k3,3 | head -n1)

  if [ "$_LOWER_VER" = "$_MIN_VER" ] || [ "$_CURRENT_VER" = "$_MIN_VER" ]; then
    log_success "✅ $_NAME: v$_CURRENT_VER (matches/exceeds v$_MIN_VER)"
  else
    log_warn "⚠️  $_NAME: v$_CURRENT_VER (below recommended v$_MIN_VER)"
    HEALTHY=1
    [ "$_CRITICAL" -eq 1 ] && CORE_HEALTHY=1
  fi
}

# 2. Tool Checks
# Core runtimes are CRITICAL (1)
check_version "Node.js" "node" "24.1.0" "node -v" 1
check_version "pnpm" "pnpm" "9.0.0" "pnpm -v" 1
check_version "Python" "$PYTHON" "3.10.0" "$PYTHON --version" 1
check_version "Git" "git" "2.30.0" "git --version" 1

if command -v make >/dev/null 2>&1; then
  log_success "✅ Make: Installed"
else
  log_error "❌ Make: Not found."
  HEALTHY=1
  CORE_HEALTHY=1
fi

# Optional tools are NOT critical (0)
if command -v go >/dev/null 2>&1; then
  check_version "Go" "go" "1.21.0" "go version" 0
fi

if command -v golangci-lint >/dev/null 2>&1; then
  check_version "golangci-lint" "golangci-lint" "1.55.0" "golangci-lint --version" 0
fi

if command -v gitleaks >/dev/null 2>&1; then
  log_success "✅ Gitleaks: Installed"
fi

if command -v hadolint >/dev/null 2>&1; then
  log_success "✅ Hadolint: Installed"
fi

if command -v docker >/dev/null 2>&1; then
  log_success "✅ Docker: Installed"
else
  log_warn "⚠️  Docker: Not found (optional for some tasks)"
fi

# 3. Project File Integrity
log_info "\n📁 Checking Project Integrity..."
for f in "Makefile" "$PACKAGE_JSON" "README.md" ".agent/rules/01-general.md"; do
  if [ -f "$f" ]; then
    log_debug "Found $f"
  else
    log_error "❌ Missing critical file: $f"
    HEALTHY=1
    CORE_HEALTHY=1
  fi
done

# Final combined health check
# HEALTHY=0 means ALL tools (core + optional) are perfect.
# CORE_HEALTHY=0 means project is functional for main tasks.

if [ "$HEALTHY" -eq 0 ]; then
  log_success "\n✨ Environment is HEALTHY! Ready for development."
  exit 0
elif [ "$CORE_HEALTHY" -eq 0 ]; then
  log_warn "\n🛠️  Environment is FUNCTIONAL but has warnings (missing recommended/optional tools)."
  log_warn "💡 Run 'make setup' to address the warnings above."
  exit 0
else
  log_error "\n❌ Environment is BROKEN. Critical tools or files are missing."
  log_error "Please fix the issues above to proceed."
  exit 1
fi
