#!/bin/sh
# .devcontainer/init.sh — Devcontainer initialization script
# Purpose: Set up mise, GPG, and git configuration for development environment
# Compatibility: POSIX shell (sh, bash, zsh, dash)

set -eu

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "${BLUE}=== Initializing Devcontainer ===${NC}"

# Step 1: Trust and bootstrap mise
echo "${GREEN}📦 Setting up mise...${NC}"
mise trust -a
mise bootstrap

# Step 2: Configure GPG permissions
echo "${GREEN}🔐 Configuring GPG...${NC}"
if [ -d "$HOME/.gnupg" ]; then
  chmod 700 "$HOME/.gnupg"
  echo "${GREEN}✓ GPG directory permissions fixed${NC}"
else
  echo "${BLUE}ℹ GPG directory not found (optional)${NC}"
fi

# Step 3: Configure git signing key
echo "${GREEN}🔑 Configuring git signing...${NC}"
if SIGNING_KEY=$(git config --global user.signingkey 2>/dev/null); then
  git config --local user.signingkey "$SIGNING_KEY"
  git config --local commit.gpgsign true
  echo "${GREEN}✓ Git signing enabled with key: ${SIGNING_KEY}${NC}"
else
  echo "${BLUE}ℹ No global signing key found (optional)${NC}"
fi

echo "${GREEN}✅ Devcontainer initialization complete!${NC}"
