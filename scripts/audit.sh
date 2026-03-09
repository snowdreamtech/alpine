#!/bin/sh
# scripts/audit.sh - Security Auditor
# Standardizes execution of security scans (gitleaks, npm audit, pip-audit, osv-scanner, etc.).

# Note: We do NOT set -e here because we want to run all audit modules even if some fail.
# We will track overall exit status manually.
# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  _OVERALL_EXIT=0
  _START_=$(date +%s)

  # Initialize Summary File if not already done
  if [ -z "$SETUP_SUMMARY_FILE" ]; then
    SETUP_SUMMARY_FILE=$(mktemp)
    export SETUP_SUMMARY_FILE
    _CREATED_SUMMARY=true

    {
      printf "### Security Audit Execution Summary\n\n"
      printf "| Category | Module | Status | Version | Time |\n"
      printf "| :--- | :--- | :--- | :--- | :--- |\n"
    } >"$SETUP_SUMMARY_FILE"
  fi

  # 3. Secrets Scanning
  if run_quiet command -v gitleaks; then
    _T0=$(date +%s)
    log_info "── Scanning for Secrets (gitleaks) ──"
    if [ "$DRY_RUN" -eq 1 ]; then
      log_success "DRY-RUN: Would run gitleaks detect"
      log_summary "Security" "gitleaks" "⚖️ Previewed" "-" "0"
    else
      if run_quiet gitleaks detect --source . --verbose; then
        log_summary "Security" "gitleaks" "✅ Clean" "$(get_version gitleaks)" "$(($(date +%s) - _T0))"
      else
        log_summary "Security" "gitleaks" "❌ Leaks Found" "$(get_version gitleaks)" "$(($(date +%s) - _T0))"
        _OVERALL_EXIT=1
      fi
    fi
  fi

  # 4. GitHub Actions Security
  if [ -d ".github/workflows" ]; then
    _T0=$(date +%s)
    log_info "\n── Auditing GitHub Actions (zizmor) ──"
    if run_quiet command -v zizmor; then
      if [ "$DRY_RUN" -eq 1 ]; then
        log_success "DRY-RUN: Would run zizmor"
        log_summary "GitHub" "zizmor" "⚖️ Previewed" "-" "0"
      else
        if run_quiet zizmor . --format plain; then
          log_summary "GitHub" "zizmor" "✅ Secure" "$(get_version zizmor)" "$(($(date +%s) - _T0))"
        else
          log_summary "GitHub" "zizmor" "❌ Vulnerable" "$(get_version zizmor)" "$(($(date +%s) - _T0))"
          _OVERALL_EXIT=1
        fi
      fi
    fi
  fi

  # 5. Dependency Audits (Node.js)
  if [ -f "$PACKAGE_JSON" ]; then
    _T0=$(date +%s)
    log_info "\n── Auditing Node.js dependencies ($NPM audit) ──"
    if [ "$DRY_RUN" -eq 1 ]; then
      log_success "DRY-RUN: Would run $NPM audit"
      log_summary "Node.js" "$NPM-audit" "⚖️ Previewed" "-" "0"
    else
      _REG_ARG=""
      if [ "$NPM" = "pnpm" ] || [ "$NPM" = "npm" ]; then
        _REG_ARG="--registry=https://registry.npmjs.org"
      fi

      if run_quiet "$NPM" audit $_REG_ARG; then
        log_summary "Node.js" "$NPM-audit" "✅ Secure" "$(get_version "$NPM")" "$(($(date +%s) - _T0))"
      else
        log_summary "Node.js" "$NPM-audit" "❌ Vulnerable" "$(get_version "$NPM")" "$(($(date +%s) - _T0))"
        _OVERALL_EXIT=1
      fi
    fi
  fi

  # 6. Dependency Audits (Python)
  if [ -f "$REQUIREMENTS_TXT" ] || [ -f "requirements.txt" ] || [ -f "$PYPROJECT_TOML" ]; then
    _T0=$(date +%s)
    log_info "\n── Auditing Python dependencies (pip-audit) ──"
    _PIPAUDIT=""
    if [ -x "$VENV/bin/pip-audit" ]; then
      _PIPAUDIT="$VENV/bin/pip-audit"
    elif command -v pip-audit >/dev/null 2>&1; then
      _PIPAUDIT="pip-audit"
    fi

    if [ -n "$_PIPAUDIT" ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        log_success "DRY-RUN: Would run $_PIPAUDIT"
        log_summary "Python" "pip-audit" "⚖️ Previewed" "-" "0"
      else
        _V=$(get_version "$_PIPAUDIT")
        if run_quiet "$_PIPAUDIT"; then
          log_summary "Python" "pip-audit" "✅ Secure" "$_V" "$(($(date +%s) - _T0))"
        else
          log_summary "Python" "pip-audit" "❌ Vulnerable" "$_V" "$(($(date +%s) - _T0))"
          _OVERALL_EXIT=1
        fi
      fi
    else
      log_warn "pip-audit not found. Run 'make setup' to install it."
      log_summary "Python" "pip-audit" "⚠️ Missing" "-" "0"
    fi
  fi

  # 7. Multi-Stack Audit (OSV-Scanner)
  if run_quiet command -v osv-scanner; then
    _T0=$(date +%s)
    log_info "\n── Generic Vulnerability Scan (osv-scanner) ──"
    if [ "$DRY_RUN" -eq 1 ]; then
      log_success "DRY-RUN: Would run osv-scanner"
      log_summary "Security" "osv-scanner" "⚖️ Previewed" "-" "0"
    else
      if run_quiet osv-scanner -r .; then
        log_summary "Security" "osv-scanner" "✅ Secure" "$(get_version osv-scanner)" "$(($(date +%s) - _T0))"
      else
        log_summary "Security" "osv-scanner" "❌ Vulnerable" "$(get_version osv-scanner)" "$(($(date +%s) - _T0))"
        _OVERALL_EXIT=1
      fi
    fi
  fi

  # 8. Stack Specific (Go/Rust/Containers)
  if [ -f "go.mod" ]; then
    _T0=$(date +%s)
    log_info "\n── Auditing Go dependencies (govulncheck) ──"
    if run_quiet command -v govulncheck; then
      if [ "$DRY_RUN" -eq 1 ]; then
        log_success "DRY-RUN: Would run govulncheck"
        log_summary "Go" "govulncheck" "⚖️ Previewed" "-" "0"
      else
        if run_quiet govulncheck ./...; then
          log_summary "Go" "govulncheck" "✅ Secure" "$(get_version govulncheck)" "$(($(date +%s) - _T0))"
        else
          log_summary "Go" "govulncheck" "❌ Vulnerable" "$(get_version govulncheck)" "$(($(date +%s) - _T0))"
          _OVERALL_EXIT=1
        fi
      fi
    else
      log_warn "govulncheck not found. Skipping Go audit."
      log_summary "Go" "govulncheck" "⚠️ Missing" "-" "0"
    fi
  fi

  if [ -f "Cargo.toml" ]; then
    _T0=$(date +%s)
    log_info "\n── Auditing Rust dependencies (cargo audit) ──"
    if run_quiet command -v cargo && run_quiet cargo audit --version; then
      if [ "$DRY_RUN" -eq 1 ]; then
        log_success "DRY-RUN: Would run cargo audit"
        log_summary "Rust" "cargo-audit" "⚖️ Previewed" "-" "0"
      else
        if run_quiet cargo audit; then
          log_summary "Rust" "cargo-audit" "✅ Secure" "$(get_version cargo-audit)" "$(($(date +%s) - _T0))"
        else
          log_summary "Rust" "cargo-audit" "❌ Vulnerable" "$(get_version cargo-audit)" "$(($(date +%s) - _T0))"
          _OVERALL_EXIT=1
        fi
      fi
    else
      log_warn "cargo-audit not found. Skipping Rust audit."
      log_summary "Rust" "cargo-audit" "⚠️ Missing" "-" "0"
    fi
  fi

  if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
    _T0=$(date +%s)
    log_info "\n── Auditing Containers (trivy) ──"
    if run_quiet command -v trivy; then
      if [ "$DRY_RUN" -eq 1 ]; then
        log_success "DRY-RUN: Would run trivy fs ."
        log_summary "DevOps" "trivy" "⚖️ Previewed" "-" "0"
      else
        if run_quiet trivy fs . && run_quiet trivy config .; then
          log_summary "DevOps" "trivy" "✅ Secure" "$(get_version trivy)" "$(($(date +%s) - _T0))"
        else
          log_summary "DevOps" "trivy" "❌ Vulnerable" "$(get_version trivy)" "$(($(date +%s) - _T0))"
          _OVERALL_EXIT=1
        fi
      fi
    else
      log_warn "trivy not found. Skipping container audit."
      log_summary "DevOps" "trivy" "⚠️ Missing" "-" "0"
    fi
  fi

  # ── Final Report ─────────────────────────────────────────────────────────────

  if [ "$_CREATED_SUMMARY" = "true" ]; then
    _TOTAL_DUR=$(($(date +%s) - _START_))
    printf "\n**Total Duration: %ss**\n" "$_TOTAL_DUR" >>"$SETUP_SUMMARY_FILE"

    printf "\n"
    cat "$SETUP_SUMMARY_FILE"
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
      cat "$SETUP_SUMMARY_FILE" >>"$GITHUB_STEP_SUMMARY"
    fi
    rm -f "$SETUP_SUMMARY_FILE"
  fi

  if [ "$_IS_TOP_LEVEL" = "true" ]; then
    if [ "$_OVERALL_EXIT" -eq 0 ]; then
      log_success "\n✨ Security audit finished successfully."
      if [ "$DRY_RUN" -eq 0 ]; then
        printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
        printf "  - Run %bmake commit%b to finalize your changes.\n" "${GREEN}" "${NC}"
        printf "  - Run %bmake build%b to create project artifacts.\n" "${GREEN}" "${NC}"
      fi
    else
      log_error "\n⚠️ Security audit finished with vulnerabilities or leaks found."
    fi
  fi

  exit "$_OVERALL_EXIT"
}

main "$@"
