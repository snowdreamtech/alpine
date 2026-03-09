#!/bin/sh
# scripts/init-project.sh - Project Hydration Script
# Re-brands the template for a new project by replacing placeholders.
# Features: POSIX compliant, Execution Guard, Dry-run support, Professional UX.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

main() {
  # 1. Execution Context Guard
  if [ ! -f "LICENSE" ] || [ ! -d ".git" ]; then
    log_error "Error: This script must be run from the project root (where LICENSE and .git reside)."
    exit 1
  fi

  # 2. Argument Parsing
  _PROJECT_NAME=""
  _AUTHOR_NAME=""
  _GITHUB_ORG=""
  _AUTO_CONFIRM=0

  parse_common_args "$@"

  for _arg in "$@"; do
    case "$_arg" in
    --project=*) _PROJECT_NAME="${_arg#*=}" ;;
    --author=*) _AUTHOR_NAME="${_arg#*=}" ;;
    --github=*) _GITHUB_ORG="${_arg#*=}" ;;
    -y | --yes) _AUTO_CONFIRM=1 ;;
    esac
  done

  # Check if we are running in a terminal
  _IS_TTY=0
  [ -t 0 ] && _IS_TTY=1

  if [ "$VERBOSE" -ge 1 ]; then
    printf "%b💧 Project Hydration: Converting Template to Project...%b\n\n" "${BLUE}" "${NC}"
  fi

  # 3. Input Collection (Interactive fallback or validation)
  if [ -z "$_PROJECT_NAME" ]; then
    if [ "$_IS_TTY" -eq 1 ] && [ "$_AUTO_CONFIRM" -eq 0 ]; then
      printf "Enter Project Name (e.g., my-awesome-app): "
      read -r _PROJECT_NAME
    else
      log_error "Error: --project is required in non-interactive mode."
      exit 1
    fi
  fi

  if [ -z "$_AUTHOR_NAME" ]; then
    if [ "$_IS_TTY" -eq 1 ] && [ "$_AUTO_CONFIRM" -eq 0 ]; then
      printf "Enter Author Name (e.g., John Doe): "
      read -r _AUTHOR_NAME
    else
      log_error "Error: --author is required in non-interactive mode."
      exit 1
    fi
  fi

  if [ -z "$_GITHUB_ORG" ]; then
    if [ "$_IS_TTY" -eq 1 ] && [ "$_AUTO_CONFIRM" -eq 0 ]; then
      printf "Enter GitHub Username/Org (e.g., myorg): "
      read -r _GITHUB_ORG
    else
      log_error "Error: --github is required in non-interactive mode."
      exit 1
    fi
  fi

  _OLD_PROJECT="template"
  _OLD_ORG="snowdreamtech"
  _OLD_USER="snowdream"

  # 4. Confirmation
  if [ "$VERBOSE" -ge 1 ]; then
    printf "\n%bConfiguration Summary:%b\n" "${YELLOW}" "${NC}"
    printf "  Project: %b%s%b\n" "${GREEN}" "$_PROJECT_NAME" "${NC}"
    printf "  Author:  %b%s%b\n" "${GREEN}" "$_AUTHOR_NAME" "${NC}"
    printf "  GitHub:  %b%s%b\n" "${GREEN}" "$_GITHUB_ORG" "${NC}"
  fi

  if [ "$DRY_RUN" -eq 0 ] && [ "$VERBOSE" -ge 1 ] && [ "$_AUTO_CONFIRM" -eq 0 ]; then
    if [ "$_IS_TTY" -eq 1 ] || [ "$SNOWDREAM_TEST_FORCE_CONFIRM" = "1" ]; then
      printf "\nProceed with hydration? (y/N): "
      read -r _CONFIRM
      case "$_CONFIRM" in
      [yY]*) ;;
      *)
        log_error "Aborted."
        exit 1
        ;;
      esac
    else
      log_info "Non-interactive mode: Proceeding automatically..."
    fi
  fi

  # 5. Replace Placeholders
  log_info "\nStep 1: Replacing placeholders in files..."

  if [ "$DRY_RUN" -eq 1 ]; then
    log_warn "DRY-RUN: Would replace '$_OLD_PROJECT' with '$_PROJECT_NAME' and '$_OLD_ORG/$_OLD_USER' with '$_GITHUB_ORG' in matching files."
  else
    # Use perl for cross-platform compatibility
    find . -type f \
      ! -path "*/.git/*" \
      ! -path "./node_modules/*" \
      ! -path "./.venv/*" \
      ! -path "./scripts/init-project.sh" \
      -exec perl -pi -e "s/$_OLD_PROJECT/$_PROJECT_NAME/g" {} +

    find . -type f \
      ! -path "*/.git/*" \
      ! -path "./node_modules/*" \
      ! -path "./.venv/*" \
      ! -path "./scripts/init-project.sh" \
      ! -path "./scripts/init-project.ps1" \
      ! -path "./scripts/init-project.bat" \
      -exec perl -pi -e "s/$_OLD_ORG|$_OLD_USER/$_GITHUB_ORG/g" {} +
  fi

  # 6. Update LICENSE
  log_info "Step 2: Updating LICENSE..."
  _CURRENT_YEAR=$(date +%Y)
  if [ "$DRY_RUN" -eq 1 ]; then
    log_warn "DRY-RUN: Would update LICENSE copyright to $_CURRENT_YEAR and $_AUTHOR_NAME."
  else
    perl -pi -e "s/Copyright \(c\) \d{4}-present SnowdreamTech Inc\./Copyright (c) $_CURRENT_YEAR-present $_AUTHOR_NAME/g" LICENSE
  fi

  # 7. Git Initialization
  if [ "$DRY_RUN" -eq 0 ] && [ "$VERBOSE" -ge 1 ]; then
    printf "\nRe-initialize Git repository? (y/N): "
    read -r _REINIT_GIT
    case "$_REINIT_GIT" in
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

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake setup%b to install system-level tools.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake install%b to install project dependencies.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
