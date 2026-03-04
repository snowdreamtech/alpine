#!/bin/bash

# --- Project Hydration Script ---
# Re-brands the template for a new project by replacing placeholders.

set -euo pipefail

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}💧 Project Hydration: Converting Template to Project...${NC}\n"

# 1. Interactive Input
read -rp "Enter Project Name (e.g., my-awesome-app): " PROJECT_NAME
read -rp "Enter Author Name (e.g., John Doe): " AUTHOR_NAME
read -rp "Enter GitHub Username/Org (e.g., myorg): " GITHUB_ORG

# Default placeholders to replace
OLD_PROJECT="template"
OLD_ORG="snowdreamtech"
OLD_USER="snowdream"

# 2. Confirmation
echo -e "\n${YELLOW}Configuration Summary:${NC}"
echo -e "  Project: ${GREEN}$PROJECT_NAME${NC}"
echo -e "  Author:  ${GREEN}$AUTHOR_NAME${NC}"
echo -e "  GitHub:  ${GREEN}$GITHUB_ORG${NC}"

read -rp "Proceed with hydration? (y/N): " CONFIRM
if [[ $CONFIRM != [yY] ]]; then
  echo -e "${RED}Aborted.${NC}"
  exit 1
fi

# 3. Replace Placeholders
echo -e "\n${BLUE}Step 1: Replacing placeholders in files...${NC}"

# Use perl for cross-platform compatibility
find . -type f \
  -not -path "*/.git/*" \
  -not -path "./node_modules/*" \
  -not -path "./.venv/*" \
  -not -path "./scripts/init-project.sh" \
  -print0 | xargs -0 perl -pi -e "s/$OLD_PROJECT/$PROJECT_NAME/g"

find . -type f \
  -not -path "*/.git/*" \
  -not -path "./node_modules/*" \
  -not -path "./.venv/*" \
  -not -path "./scripts/init-project.sh" \
  -print0 | xargs -0 perl -pi -e "s/$OLD_ORG|$OLD_USER/$GITHUB_ORG/g"

# 4. Update LICENSE
echo -e "${BLUE}Step 2: Updating LICENSE...${NC}"
CURRENT_YEAR=$(date +%Y)
perl -pi -e "s/Copyright \(c\) \d{4}-present SnowdreamTech Inc\./Copyright (c) $CURRENT_YEAR-present $AUTHOR_NAME/g" LICENSE

# 5. Git Initialization
read -rp "Re-initialize Git repository? (y/N): " REINIT_GIT
if [[ $REINIT_GIT == [yY] ]]; then
  echo -e "${BLUE}Step 3: Re-initializing Git...${NC}"
  rm -rf .git
  git init
  git add .
  git commit -m "initial commit: project hydrated from template"
fi

echo -e "\n${GREEN}🚀 Project Hydration Complete!${NC}"
echo -e "Next steps: Run 'make setup'."
