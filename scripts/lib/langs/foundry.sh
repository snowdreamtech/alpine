#!/usr/bin/env sh
# scripts/lib/langs/foundry.sh - Foundry Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Foundry development prerequisites.
# Examples:
#   check_foundry
check_foundry() {
  log_info "🔍 Checking Foundry environment..."

  # Check for Foundry binaries (forge, cast, anvil, chisel)
  if command -v forge >/dev/null 2>&1; then
    log_success "✅ Foundry (forge) detected."
  elif [ -f "foundry.toml" ]; then
    log_success "✅ Foundry configuration file detected."
  else
    log_info "⏭️  Foundry: Skipped (no Foundry tools found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Foundry tools via foundryup.
# Examples:
#   install_foundry
install_foundry() {
  log_info "🚀 Setting up Foundry..."

  if is_dry_run; then
    log_info "DRY-RUN: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    return 0
  fi

  if ! curl -L https://foundry.paradigm.xyz | bash; then
    log_warn "⚠️ Failed to install Foundry installer."
  else
    log_success "✅ Foundry installer set up. Please run foundryup manually to complete."
  fi
}
