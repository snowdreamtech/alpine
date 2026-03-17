#!/usr/bin/env sh
# scripts/lib/langs/ef-core.sh - EF Core Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for EF Core development prerequisites.
# Examples:
#   check_ef_core
check_ef_core() {
  log_info "🔍 Checking EF Core environment..."

  # Check for .NET SDK (Prerequisite)
  if ! command -v dotnet >/dev/null 2>&1; then
    log_warn "⚠️  EF Core requires .NET SDK. Please install it first."
    return 1
  fi

  # Check for EF Core tool or in project files
  if dotnet ef --version >/dev/null 2>&1; then
    log_success "✅ EF Core CLI tool detected."
  elif find . -maxdepth 3 -name "*.csproj" -exec grep -q "Microsoft.EntityFrameworkCore" {} +; then
    log_success "✅ EF Core detected in project dependencies."
  else
    log_info "⏭️  EF Core: Skipped (no EF Core files found)"
    return 0
  fi

  return 0
}

# Purpose: Installs EF Core CLI tool.
# Examples:
#   install_ef_core
install_ef_core() {
  log_info "🚀 Setting up EF Core CLI tool..."

  if is_dry_run; then
    log_info "DRY-RUN: dotnet tool install --global dotnet-ef"
    return 0
  fi

  if ! dotnet tool install --global dotnet-ef; then
    log_warn "⚠️ Failed to install EF Core tool globally. Consider: dotnet tool update --global dotnet-ef"
  else
    log_success "✅ EF Core tool installed successfully."
  fi
}
