#!/bin/sh

# --- Project Hydration Script ---
# Re-brands the template for a new project by replacing placeholders.

set -e

# Colors for output (POSIX compatible ASCII escapes)
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

printf "%b💧 Project Hydration: Converting Template to Project...%b\n\n" "${BLUE}" "${NC}"

# 1. Interactive Input
printf "Enter Project Name (e.g., my-awesome-app): "
read -r PROJECT_NAME
printf "Enter Author Name (e.g., John Doe): "
read -r AUTHOR_NAME
printf "Enter GitHub Username/Org (e.g., myorg): "
read -r GITHUB_ORG

# Default placeholders to replace
OLD_PROJECT="template"
OLD_ORG="snowdreamtech"
OLD_USER="snowdream"

# 2. Confirmation
printf "\n%bConfiguration Summary:%b\n" "${YELLOW}" "${NC}"
printf "  Project: %b%s%b\n" "${GREEN}" "$PROJECT_NAME" "${NC}"
printf "  Author:  %b%s%b\n" "${GREEN}" "$AUTHOR_NAME" "${NC}"
printf "  GitHub:  %b%s%b\n" "${GREEN}" "$GITHUB_ORG" "${NC}"

printf "\nProceed with hydration? (y/N): "
read -r CONFIRM
case "$CONFIRM" in
[yY]*) ;;
*)
  printf "%bAborted.%b\n" "${RED}" "${NC}"
  exit 1
  ;;
esac

# 3. Replace Placeholders
printf "\n%bStep 1: Replacing placeholders in files...%b\n" "${BLUE}" "${NC}"

# Use perl for cross-platform compatibility
find . -type f \
  ! -path "*/.git/*" \
  ! -path "./node_modules/*" \
  ! -path "./.venv/*" \
  ! -path "./scripts/init-project.sh" \
  -exec perl -pi -e "s/$OLD_PROJECT/$PROJECT_NAME/g" {} +

find . -type f \
  ! -path "*/.git/*" \
  ! -path "./node_modules/*" \
  ! -path "./.venv/*" \
  ! -path "./scripts/init-project.sh" \
  ! -path "./scripts/init-project.ps1" \
  ! -path "./scripts/init-project.bat" \
  -exec perl -pi -e "s/$OLD_ORG|$OLD_USER/$GITHUB_ORG/g" {} +

# 4. Update LICENSE
printf "%bStep 2: Updating LICENSE...%b\n" "${BLUE}" "${NC}"
CURRENT_YEAR=$(date +%Y)
perl -pi -e "s/Copyright \(c\) \d{4}-present SnowdreamTech Inc\./Copyright (c) $CURRENT_YEAR-present $AUTHOR_NAME/g" LICENSE

# 5. Git Initialization
printf "\nRe-initialize Git repository? (y/N): "
read -r REINIT_GIT
case "$REINIT_GIT" in
[yY]*)
  printf "%bStep 3: Re-initializing Git...%b\n" "${BLUE}" "${NC}"
  rm -rf .git
  git init
  git add .
  git commit -m "initial commit: project hydrated from template"
  ;;
*) ;;
esac

printf "\n%b🚀 Project Hydration Complete!%b\n" "${GREEN}" "${NC}"
printf "Next steps: Run 'make setup'.\n"
