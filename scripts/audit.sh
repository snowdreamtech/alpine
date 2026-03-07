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
  if [ "$DRY_RUN" -eq 1 ]; then
    log_success "DRY-RUN: Would run gitleaks detect"
  else
    gitleaks detect --source . --verbose
  fi
fi

# 4. Dependency Audits
run_npm_script "audit"

if [ -f "$REQUIREMENTS_TXT" ] || [ -f "requirements.txt" ] || [ -f "$PYPROJECT_TOML" ]; then
  log_info "\n── Auditing Python dependencies (pip-audit) ──"
  if command -v pip-audit >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log_success "DRY-RUN: Would run pip-audit"
    else
      pip-audit
    fi
  else
    log_warn "pip-audit not found. Skipping python audit."
  fi
fi

log_success "\n✨ Security audit finished."
