#!/bin/sh
# .devcontainer/init.sh — Devcontainer initialization script
# Purpose: Set up mise, GPG, and git configuration for development environment
# Compatibility: POSIX shell (sh, bash, zsh, dash)

set -eu

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "${BLUE}=== Initializing Devcontainer ===${NC}"

# Step 1: Trust and bootstrap mise
echo "${GREEN}📦 Setting up mise...${NC}"
mise trust -a
mise bootstrap

# Step 2: Configure SSH permissions
echo "${GREEN}🔑 Configuring SSH permissions...${NC}"
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh"

  # Set permissions for SSH key files
  for key in id_rsa id_ed25519 id_ecdsa id_dsa; do
    if [ -f "$HOME/.ssh/$key" ]; then
      chmod 600 "$HOME/.ssh/$key"
      echo "${YELLOW}  ✓ $key (600)${NC}"
    fi
  done

  # Set permissions for public keys and config
  for pubfile in "$HOME"/.ssh/*.pub config authorized_keys known_hosts; do
    if [ -f "$pubfile" ]; then
      chmod 600 "$pubfile"
      echo "${YELLOW}  ✓ $(basename "$pubfile") (600)${NC}"
    fi
  done

  echo "${GREEN}✓ SSH directory permissions configured${NC}"
else
  echo "${BLUE}ℹ SSH directory not found (optional)${NC}"
fi

# Step 3: Configure GPG permissions
echo "${GREEN}🔐 Configuring GPG permissions...${NC}"
if [ -d "$HOME/.gnupg" ]; then
  chmod 700 "$HOME/.gnupg"
  echo "${YELLOW}  ✓ .gnupg directory (700)${NC}"

  # Configure subdirectories
  for subdir in private-keys-v1.d openpgp-revocs.d; do
    if [ -d "$HOME/.gnupg/$subdir" ]; then
      chmod 700 "$HOME/.gnupg/$subdir"
      echo "${YELLOW}  ✓ $subdir/ (700)${NC}"
    fi
  done

  # Configure key files
  for keyfile in "$HOME"/.gnupg/*.gpg "$HOME"/.gnupg/*.asc "$HOME"/.gnupg/gpg.conf; do
    if [ -f "$keyfile" ]; then
      chmod 600 "$keyfile"
      echo "${YELLOW}  ✓ $(basename "$keyfile") (600)${NC}"
    fi
  done

  echo "${GREEN}✓ GPG directory permissions configured${NC}"
else
  echo "${BLUE}ℹ GPG directory not found (optional)${NC}"
fi

# Step 4: Configure git signing key
echo "${GREEN}🔑 Configuring git signing...${NC}"
if SIGNING_KEY=$(git config --global user.signingkey 2>/dev/null); then
  git config --local user.signingkey "$SIGNING_KEY"
  git config --local commit.gpgsign true
  echo "${GREEN}✓ Git signing enabled with key: ${SIGNING_KEY}${NC}"
else
  echo "${BLUE}ℹ No global signing key found (optional)${NC}"
fi

echo "${GREEN}✅ Devcontainer initialization complete!${NC}"
