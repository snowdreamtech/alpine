#!/usr/bin/env sh
# scripts/lib/langs/tidb.sh - TiDB Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for TiDB development prerequisites.
# Examples:
#   check_tidb
check_tidb() {
  log_info "🔍 Checking TiDB environment..."

  # Check for TiUP (TiDB's package manager) or TiDB binary
  if command -v tiup >/dev/null 2>&1; then
    log_success "✅ TiUP (TiDB manager) detected."
  elif command -v tidb-server >/dev/null 2>&1; then
    log_success "✅ TiDB server binary detected."
  elif [ -f "docker-compose.yml" ] && grep -qi "tidb" docker-compose.yml; then
    log_success "✅ TiDB detected in docker-compose.yml."
  else
    log_info "⏭️  TiDB: Skipped (no TiDB tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs TiUP (TiDB's package manager).
# Examples:
#   install_tidb
install_tidb() {
  log_info "🚀 Setting up TiUP..."

  if is_dry_run; then
    log_info "DRY-RUN: curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh"
    return 0
  fi

  if ! curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh; then
    log_warn "⚠️ Failed to install TiUP automatically."
  else
    log_success "✅ TiUP installed successfully."
  fi
}
