#!/bin/sh
# scripts/update.sh - Tooling Update Manager
# Standardizes updating of global and project tools (pnpm, pre-commit, brew, etc.).

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

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

# 2. Argument Parsing
parse_common_args "$@"

# ── Functions ────────────────────────────────────────────────────────────────

update_pnpm_global() {
  _T0=$(date +%s)
  if command -v pnpm >/dev/null 2>&1; then
    # Intelligent pnpm update: detects if managed by corepack
    if command -v corepack >/dev/null 2>&1 && pnpm self-update --help 2>&1 | grep -q "corepack" >/dev/null 2>&1; then
      log_info "Updating pnpm (via corepack)..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Manager" "pnpm" "⚖️ Previewed" "-" "0"
      else
        corepack prepare pnpm@latest --activate >/dev/null 2>&1 || true
        log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0))"
      fi
    else
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Manager" "pnpm" "⚖️ Previewed" "-" "0"
      else
        log_info "Updating pnpm (self-update)..."
        if ! pnpm self-update 2>&1 | grep -q "ERR_PNPM_CANT_SELF_UPDATE_IN_COREPACK"; then
          log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0))"
        else
          log_warn "pnpm is managed by corepack. Switching to corepack update..."
          corepack prepare pnpm@latest --activate >/dev/null 2>&1 || true
          log_summary "Manager" "pnpm" "✅ Updated" "$(get_version pnpm)" "$(($(date +%s) - _T0))"
        fi
      fi
    fi
  fi
}

update_pnpm_project() {
  _T0=$(date +%s)
  if [ -f "pnpm-lock.yaml" ]; then
    log_info "Updating project dependencies (pnpm update)..."
    if [ "$DRY_RUN" -eq 1 ]; then
      log_summary "Project" "pnpm-deps" "⚖️ Previewed" "-" "0"
    else
      pnpm update >/dev/null 2>&1 || true
      log_summary "Project" "pnpm-deps" "✅ Updated" "-" "$(($(date +%s) - _T0))"
    fi
  fi
}

update_python_venv() {
  _T0=$(date +%s)
  if [ -d "$VENV" ]; then
    log_info "Updating Python environment ($VENV)..."
    if [ "$DRY_RUN" -eq 1 ]; then
      log_summary "Project" "Python-Venv" "⚖️ Previewed" "-" "0"
    else
      "$VENV/bin/pip" install --upgrade pip >/dev/null 2>&1 || true
      if [ -f "$REQUIREMENTS_TXT" ]; then
        "$VENV/bin/pip" install -r "$REQUIREMENTS_TXT" --upgrade >/dev/null 2>&1 || true
      fi
      log_summary "Project" "Python-Venv" "✅ Updated" "$(get_version "$VENV/bin/pip")" "$(($(date +%s) - _T0))"
    fi
  fi
}

update_homebrew() {
  _T0=$(date +%s)
  if command -v brew >/dev/null 2>&1; then
    log_info "Updating Homebrew..."
    if [ "$DRY_RUN" -eq 1 ]; then
      log_summary "Manager" "Homebrew" "⚖️ Previewed" "-" "0"
    else
      brew update >/dev/null 2>&1 || true
      log_summary "Manager" "Homebrew" "✅ Updated" "-" "$(($(date +%s) - _T0))"
    fi
  fi
}

update_ruby_gems() {
  _T0=$(date +%s)
  if command -v gem >/dev/null 2>&1; then
    if gem list rubocop -i >/dev/null 2>&1; then
      log_info "Updating Rubocop gem..."
      if [ "$DRY_RUN" -eq 1 ]; then
        log_summary "Lint Tool" "Rubocop" "⚖️ Previewed" "-" "0"
      else
        gem update rubocop --user-install --no-document --quiet >/dev/null 2>&1 || true
        log_summary "Lint Tool" "Rubocop" "✅ Updated" "$(get_version rubocop)" "$(($(date +%s) - _T0))"
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
    log_info "Updating pre-commit hooks..."
    if [ "$DRY_RUN" -eq 1 ]; then
      log_summary "Other" "Hooks" "⚖️ Previewed" "-" "0"
    else
      "$_BIN" autoupdate >/dev/null 2>&1 || true
      log_summary "Other" "Hooks" "✅ Updated" "$(get_version "$_BIN")" "$(($(date +%s) - _T0))"
    fi
  fi
}

# ── Main Execution ───────────────────────────────────────────────────────────

_START_TIME=$(date +%s)

# Initialize Summary File if not already done
if [ -z "$SETUP_SUMMARY_FILE" ]; then
  SETUP_SUMMARY_FILE=$(mktemp)
  export SETUP_SUMMARY_FILE
  _IS_TOP_LEVEL=true

  {
    printf "### Update Execution Summary\n\n"
    printf "| Category | Module | Status | Version | Time |\n"
    printf "| :--- | :--- | :--- | :--- | :--- |\n"
  } >"$SETUP_SUMMARY_FILE"
fi

update_homebrew
update_pnpm_global
update_pnpm_project
update_python_venv
update_ruby_gems
update_pre_commit

# Optional: run npm update if defined
run_npm_script "update"

# Final Output Management
if [ "$_IS_TOP_LEVEL" = "true" ]; then
  _TOTAL_DUR=$(($(date +%s) - _START_TIME))
  printf "\n**Total Duration: %ss**\n" "$_TOTAL_DUR" >>"$SETUP_SUMMARY_FILE"

  if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    cat "$SETUP_SUMMARY_FILE" >>"$GITHUB_STEP_SUMMARY"
  else
    printf "\n"
    cat "$SETUP_SUMMARY_FILE"
  fi
  rm -f "$SETUP_SUMMARY_FILE"
  log_success "\n✨ Update process finished."
fi
