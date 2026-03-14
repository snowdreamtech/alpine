#!/bin/sh
# scripts/check-env.sh - Environment Health Auditor
#
# Purpose:
#   Validates the developer workstation against project-required runtimes and tools.
#   Identifies missing dependencies or version mismatches before development starts.
#
# Usage:
#   sh scripts/check-env.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 08 (Dev Env).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Language-aware runtime detection (Node, Go, Python, etc.).
#   - High-performance, non-destructive validation scans.

# set -e removed to allow full diagnostic reporting

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Global State (Scoped to script) ──────────────────────────────────────────
HEALTHY_ST=0
CORE_HEALTHY_ST=0

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Displays usage information for the environment health auditor.
# Examples:
#   show_help
# shellcheck disable=SC2317,SC2329
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Checks the health of the development environment.

Options:
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# Purpose: Internal helper for version checking of a specific tool.
# Params:
#   $1 - Human-readable name
#   $2 - Command to verify
#   $3 - Minimum required version
#   $4 - Version check command
#   $5 - Critical flag (1 for core, 0 for optional)
#   $6 - CI-only flag (1 to skip locally with info, 0 to always check)
# Examples:
#   check_tool_version "Git" "git" "2.30.0" "git --version" 1
check_tool_version() {
  local _LV_NAME="$1"
  local _LV_CMD="$2"
  local _LV_MIN_VER="$3"
  local _LV_VER_CMD="$4"
  local _LV_CRITICAL="${5:-0}"
  local _LV_CI_ONLY="${6:-0}"

  log_debug "Checking $_LV_NAME (min: $_LV_MIN_VER)..."

  if ! command -v "$_LV_CMD" >/dev/null 2>&1; then
    if [ "$_LV_CI_ONLY" -eq 1 ] && ! is_ci_env; then
      log_info "⏭️  $_LV_NAME: CI-only (skipped locally)"
      return 0
    fi
    log_warn "❌ $_LV_NAME: Not found."
    HEALTHY_ST=1
    [ "${_LV_CRITICAL:-0}" -eq 1 ] && CORE_HEALTHY_ST=1
    return 1
  fi

  local _LV_CURRENT_VER
  _LV_CURRENT_VER=$(get_version "$_LV_CMD")
  [ "$_LV_CURRENT_VER" = "-" ] && _LV_CURRENT_VER="0.0"

  # If requirement is empty or -, allow anything
  if [ -z "$_LV_MIN_VER" ] || [ "$_LV_MIN_VER" = "-" ]; then
    log_success "✅ $_LV_NAME: v$_LV_CURRENT_VER (detected)"
    return 0
  fi

  local _LV_LOWER_VER
  _LV_LOWER_VER=$(printf "%s\n%s" "$_LV_MIN_VER" "$_LV_CURRENT_VER" | sort -n -t. -k1,1 -k2,2 -k3,3 | head -n1)

  if [ "$_LV_LOWER_VER" = "$_LV_MIN_VER" ] || [ "$_LV_CURRENT_VER" = "$_LV_MIN_VER" ]; then
    log_success "✅ $_LV_NAME: v$_LV_CURRENT_VER (matches/exceeds v$_LV_MIN_VER)"
  else
    log_warn "⚠️  $_LV_NAME: v$_LV_CURRENT_VER (below recommended v$_LV_MIN_VER)"
    HEALTHY_ST=1
    [ "${_LV_CRITICAL:-0}" -eq 1 ] && CORE_HEALTHY_ST=1
  fi
}

