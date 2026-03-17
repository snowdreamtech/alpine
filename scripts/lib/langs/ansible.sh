#!/usr/bin/env sh
# scripts/lib/langs/ansible.sh - Ansible Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for Ansible development prerequisites.
# Examples:
#   check_ansible
check_ansible() {
  log_info "🔍 Checking Ansible environment..."

  # Check for Python (Prerequisite)
  if ! command -v python3 >/dev/null 2>&1; then
    log_warn "⚠️  Ansible requires Python 3. Please install it first."
    return 1
  fi

  # Check for ansible command or project files
  if command -v ansible >/dev/null 2>&1; then
    log_success "✅ Ansible CLI detected."
  elif has_lang_files "ansible.cfg playbook.yml site.yml" "roles/"; then
    log_success "✅ Ansible project files detected."
  else
    log_info "⏭️  Ansible: Skipped (no Ansible files found)"
    return 0
  fi

  return 0
}

# Purpose: Installs Ansible via pip.
# Examples:
#   install_ansible
install_ansible() {
  log_info "🚀 Setting up Ansible..."

  if is_dry_run; then
    log_info "DRY-RUN: pip install ansible ansible-lint"
    return 0
  fi

  if ! pip install ansible ansible-lint; then
    log_error "❌ Failed to install Ansible."
    exit 1
  fi

  log_success "✅ Ansible installed successfully."
}
