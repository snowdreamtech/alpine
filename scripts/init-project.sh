#!/bin/sh
# scripts/init-project.sh - Project Hydration Script
# Re-brands the template for a new project by replacing placeholders.
# Features: POSIX compliant, Execution Guard, Dry-run support, Professional UX.

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
log_info() { printf "%b%s%b\n" "$BLUE" "$1" "$NC"; }
log_success() { printf "%b%s%b\n" "$GREEN" "$1" "$NC"; }
log_warn() { printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; }
log_error() { printf "%b%s%b\n" "$RED" "$1" "$NC" >&2; }

# 1. Execution Context Guard
if [ ! -f "LICENSE" ] || [ ! -d ".git" ]; then
  log_error "Error: This script must be run from the project root (where LICENSE and .git reside)."
  exit 1
fi

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Re-brands the template for a new project by replacing placeholders.

Options:
  --dry-run        Preview changes without modifying files.
  --help           Show this help message.

EOF
}

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=1
    log_warn "Running in DRY-RUN mode. No changes will be applied."
    ;;
  --help)
    show_help
    exit 0
    ;;
  esac
done

printf "%b💧 Project Hydration: Converting Template to Project...%b\n\n" "${BLUE}" "${NC}"

# 2. Interactive Input
# In dry-run or non-interactive mode, we might want defaults, but for hydration, we keep it interactive.
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

# 3. Confirmation
printf "\n%bConfiguration Summary:%b\n" "${YELLOW}" "${NC}"
printf "  Project: %b%s%b\n" "${GREEN}" "$PROJECT_NAME" "${NC}"
printf "  Author:  %b%s%b\n" "${GREEN}" "$AUTHOR_NAME" "${NC}"
printf "  GitHub:  %b%s%b\n" "${GREEN}" "$GITHUB_ORG" "${NC}"

if [ "$DRY_RUN" -eq 0 ]; then
  printf "\nProceed with hydration? (y/N): "
  read -r CONFIRM
  case "$CONFIRM" in
  [yY]*) ;;
  *)
    log_error "Aborted."
    exit 1
    ;;
  esac
fi

# 4. Replace Placeholders
log_info "\nStep 1: Replacing placeholders in files..."

# Create a temporary file to track changes if in dry-run
if [ "$DRY_RUN" -eq 1 ]; then
  log_warn "DRY-RUN: Would replace '$OLD_PROJECT' with '$PROJECT_NAME' and '$OLD_ORG/$OLD_USER' with '$GITHUB_ORG' in matching files."
else
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
fi

# 5. Update LICENSE
log_info "Step 2: Updating LICENSE..."
CURRENT_YEAR=$(date +%Y)
if [ "$DRY_RUN" -eq 1 ]; then
  log_warn "DRY-RUN: Would update LICENSE copyright to $CURRENT_YEAR and $AUTHOR_NAME."
else
  perl -pi -e "s/Copyright \(c\) \d{4}-present SnowdreamTech Inc\./Copyright (c) $CURRENT_YEAR-present $AUTHOR_NAME/g" LICENSE
fi

# 6. Git Initialization
if [ "$DRY_RUN" -eq 0 ]; then
  printf "\nRe-initialize Git repository? (y/N): "
  read -r REINIT_GIT
  case "$REINIT_GIT" in
  [yY]*)
    log_info "Step 3: Re-initializing Git..."
    rm -rf .git
    git init
    git add .
    git commit -m "initial commit: project hydrated from template"
    ;;
  *) ;;
  esac
else
  log_warn "DRY-RUN: Would prompt for Git re-initialization."
fi

log_success "\n🚀 Project Hydration Complete!"
if [ "$DRY_RUN" -eq 0 ]; then
  printf "Next steps: Run 'make setup'.\n"
fi
