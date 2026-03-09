#!/bin/sh
# scripts/update.sh - Toolchain Update Manager
# Standardizes the maintenance of global and project-local development toolsets.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Orchestrated updates for Brew, NPM, Python, and Git Hooks.
#   - Operation throttling with 24h cooldown to minimize disruption.
#   - Professional UX with clear update summaries.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Configuration ────────────────────────────────────────────────────────────

# Help Message
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

update_pnpm_global() {
  _T0=$(date +%s)
  if command -v pnpm >/dev/null 2>&1; then
    if check_update_cooldown "pnpm-global"; then
      # Intelligent pnpm update: detects if managed by corepack
      if command -v corepack >/dev/null 2>&1 && pnpm self-update --help 2>&1 | grep -q "corepack" >/dev/null 2>&1; then
        log_info "Updating pnpm (via corepack)..."
        if [ "$DRY_RUN" -eq 1 ]; then
          log_summary "Manager" "pnpm" "⚖️ Previewed" "-" "0"
        else
          if run_quiet corepack prepare pnpm@latest --activate; then
            save_update_timestamp "pnpm-global"
            log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0))"
          else
            log_summary "Manager" "pnpm" "❌ Failed" "-" "$(($(date +%s) - _T0))"
          fi
        fi
      else
        if [ "$DRY_RUN" -eq 1 ]; then
          log_summary "Manager" "pnpm" "⚖️ Previewed" "-" "0"
        else
          log_info "Updating pnpm (self-update)..."
          if _OUT=$(run_quiet pnpm self-update 2>&1); then
            save_update_timestamp "pnpm-global"
            log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0))"
          elif echo "$_OUT" | grep -q "ERR_PNPM_CANT_SELF_UPDATE_IN_COREPACK"; then
            log_warn "pnpm is managed by corepack. Switching to corepack update..."
            if run_quiet corepack prepare pnpm@latest --activate; then
              save_update_timestamp "pnpm-global"
              log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0))"
            else
              log_summary "Manager" "pnpm" "❌ Failed" "-" "$(($(date +%s) - _T0))"
            fi
          else
            log_summary "Manager" "pnpm" "❌ Failed" "-" "$(($(date +%s) - _T0))"
          fi
        fi
      fi
    else
      log_summary "Manager" "pnpm" "✅ Up-to-date (Cooldown)" "$(get_version pnpm)" "0"
    fi
  fi
}

update_pnpm_project() {
  _T0=$(date +%s)
  if [ -f "pnpm-lock.yaml" ]; then
    if command -v pnpm >/dev/null 2>&1; then
      log_info "Updating project dependencies (pnpm update)..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Project" "pnpm-deps" "⚖️ Previewed" "-" "0"
      else
        if run_quiet pnpm update; then
          log_summary "Project" "pnpm-deps" "✅ Updated" "-" "$(($(date +%s) - _T0))"
        else
          log_summary "Project" "pnpm-deps" "❌ Failed" "-" "$(($(date +%s) - _T0))"
        fi
      fi
    else
      log_warn "pnpm-lock.yaml found but pnpm command is missing. Skipping."
      log_summary "Project" "pnpm-deps" "⚠️ Missing" "-" "0"
    fi
  fi
}

update_python_venv() {
  _T0=$(date +%s)
  if [ -d "$VENV" ]; then
    if [ -x "$VENV/bin/pip" ]; then
      log_info "Updating Python environment ($VENV)..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Project" "Python-Venv" "⚖️ Previewed" "-" "0"
      else
        _STAT="✅ Updated"
        run_quiet "$VENV/bin/pip" install --upgrade pip || _STAT="⚠️ Warning"
        if [ -f "$REQUIREMENTS_TXT" ]; then
          run_quiet "$VENV/bin/pip" install -r "$REQUIREMENTS_TXT" --upgrade || _STAT="❌ Failed"
        fi
        log_summary "Project" "Python-Venv" "$_STAT" "$(get_version "$VENV/bin/pip")" "$(($(date +%s) - _T0))"
      fi
    else
      log_warn "Virtualenv directory $VENV exists but pip is missing/not executable. Skipping."
      log_summary "Project" "Python-Venv" "⚠️ Missing" "-" "0"
    fi
  fi
}

update_homebrew() {
  _T0=$(date +%s)
  if command -v brew >/dev/null 2>&1; then
    if check_update_cooldown "homebrew"; then
      log_info "Updating Homebrew..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Manager" "Homebrew" "⚖️ Previewed" "-" "0"
      else
        if run_quiet brew update; then
          save_update_timestamp "homebrew"
          log_summary "Manager" "Homebrew" "✅ Updated" "-" "$(($(date +%s) - _T0))"
        else
          log_summary "Manager" "Homebrew" "❌ Failed" "-" "$(($(date +%s) - _T0))"
        fi
      fi
    else
      log_summary "Manager" "Homebrew" "✅ Up-to-date (Cooldown)" "-" "0"
    fi
  fi
}

update_macports() {
  _T0=$(date +%s)
  if command -v port >/dev/null 2>&1; then
    if check_update_cooldown "macports"; then
      log_info "Updating MacPorts (requires sudo)..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Manager" "MacPorts" "⚖️ Previewed" "-" "0"
      else
        if sudo port selfupdate && sudo port -N upgrade outdated; then
          save_update_timestamp "macports"
          log_summary "Manager" "MacPorts" "✅ Updated" "-" "$(($(date +%s) - _T0))"
        else
          log_summary "Manager" "MacPorts" "❌ Failed" "-" "$(($(date +%s) - _T0))"
        fi
      fi
    else
      log_summary "Manager" "MacPorts" "✅ Up-to-date (Cooldown)" "-" "0"
    fi
  fi
}

