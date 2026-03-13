#!/bin/sh
# scripts/update.sh - Toolchain Update Manager
#
# Purpose:
#   Standardizes the maintenance of global and project-local development toolsets.
#   Orchestrates updates for Brew, NPM, Python, and Git Hooks in a unified CLI.
#
# Usage:
#   sh scripts/update.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Network), Rule 05 (Dependencies), Rule 08 (Dev Env).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Unified reporting for multi-stack toolchain maintenance.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Configuration ────────────────────────────────────────────────────────────

# Purpose: Displays usage information for the update manager.
# Examples:
#   show_help
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Standardizes updating of global and project tools.

Options:
  --dry-run        Preview updates without applying them.
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Updates global pnpm installation via corepack or self-update.
# Examples:
#   update_pnpm_global
update_pnpm_global() {
  local _T0_PNPM_G
  _T0_PNPM_G=$(date +%s)
  if command -v pnpm >/dev/null 2>&1; then
    if check_update_cooldown "pnpm-global"; then
      # Intelligent pnpm update: detects if managed by corepack
      if command -v corepack >/dev/null 2>&1 && pnpm self-update --help 2>&1 | grep -q "corepack" >/dev/null 2>&1; then
        log_info "Updating pnpm (via corepack)..."
        if [ "${DRY_RUN:-0}" -eq 1 ]; then
          log_summary "Manager" "pnpm" "⚖️ Previewed" "-" "0"
        else
          if run_quiet corepack prepare pnpm@latest --activate; then
            save_update_timestamp "pnpm-global"
            log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0_PNPM_G))"
          else
            log_summary "Manager" "pnpm" "❌ Failed" "-" "$(($(date +%s) - _T0_PNPM_G))"
          fi
        fi
      else
        if [ "${DRY_RUN:-0}" -eq 1 ]; then
          log_summary "Manager" "pnpm" "⚖️ Previewed" "-" "0"
        else
          log_info "Updating pnpm (self-update)..."
          local _OUT_PNPM_G
          if _OUT_PNPM_G=$(run_quiet pnpm self-update 2>&1); then
            save_update_timestamp "pnpm-global"
            log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0_PNPM_G))"
          elif echo "$_OUT_PNPM_G" | grep -q "ERR_PNPM_CANT_SELF_UPDATE_IN_COREPACK"; then
            log_warn "pnpm is managed by corepack. Switching to corepack update..."
            if run_quiet corepack prepare pnpm@latest --activate; then
              save_update_timestamp "pnpm-global"
              log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0_PNPM_G))"
            else
              log_summary "Manager" "pnpm" "❌ Failed" "-" "$(($(date +%s) - _T0_PNPM_G))"
            fi
          else
            log_summary "Manager" "pnpm" "❌ Failed" "-" "$(($(date +%s) - _T0_PNPM_G))"
          fi
        fi
      fi
    else
      log_summary "Manager" "pnpm" "✅ Up-to-date (Cooldown)" "$(get_version pnpm)" "0"
    fi
  fi
}

# Purpose: Updates project dependencies using pnpm update.
# Examples:
#   update_pnpm_project
update_pnpm_project() {
  local _T0_PNPM_P
  _T0_PNPM_P=$(date +%s)
  if [ -f "pnpm-lock.yaml" ]; then
    if command -v pnpm >/dev/null 2>&1; then
      log_info "Updating project dependencies (pnpm update)..."
      if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_summary "Project" "pnpm-deps" "⚖️ Previewed" "-" "0"
      else
        if run_quiet pnpm update; then
          log_summary "Project" "pnpm-deps" "✅ Updated" "-" "$(($(date +%s) - _T0_PNPM_P))"
        else
          log_summary "Project" "pnpm-deps" "❌ Failed" "-" "$(($(date +%s) - _T0_PNPM_P))"
        fi
      fi
    else
      log_warn "pnpm-lock.yaml found but pnpm command is missing. Skipping."
      log_summary "Project" "pnpm-deps" "⚠️ Missing" "-" "0"
    fi
  fi
}

# Purpose: Updates pip and project dependencies within the virtual environment.
# Examples:
#   update_python_venv
update_python_venv() {
  local _T0_PY
  _T0_PY=$(date +%s)
  if [ -d "$VENV" ]; then
    if [ -x "$VENV/bin/pip" ]; then
      log_info "Updating Python environment ($VENV)..."
      if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_summary "Project" "Python-Venv" "⚖️ Previewed" "-" "0"
      else
        local _STAT_PY="✅ Updated"
        run_quiet "$VENV/bin/pip" install --upgrade pip || _STAT_PY="⚠️ Warning"
        if [ -f "$REQUIREMENTS_TXT" ]; then
          run_quiet "$VENV/bin/pip" install -r "$REQUIREMENTS_TXT" --upgrade || _STAT_PY="❌ Failed"
        fi
        log_summary "Project" "Python-Venv" "$_STAT_PY" "$(get_version "$VENV/bin/pip")" "$(($(date +%s) - _T0_PY))"
      fi
    else
      log_warn "Virtualenv directory $VENV exists but pip is missing/not executable. Skipping."
      log_summary "Project" "Python-Venv" "⚠️ Missing" "-" "0"
    fi
  fi
}

