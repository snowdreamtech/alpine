#!/bin/sh
# scripts/init-project.sh - Project Branding Hydrator
# Customizes the template for a new project by replacing branded placeholders.
#
# Usage:
#   sh scripts/init-project.sh [OPTIONS]
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Safe placeholder replacement across the entire codebase.
#   - Integrated Git re-initialization and remote cleanup.
#   - Professional UX for streamlined project onboarding.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Purpose: Main entry point for project hydration.
#          Collects project metadata and performs global placeholder replacement.
# Params:
#   $@ - Command line arguments (--project, --author, --github, -y)
# Examples:
#   sh scripts/init-project.sh --project=my-app --author="John Doe" --github=myorg -y
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _PROJECT_NAME_HYD=""
  local _AUTHOR_NAME_HYD=""
  local _GITHUB_ORG_HYD=""
  local _AUTO_CON_HYD=0

  parse_common_args "$@"

  local _arg_hyd
  for _arg_hyd in "$@"; do
    case "$_arg_hyd" in
    --project=*) _PROJECT_NAME_HYD="${_arg_hyd#*=}" ;;
    --author=*) _AUTHOR_NAME_HYD="${_arg_hyd#*=}" ;;
    --github=*) _GITHUB_ORG_HYD="${_arg_hyd#*=}" ;;
    -y | --yes) _AUTO_CON_HYD=1 ;;
    esac
  done

  # Check if we are running in a terminal
  local _IS_TTY_HYD=0
  [ -t 0 ] && _IS_TTY_HYD=1

  if [ "$VERBOSE" -ge 1 ]; then
    printf "%b💧 Project Hydration: Converting Template to Project...%b\n\n" "${BLUE}" "${NC}"
  fi

  # 3. Input Collection (Interactive fallback or validation)
  if [ -z "$_PROJECT_NAME_HYD" ]; then
    if [ "$_IS_TTY_HYD" -eq 1 ] && [ "$_AUTO_CON_HYD" -eq 0 ]; then
      printf "Enter Project Name (e.g., my-awesome-app): "
      read -r _PROJECT_NAME_HYD
    else
      log_error "Error: --project is required in non-interactive mode."
      exit 1
    fi
  fi

  if [ -z "$_AUTHOR_NAME_HYD" ]; then
    if [ "$_IS_TTY_HYD" -eq 1 ] && [ "$_AUTO_CON_HYD" -eq 0 ]; then
      printf "Enter Author Name (e.g., John Doe): "
      read -r _AUTHOR_NAME_HYD
    else
      log_error "Error: --author is required in non-interactive mode."
      exit 1
    fi
  fi

  if [ -z "$_GITHUB_ORG_HYD" ]; then
    if [ "$_IS_TTY_HYD" -eq 1 ] && [ "$_AUTO_CON_HYD" -eq 0 ]; then
      printf "Enter GitHub Username/Org (e.g., myorg): "
      read -r _GITHUB_ORG_HYD
    else
      log_error "Error: --github is required in non-interactive mode."
      exit 1
    fi
  fi

  local _OLD_PROJ_REF="template"
  local _OLD_ORG_REF="snowdreamtech"
  local _OLD_USER_REF="snowdream"

  # 4. Confirmation
  if [ "$VERBOSE" -ge 1 ]; then
    printf "\n%bConfiguration Summary:%b\n" "${YELLOW}" "${NC}"
    printf "  Project: %b%s%b\n" "${GREEN}" "$_PROJECT_NAME_HYD" "${NC}"
    printf "  Author:  %b%s%b\n" "${GREEN}" "$_AUTHOR_NAME_HYD" "${NC}"
    printf "  GitHub:  %b%s%b\n" "${GREEN}" "$_GITHUB_ORG_HYD" "${NC}"
  fi

  if [ "$DRY_RUN" -eq 0 ] && [ "$VERBOSE" -ge 1 ] && [ "$_AUTO_CON_HYD" -eq 0 ]; then
    if [ "$_IS_TTY_HYD" -eq 1 ] || [ "$SNOWDREAM_TEST_FORCE_CONFIRM" = "1" ]; then
      printf "\nProceed with hydration? (y/N): "
      local _CONFIRM_HYD
      read -r _CONFIRM_HYD
      case "$_CONFIRM_HYD" in
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
    log_warn "DRY-RUN: Would replace '$_OLD_PROJ_REF' with '$_PROJECT_NAME_HYD' and '$_OLD_ORG_REF/$_OLD_USER_REF' with '$_GITHUB_ORG_HYD' in matching files."
  else
    # Use perl for cross-platform compatibility
    find . -type f \
      ! -path "*/.git/*" \
      ! -path "./node_modules/*" \
      ! -path "./.venv/*" \
      ! -path "./scripts/init-project.sh" \
      -exec perl -pi -e "s/$_OLD_PROJ_REF/$_PROJECT_NAME_HYD/g" {} +

    find . -type f \
      ! -path "*/.git/*" \
      ! -path "./node_modules/*" \
      ! -path "./.venv/*" \
      ! -path "./scripts/init-project.sh" \
      ! -path "./scripts/init-project.ps1" \
      ! -path "./scripts/init-project.bat" \
      -exec perl -pi -e "s/$_OLD_ORG_REF|$_OLD_USER_REF/$_GITHUB_ORG_HYD/g" {} +
  fi

  # 6. Update LICENSE
  log_info "Step 2: Updating LICENSE..."
  local _CUR_YEAR_HYD
  _CUR_YEAR_HYD=$(date +%Y)
  if [ "$DRY_RUN" -eq 1 ]; then
    log_warn "DRY-RUN: Would update LICENSE copyright to $_CUR_YEAR_HYD and $_AUTHOR_NAME_HYD."
  else
    perl -pi -e "s/Copyright \(c\) \d{4}-present SnowdreamTech Inc\./Copyright (c) $_CUR_YEAR_HYD-present $_AUTHOR_NAME_HYD/g" LICENSE
  fi

  # 7. Git Initialization
  if [ "$DRY_RUN" -eq 0 ] && [ "$VERBOSE" -ge 1 ]; then
    printf "\nRe-initialize Git repository? (y/N): "
    local _REINIT_GIT_HYD
    read -r _REINIT_GIT_HYD
    case "$_REINIT_GIT_HYD" in
    [yY]*)
      log_info "Step 3: Re-initializing Git..."
      rm -rf .git
      git init
      git add .
      git commit -m "initial commit: project hydrated from template"
      ;;
    *) ;;
    esac
  elif [ "$DRY_RUN" -eq 1 ]; then
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