update_ruby_gems() {
  _T0=$(date +%s)
  if command -v gem >/dev/null 2>&1; then
    if gem list rubocop -i >/dev/null 2>&1; then
      if check_update_cooldown "rubocop"; then
        log_info "Updating Rubocop gem..."
        if [ "$DRY_RUN" -eq 1 ]; then
          log_summary "Lint Tool" "Rubocop" "⚖️ Previewed" "-" "0"
        else
          if run_quiet gem update rubocop --user-install --no-document --quiet; then
            save_update_timestamp "rubocop"
            log_summary "Lint Tool" "Rubocop" "✅ Updated" "$(get_version rubocop)" "$(($(date +%s) - _T0))"
          else
            log_summary "Lint Tool" "Rubocop" "❌ Failed" "-" "$(($(date +%s) - _T0))"
          fi
        fi
      else
        log_summary "Lint Tool" "Rubocop" "✅ Up-to-date (Cooldown)" "$(get_version rubocop)" "0"
      fi
    fi
  fi
}

update_pre_commit() {
  _T0=$(date +%s)
  _BIN=""
  if [ -x "$VENV/bin/pre-commit" ]; then
    _BIN="$VENV/bin/pre-commit"
  elif command -v pre-commit >/dev/null 2>&1; then _BIN="pre-commit"; fi

  if [ -n "$_BIN" ] && [ -f ".pre-commit-config.yaml" ]; then
    if check_update_cooldown "pre-commit"; then
      log_info "Updating pre-commit hooks..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Other" "Hooks" "⚖️ Previewed" "-" "0"
      else
        if run_quiet "$_BIN" autoupdate; then
          save_update_timestamp "pre-commit"
          log_summary "Other" "Hooks" "✅ Updated" "$(get_version "$_BIN")" "$(($(date +%s) - _T0))"
        else
          log_summary "Other" "Hooks" "❌ Failed" "-" "$(($(date +%s) - _T0))"
        fi
      fi
    else
      log_summary "Other" "Hooks" "✅ Up-to-date (Cooldown)" "$(get_version "$_BIN")" "0"
    fi
  fi
  return 0
}

update_go_mod() {
  _T0=$(date +%s)
  if [ -f "go.mod" ]; then
    if command -v go >/dev/null 2>&1; then
      log_info "Updating Go workspace (go get -u)..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Project" "Go-Mod" "⚖️ Previewed" "-" "0"
      else
        if run_quiet go get -u ./... && run_quiet go mod tidy; then
          log_summary "Project" "Go-Mod" "✅ Updated" "$(get_version go)" "$(($(date +%s) - _T0))"
        else
          log_summary "Project" "Go-Mod" "❌ Failed" "-" "$(($(date +%s) - _T0))"
        fi
      fi
    else
      log_warn "go.mod found but go command is missing. Skipping."
      log_summary "Project" "Go-Mod" "⚠️ Missing" "-" "0"
    fi
  fi
}

update_cargo_deps() {
  _T0=$(date +%s)
  if [ -f "Cargo.toml" ]; then
    if command -v cargo >/dev/null 2>&1; then
      log_info "Updating Rust dependencies (cargo update)..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Project" "Cargo-Deps" "⚖️ Previewed" "-" "0"
      else
        if run_quiet cargo update; then
          log_summary "Project" "Cargo-Deps" "✅ Updated" "$(get_version cargo)" "$(($(date +%s) - _T0))"
        else
          log_summary "Project" "Cargo-Deps" "❌ Failed" "-" "$(($(date +%s) - _T0))"
        fi
      fi
    else
      log_warn "Cargo.toml found but cargo command is missing. Skipping."
      log_summary "Project" "Cargo-Deps" "⚠️ Missing" "-" "0"
    fi
  fi
}

# Argument parsing
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  _START_TIME=$(date +%s)

  # Initialize Summary File if not already done
  if [ -z "$SETUP_SUMMARY_FILE" ]; then
    SETUP_SUMMARY_FILE=$(mktemp)
    export SETUP_SUMMARY_FILE
    _CREATED_SUMMARY=true

    {
      printf "### Update Execution Summary\n\n"
      printf "| Category | Module | Status | Version | Time |\n"
      printf "| :--- | :--- | :--- | :--- | :--- |\n"
    } >"$SETUP_SUMMARY_FILE"
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
  if [ "$_CREATED_SUMMARY" = "true" ]; then
    _TOTAL_DUR=$(($(date +%s) - _START_TIME))
    printf "\n**Total Duration: %ss**\n" "$_TOTAL_DUR" >>"$SETUP_SUMMARY_FILE"

    printf "\n"
    printf "\n"
    cat "$SETUP_SUMMARY_FILE"
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
      cat "$SETUP_SUMMARY_FILE" >>"$GITHUB_STEP_SUMMARY"
    fi
    rm -f "$SETUP_SUMMARY_FILE"
  fi

  if [ "$_IS_TOP_LEVEL" = "true" ]; then
    log_success "\n✨ All tools and dependencies updated successfully!"

    # Next Actions
    if [ "$DRY_RUN" -eq 0 ]; then
      printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
      printf "  - Run %bmake install%b to synchronize project dependencies.\n" "${GREEN}" "${NC}"
      printf "  - Run %bmake verify%b to ensure environment stability.\n" "${GREEN}" "${NC}"
    fi
  fi
}

main "$@"