# Purpose: Updates Homebrew formulae and casks.
# Examples:
#   update_homebrew
update_homebrew() {
  local _T0_BREW
  _T0_BREW=$(date +%s)
  if command -v brew >/dev/null 2>&1; then
    if check_update_cooldown "homebrew"; then
      log_info "Updating Homebrew..."
      if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_summary "Manager" "Homebrew" "⚖️ Previewed" "-" "0"
      else
        if run_quiet brew update; then
          save_update_timestamp "homebrew"
          log_summary "Manager" "Homebrew" "✅ Updated" "-" "$(($(date +%s) - _T0_BREW))"
        else
          log_summary "Manager" "Homebrew" "❌ Failed" "-" "$(($(date +%s) - _T0_BREW))"
        fi
      fi
    else
      log_summary "Manager" "Homebrew" "✅ Up-to-date (Cooldown)" "-" "0"
    fi
  fi
}

# Purpose: Updates MacPorts and outdated ports.
# Examples:
#   update_macports
update_macports() {
  local _T0_PORT
  _T0_PORT=$(date +%s)
  if command -v port >/dev/null 2>&1; then
    if check_update_cooldown "macports"; then
      log_info "Updating MacPorts (requires sudo)..."
      if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_summary "Manager" "MacPorts" "⚖️ Previewed" "-" "0"
      else
        if sudo port selfupdate && sudo port -N upgrade outdated; then
          save_update_timestamp "macports"
          log_summary "Manager" "MacPorts" "✅ Updated" "-" "$(($(date +%s) - _T0_PORT))"
        else
          log_summary "Manager" "MacPorts" "❌ Failed" "-" "$(($(date +%s) - _T0_PORT))"
        fi
      fi
    else
      log_summary "Manager" "MacPorts" "✅ Up-to-date (Cooldown)" "-" "0"
    fi
  fi
}

# Purpose: Updates Rubocop gem if installed.
# Examples:
#   update_ruby_gems
update_ruby_gems() {
  local _T0_RUBY
  _T0_RUBY=$(date +%s)
  if command -v gem >/dev/null 2>&1; then
    if gem list rubocop -i >/dev/null 2>&1; then
      if check_update_cooldown "rubocop"; then
        log_info "Updating Rubocop gem..."
        if [ "${DRY_RUN:-0}" -eq 1 ]; then
          log_summary "Lint Tool" "Rubocop" "⚖️ Previewed" "-" "0"
        else
          if run_quiet gem update rubocop --user-install --no-document --quiet; then
            save_update_timestamp "rubocop"
            log_summary "Lint Tool" "Rubocop" "✅ Updated" "$(get_version rubocop)" "$(($(date +%s) - _T0_RUBY))"
          else
            log_summary "Lint Tool" "Rubocop" "❌ Failed" "-" "$(($(date +%s) - _T0_RUBY))"
          fi
        fi
      else
        log_summary "Lint Tool" "Rubocop" "✅ Up-to-date (Cooldown)" "$(get_version rubocop)" "0"
      fi
    fi
  fi
}

# Purpose: Updates pre-commit hooks specified in the project configuration.
# Examples:
#   update_pre_commit
update_pre_commit() {
  local _T0_PC
  _T0_PC=$(date +%s)
  local _BIN_PC=""
  if [ -x "$VENV/bin/pre-commit" ]; then
    _BIN_PC="$VENV/bin/pre-commit"
  elif command -v pre-commit >/dev/null 2>&1; then _BIN_PC="pre-commit"; fi

  if [ -n "$_BIN_PC" ] && [ -f ".pre-commit-config.yaml" ]; then
    if check_update_cooldown "pre-commit"; then
      log_info "Updating pre-commit hooks..."
      if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_summary "Other" "Hooks" "⚖️ Previewed" "-" "0"
      else
        if run_quiet "$_BIN_PC" autoupdate; then
          save_update_timestamp "pre-commit"
          log_summary "Other" "Hooks" "✅ Updated" "$(get_version "$_BIN_PC")" "$(($(date +%s) - _T0_PC))"
        else
          log_summary "Other" "Hooks" "❌ Failed" "-" "$(($(date +%s) - _T0_PC))"
        fi
      fi
    else
      log_summary "Other" "Hooks" "✅ Up-to-date (Cooldown)" "$(get_version "$_BIN_PC")" "0"
    fi
  fi
}

