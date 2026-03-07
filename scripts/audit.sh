#!/bin/sh
# scripts/audit.sh - Security Auditor
# Standardizes execution of security scans (gitleaks, npm audit, pip-audit, etc.).

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# ── Configuration ────────────────────────────────────────────────────────────

# Help Message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Runs security audits and vulnerability scans across all supported stacks.

Options:
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# 2. Argument Parsing
parse_common_args "$@"

log_info "🛡️  Starting Security Auditor...\n"

# 3. Secrets Scanning
if command -v gitleaks >/dev/null 2>&1; then
  log_info "── Scanning for Secrets (gitleaks) ──"
  gitleaks detect --source . --verbose
fi

# 4. Dependency Audits
if [ -f "package.json" ]; then
  NPM=${NPM:-pnpm}
  log_info "\n── Auditing Node.js dependencies ($NPM) ──"
  if command -v "$NPM" >/dev/null 2>&1; then
    "$NPM" audit
  fi
fi

if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  log_info "\n── Auditing Python dependencies (pip-audit) ──"
  if command -v pip-audit >/dev/null 2>&1; then
    pip-audit
  else
    log_warn "Warning: pip-audit not found. Skipping python audit."
  fi
fi

log_success "\n✨ Security audit finished."
