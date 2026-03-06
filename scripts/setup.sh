#!/bin/sh
# scripts/setup.sh - Universal Project Setup Script (macOS/Linux)
# This script initializes the development environment without requiring 'make'.

set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default Variables
VENV=${VENV:-.venv}
PYTHON=${PYTHON:-python3}
OS_NAME=$(uname -s)

printf "%b🚀 Initializing Snowdream Tech AI IDE Template for %s...%b\n" "${BLUE}" "${OS_NAME}" "${NC}"

# 1. Node.js & pnpm Setup
printf "\n%b[1/4] Setting up Node.js & pnpm...%b\n" "${YELLOW}" "${NC}"
if command -v corepack >/dev/null 2>&1; then
  printf "Enabling corepack...\n"
  corepack enable
else
  printf "%bWarning: corepack not found. Please ensure Node.js 16.9+ is installed.%b\n" "${RED}" "${NC}"
fi

if [ -f package.json ]; then
  printf "Installing Node.js dependencies via pnpm...\n"
  pnpm install
fi

# 2. Python Virtual Environment Setup
printf "\n%b[2/4] Setting up Python Virtual Environment in %s...%b\n" "${YELLOW}" "${NC}" "${VENV}"
if [ ! -d "$VENV" ]; then
  "$PYTHON" -m venv "$VENV"
fi

# Use the venv's pip
"$VENV/bin/pip" install --upgrade pip
if [ -f requirements-dev.txt ]; then
  printf "Installing Python dev dependencies...\n"
  "$VENV/bin/pip" install -r requirements-dev.txt
fi

# 3. System Tools Setup (Project-Local)
printf "\n%b[3/4] Ensuring system tools are installed locally...%b\n" "${YELLOW}" "${NC}"
printf "All tools (shellcheck, hadolint, gitleaks, etc.) are now installed via npm/pip into %s or node_modules.\n" "${VENV}"
printf "This ensures version consistency across all environments.\n"

# 4. Pre-commit Hooks Setup
printf "\n%b[4/4] Activating pre-commit hooks...%b\n" "${YELLOW}" "${NC}"
if [ -x "$VENV/bin/pre-commit" ]; then
  "$VENV/bin/pre-commit" install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg
  printf "%bPre-commit hooks activated!%b\n" "${GREEN}" "${NC}"
else
  printf "%bWarning: pre-commit not found in virtual environment.%b\n" "${RED}" "${NC}"
fi

printf "\n%b✨ Setup complete!%b\n" "${GREEN}" "${NC}"
printf "You can now use either 'make' commands or call tools directly from %s/bin/ or node_modules/.bin/\n" "${VENV}"