# Purpose: Updates Go project dependencies.
# Examples:
#   update_go_mod
update_go_mod() {
  local _T0_GO
  _T0_GO=$(date +%s)
  if [ -f "go.mod" ]; then
    if command -v go >/dev/null 2>&1; then
      log_info "Updating Go workspace (go get -u)..."
      if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_summary "Project" "Go-Mod" "⚖️ Previewed" "-" "0"
      else
        if run_quiet go get -u ./... && run_quiet go mod tidy; then
          log_summary "Project" "Go-Mod" "✅ Updated" "$(get_version go)" "$(($(date +%s) - _T0_GO))"
        else
          log_summary "Project" "Go-Mod" "❌ Failed" "-" "$(($(date +%s) - _T0_GO))"
        fi
      fi
    else
      log_warn "go.mod found but go command is missing. Skipping."
      log_summary "Project" "Go-Mod" "⚠️ Missing" "-" "0"
    fi
  fi
}

# Purpose: Updates Rust project dependencies.
# Examples:
#   update_cargo_deps
update_cargo_deps() {
  local _T0_CARGO
  _T0_CARGO=$(date +%s)
  if [ -f "Cargo.toml" ]; then
    if command -v cargo >/dev/null 2>&1; then
      log_info "Updating Rust dependencies (cargo update)..."
      if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_summary "Project" "Cargo-Deps" "⚖️ Previewed" "-" "0"
      else
        if run_quiet cargo update; then
          log_summary "Project" "Cargo-Deps" "✅ Updated" "$(get_version cargo)" "$(($(date +%s) - _T0_CARGO))"
        else
          log_summary "Project" "Cargo-Deps" "❌ Failed" "-" "$(($(date +%s) - _T0_CARGO))"
        fi
      fi
    else
      log_warn "Cargo.toml found but cargo command is missing. Skipping."
      log_summary "Project" "Cargo-Deps" "⚠️ Missing" "-" "0"
    fi
  fi
}

# Purpose: Main entry point for the toolchain update manager.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --dry-run
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  local _START_TIME_M
  _START_TIME_M=$(date +%s)

  # Initialize Summary File if not already done
  local _CREATED_SUMMARY_M=false
  if [ -z "$SETUP_SUMMARY_FILE" ]; then
    SETUP_SUMMARY_FILE=$(mktemp)
    export SETUP_SUMMARY_FILE
    _CREATED_SUMMARY_M=true

    if [ "$_UPDATE_SUMMARY_INITIALIZED" != "true" ] && ! check_ci_summary "### Update Execution Summary"; then
      {
        printf "### Update Execution Summary\n\n"
      } >"$SETUP_SUMMARY_FILE"
      [ -n "$GITHUB_ENV" ] && echo "_UPDATE_SUMMARY_INITIALIZED=true" >>"$GITHUB_ENV"
      export _UPDATE_SUMMARY_INITIALIZED=true
    else
      touch "$SETUP_SUMMARY_FILE"
    fi

    # Provide table header if not already present
    if [ "$_SUMMARY_TABLE_HEADER_SENTINEL" != "true" ] && ! check_ci_summary "| Category | Module | Status |"; then
      {
        printf "| Category | Module | Status | Version | Time |\n"
        printf "| :--- | :--- | :--- | :--- | :--- |\n"
      } >>"$SETUP_SUMMARY_FILE"
      [ -n "$GITHUB_ENV" ] && echo "_SUMMARY_TABLE_HEADER_SENTINEL=true" >>"$GITHUB_ENV"
      export _SUMMARY_TABLE_HEADER_SENTINEL=true
    fi
  fi

  update_homebrew
  update_macports
  update_pnpm_global
  update_pnpm_project
  update_python_venv
  update_go_mod
  update_cargo_deps
  update_ruby_gems
  update_pre_commit

  # Optional: run npm update if defined
  run_npm_script "update"

  # Final Output Management
  if [ "$_CREATED_SUMMARY_M" = "true" ]; then
    local _TOTAL_DUR_M
    _TOTAL_DUR_M=$(($(date +%s) - _START_TIME_M))
    printf "\n**Total Duration: %ss**\n" "$_TOTAL_DUR_M" >>"$SETUP_SUMMARY_FILE"

    printf "\n\n"
    cat "$SETUP_SUMMARY_FILE"
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
      cat "$SETUP_SUMMARY_FILE" >>"$GITHUB_STEP_SUMMARY"
    fi
    rm -f "$SETUP_SUMMARY_FILE"
  fi

  if [ "$_IS_TOP_LEVEL" = "true" ]; then
    log_success "\n✨ All tools and dependencies updated successfully!"

    # 6. Standardized Next Actions
    if [ "${DRY_RUN:-0}" -eq 0 ]; then
      printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
      printf "  - Run %bmake install%b to synchronize project dependencies.\n" "${GREEN}" "${NC}"
      printf "  - Run %bmake verify%b to ensure environment health and stability.\n" "${GREEN}" "${NC}"
    fi
  fi
}

main "$@"
