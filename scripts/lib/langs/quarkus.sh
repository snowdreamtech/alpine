#!/usr/bin/env sh
# scripts/lib/langs/quarkus.sh - Quarkus Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Quarkus development prerequisites.
# Examples:
#   check_quarkus
check_quarkus() {
  log_info "🔍 Checking Quarkus environment..."

  # Check for JDK (Prerequisite)
  if ! command -v java >/dev/null 2>&1; then
    log_warn "⚠️  Quarkus requires Java. Please install it first."
    return 1
  fi

  # Check for Quarkus binary or project files
  if command -v quarkus >/dev/null 2>&1; then
    log_success "✅ Quarkus CLI detected."
  elif [ -f "pom.xml" ] && grep -q "quarkus" pom.xml; then
    log_success "✅ Quarkus detected in pom.xml."
  elif [ -f "build.gradle" ] && grep -q "quarkus" build.gradle; then
    log_success "✅ Quarkus detected in build.gradle."
  else
    log_info "⏭️  Quarkus: Skipped (no Quarkus files found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for Quarkus setup.
# Examples:
#   install_quarkus
install_quarkus() {
  log_info "🚀 Quarkus setup: curl -Ls https://sh.quarkus.io | sh"
  if is_dry_run; then
    log_info "DRY-RUN: Skip Quarkus installation."
    return 0
  fi
}
