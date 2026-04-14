#!/bin/sh
# .devcontainer/init.sh — Devcontainer initialization script
# Purpose: Set up mise, GPG, and git configuration for development environment
# Compatibility: POSIX shell (sh, bash, zsh, dash)

set -eu

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verbosity control
VERBOSE="${VERBOSE:-0}"
DEBUG="${DEBUG:-0}"

log_info() { echo "${BLUE}ℹ $@${NC}"; }
log_success() { echo "${GREEN}✓ $@${NC}"; }
log_step() { echo "${GREEN}$@${NC}"; }
log_warning() { echo "${YELLOW}⚠ $@${NC}"; }
log_error() { echo "${RED}✗ $@${NC}"; }
log_detail() { [ "$VERBOSE" -eq 1 ] && echo "${YELLOW}  $@${NC}" || true; }

echo "${BLUE}=== Initializing Devcontainer ===${NC}"

# Step 0: Detect environment
log_step "🔍 Detecting container environment..."
if [ -f /.dockerenv ]; then
  log_detail "Running in Docker container"
elif grep -qi docker /proc/1/cgroup 2>/dev/null; then
  log_detail "Running in containerized environment"
fi
CONTAINER_USER="${CONTAINER_USER:-root}"
log_detail "Container user: $CONTAINER_USER"

# Step 1: Trust and bootstrap mise
log_step "📦 Setting up mise..."
if ! command -v mise >/dev/null 2>&1; then
  log_error "mise not found in PATH"
else
  mise trust -a || log_warning "Failed to trust mise configuration"
  mise bootstrap || log_warning "Failed to bootstrap mise tools"
  log_success "mise configured"
fi

# Step 2: Configure SSH permissions
log_step "🔑 Configuring SSH permissions..."
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh"
  log_detail ".ssh directory (700)"

  # Set permissions for SSH key files
  for key in id_rsa id_ed25519 id_ecdsa id_dsa; do
    if [ -f "$HOME/.ssh/$key" ]; then
      chmod 600 "$HOME/.ssh/$key"
      log_detail "$key (600)"
    fi
  done

  # Set permissions for public keys and config
  for pubfile in "$HOME"/.ssh/*.pub "$HOME"/.ssh/config "$HOME"/.ssh/authorized_keys "$HOME"/.ssh/known_hosts; do
    if [ -f "$pubfile" ]; then
      chmod 600 "$pubfile"
      log_detail "$(basename "$pubfile") (600)"
    fi
  done

  log_success "SSH directory permissions configured"
else
  log_warning "SSH directory not found (optional)"
fi

# Step 3: Configure GPG permissions
log_step "🔐 Configuring GPG permissions..."
if [ -d "$HOME/.gnupg" ]; then
  chmod 700 "$HOME/.gnupg"
  log_detail ".gnupg directory (700)"

  # Configure GPG agent socket permissions (if exists)
  if [ -S "$HOME/.gnupg/S.gpg-agent" ]; then
    chmod 700 "$HOME/.gnupg/S.gpg-agent"
    log_detail "S.gpg-agent socket (700)"
  fi

  # Configure subdirectories
  for subdir in private-keys-v1.d openpgp-revocs.d crls-d; do
    if [ -d "$HOME/.gnupg/$subdir" ]; then
      chmod 700 "$HOME/.gnupg/$subdir"
      log_detail "$subdir/ (700)"
    fi
  done

  # Configure key files
  for keyfile in "$HOME"/.gnupg/*.gpg "$HOME"/.gnupg/*.asc "$HOME"/.gnupg/gpg.conf "$HOME"/.gnupg/gpg-agent.conf; do
    if [ -f "$keyfile" ]; then
      chmod 600 "$keyfile"
      log_detail "$(basename "$keyfile") (600)"
    fi
  done

  log_success "GPG directory permissions configured"
else
  log_warning "GPG directory not found (optional)"
fi

# Step 4: Configure GPG program path
log_step "🔐 Setting up GPG program path..."
if command -v gpg >/dev/null 2>&1; then
  GPG_PATH="$(command -v gpg)"
  git config --local gpg.program "$GPG_PATH"
  log_success "GPG program: $GPG_PATH"

  # Optional: Verify GPG can list keys
  if [ "$DEBUG" -eq 1 ]; then
    if gpg --list-secret-keys >/dev/null 2>&1; then
      log_detail "GPG can access private keys"
    else
      log_warning "GPG found but cannot access private keys"
    fi
  fi
else
  log_warning "GPG not found in PATH (optional)"
fi

# Step 5: Configure git user information
log_step "👤 Configuring git user information..."
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

if [ -z "$GIT_USER_NAME" ]; then
  GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
fi
if [ -z "$GIT_USER_EMAIL" ]; then
  GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
fi

if [ -n "$GIT_USER_NAME" ]; then
  git config --local user.name "$GIT_USER_NAME"
  log_detail "Git user: $GIT_USER_NAME"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
  git config --local user.email "$GIT_USER_EMAIL"
  log_detail "Git email: $GIT_USER_EMAIL"
fi

if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
  log_warning "Git user info incomplete (configure with git config --global)"
fi

log_success "Git user information configured"

# Step 6: Configure git signing key
log_step "🔑 Configuring git signing..."
if SIGNING_KEY=$(git config --global user.signingkey 2>/dev/null); then
  git config --local user.signingkey "$SIGNING_KEY"
  git config --local commit.gpgsign true
  log_success "Git signing enabled with key: $SIGNING_KEY"
else
  log_warning "No global signing key found (optional)"
  git config --local commit.gpgsign false || true
fi

echo ""
log_info "========================================="
log_success "Devcontainer initialization complete!"
log_info "========================================="
log_detail 'Run `git config --local --list` to view local git config'
log_detail "Set VERBOSE=1 for detailed initialization logs"