# Purpose: Main entry point for the environment health auditing engine.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --verbose
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "🔍 Checking Development Environment Health...\n"

  # 3. Group: Core Infrastructure
  log_info "── Core Infrastructure ──"
  check_tool_version "Git" "git" "2.30.0" "git --version" 1

  if command -v make >/dev/null 2>&1; then
    log_success "✅ Make: Installed"
  else
    log_error "❌ Make: Not found."
    HEALTHY_ST=1
    CORE_HEALTHY_ST=1
  fi

  if command -v docker >/dev/null 2>&1; then
    log_success "✅ Docker: Installed"
  else
    log_warn "⚠️  Docker: Not found (optional for some tasks)"
  fi
  printf "\n"

  # 4. Group: Language Runtimes (Dynamic Detection)
  log_info "── Language Runtimes ──"

  # Node.js
  if [ -f "$PACKAGE_JSON" ]; then
    check_tool_version "Node.js" "node" "$(get_mise_tool_version node)" "node -v" 1
    check_tool_version "pnpm" "pnpm" "$(get_mise_tool_version pnpm)" "pnpm -v" 1
  else
    log_info "⏭️  Node.js/pnpm: Skipped (no package.json)"
  fi

  # Python
  if has_lang_files "requirements.txt requirements-dev.txt pyproject.toml" "*.py"; then
    check_tool_version "Python" "$PYTHON" "$(get_mise_tool_version python)" "$PYTHON --version" 1
  else
    log_info "⏭️  Python: Skipped (no python files)"
  fi

  # Go
  if has_lang_files "go.mod" "*.go"; then
    check_tool_version "Go" "go" "1.21.0" "go version" 0
  else
    log_info "⏭️  Go: Skipped (no go files)"
  fi

  # Ruby
  if has_lang_files "Gemfile .ruby-version package.json" "*.rb"; then
    check_tool_version "Ruby" "ruby" "3.0.0" "ruby -v" 0
  else
    log_info "⏭️  Ruby: Skipped (no ruby files)"
  fi

  # Java
  if has_lang_files "pom.xml build.gradle" "*.java"; then
    check_tool_version "Java" "java" "17" "java -version" 0
  else
    log_info "⏭️  Java: Skipped (no java files)"
  fi

  # PHP
  if has_lang_files "composer.json" "*.php"; then
    check_tool_version "PHP" "php" "8.0.0" "php -v" 0
  else
    log_info "⏭️  PHP: Skipped (no php files)"
  fi

  # .NET
  if has_lang_files "global.json" "*.csproj *.sln *.cs"; then
    check_tool_version ".NET" "dotnet" "6.0.0" "dotnet --version" 0
  else
    log_info "⏭️  .NET: Skipped (no dotnet files)"
  fi

  # Rust
  if has_lang_files "Cargo.toml" "*.rs"; then
    check_tool_version "Rust" "cargo" "1.70.0" "cargo --version" 0
  else
    log_info "⏭️  Rust: Skipped (no rust files)"
  fi
  printf "\n"

  # 5. Group: Mobile Support
  if has_lang_files "Package.swift pubspec.yaml build.gradle.kts" "*.swift *.kt *.dart"; then
    log_info "── Mobile Support ──"
    if has_lang_files "Package.swift" "*.swift"; then check_tool_version "Swift" "swift" "5.0" "swift --version" 0; fi
    if has_lang_files "build.gradle.kts" "*.kt *.kts"; then check_tool_version "Kotlin" "kotlin" "1.9.0" "kotlin -version" 0; fi
    if [ -f "pubspec.yaml" ] || has_lang_files "" "*.dart"; then
      if command -v flutter >/dev/null 2>&1; then
        check_tool_version "Flutter" "flutter" "3.0.0" "flutter --version" 0
      else check_tool_version "Dart" "dart" "3.0.0" "dart --version" 0; fi
    fi
    printf "\n"
  fi

  log_info "── Toolchain Manager ──"
  if command -v mise >/dev/null 2>&1; then
    log_success "✅ mise: Active ($(get_version mise))"
  else
    log_warn "❌ mise: Not found. (Mandatory for toolchain management)"
    HEALTHY_ST=1
  fi
  printf "\n"

  # 7. Group: Security & Quality Tools
  log_info "── Security & Quality Tools ──"
  check_tool_version "Gitleaks" "gitleaks" "$(get_mise_tool_version gitleaks)" "gitleaks version" 0 0
  check_tool_version "OSV-scanner" "osv-scanner" "$(get_mise_tool_version osv-scanner)" "osv-scanner --version" 0 1
  check_tool_version "Trivy" "trivy" "$(get_mise_tool_version trivy)" "trivy --version" 0 1
  check_tool_version "Zizmor" "zizmor" "$(get_mise_tool_version zizmor)" "zizmor --version" 0 1

  log_info "── Lint & Quality Tools ──"
  check_tool_version "Shfmt" "shfmt" "$(get_mise_tool_version shfmt-py)" "shfmt --version" 0 0
  check_tool_version "Shellcheck" "shellcheck" "$(get_mise_tool_version shellcheck-py)" "shellcheck --version" 0 0
  check_tool_version "Actionlint" "actionlint" "$(get_mise_tool_version actionlint-py)" "actionlint --version" 0 0
  check_tool_version "EditorConfig" "editorconfig-checker" "$(get_mise_tool_version editorconfig-checker)" "editorconfig-checker --version" 0 0

  if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
    check_tool_version "Hadolint" "hadolint" "$(get_mise_tool_version hadolint)" "hadolint --version" 0 0
  fi
  if has_lang_files "go.mod" "*.go"; then
    check_tool_version "golangci-lint" "golangci-lint" "$(get_mise_tool_version golangci-lint)" "golangci-lint --version" 0 0
    check_tool_version "Govulncheck" "govulncheck" "latest" "govulncheck ./..." 0 1
  fi
  if has_lang_files "Makefile" "*.make"; then
    check_tool_version "Checkmake" "checkmake" "$(get_mise_tool_version checkmake)" "checkmake --version" 0 0
  fi
  if has_lang_files "Cargo.toml" "*.rs"; then
    check_tool_version "Cargo-audit" "cargo-audit" "latest" "cargo-audit --version" 0 1
  fi
  if has_lang_files "requirements.txt pyproject.toml" "*.py"; then
    check_tool_version "Pip-audit" "pip-audit" "$(get_mise_tool_version pip-audit)" "pip-audit --version" 0 1
  fi
  printf "\n"

  # 7. Project File Integrity
  log_info "── Project Integrity ──"
  local _f_chk
  for _f_chk in "Makefile" "README.md" ".agent/rules/01-general.md"; do
    if [ -f "$_f_chk" ]; then
      log_debug "Found $_f_chk"
    else
      log_error "❌ Missing critical file: $_f_chk"
      HEALTHY_ST=1
      CORE_HEALTHY_ST=1
    fi
  done
  [ "${CORE_HEALTHY_ST:-0}" -eq 0 ] && log_success "✅ Basic project structure is intact."

  # Final combined health check
  if [ "${HEALTHY_ST:-0}" -eq 0 ]; then
    log_success "\n✨ Environment is HEALTHY! Ready for development."
    exit 0
  elif [ "${CORE_HEALTHY_ST:-0}" -eq 0 ]; then
    log_warn "\n🛠️  Environment is FUNCTIONAL but has warnings (missing recommended/optional tools)."
    log_warn "💡 Run 'make setup' to address the warnings above."
    exit 0
  else
    log_error "\n❌ Environment is BROKEN. Critical tools or files are missing."
    log_error "Please fix the issues above to proceed."
    exit 1
  fi
}

main "$@"
