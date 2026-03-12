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

set -e

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
# Examples:
#   check_tool_version "Git" "git" "2.30.0" "git --version" 1
check_tool_version() {
  local _LV_NAME="$1"
  local _LV_CMD="$2"
  local _LV_MIN_VER="$3"
  local _LV_VER_CMD="$4"
  local _LV_CRITICAL="${5:-0}"

  log_debug "Checking $_LV_NAME (min: $_LV_MIN_VER)..."

  if ! command -v "$_LV_CMD" >/dev/null 2>&1; then
    log_warn "❌ $_LV_NAME: Not found."
    HEALTHY_ST=1
    [ "${_LV_CRITICAL:-0}" -eq 1 ] && CORE_HEALTHY_ST=1
    return 1
  fi

  local _LV_CURRENT_VER
  _LV_CURRENT_VER=$(get_version "$_LV_CMD")
  [ "$_LV_CURRENT_VER" = "-" ] && _LV_CURRENT_VER="0.0"

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
    check_tool_version "Node.js" "node" "24.1.0" "node -v" 1
    check_tool_version "pnpm" "pnpm" "9.0.0" "pnpm -v" 1
  else
    log_info "⏭️  Node.js/pnpm: Skipped (no package.json)"
  fi

  # Python
  if has_lang_files "requirements.txt requirements-dev.txt pyproject.toml" "*.py"; then
    check_tool_version "Python" "$PYTHON" "3.10.0" "$PYTHON --version" 1
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

  # 6. Group: Security & Quality Tools
  log_info "── Security & Quality Tools ──"
  if command -v gitleaks >/dev/null 2>&1; then log_success "✅ Gitleaks: Installed"; else
    log_warn "⚠️  Gitleaks: Not found. Run 'make setup' to install."
    HEALTHY_ST=1
  fi
  if command -v osv-scanner >/dev/null 2>&1; then log_success "✅ OSV-scanner: Installed"; else log_warn "⚠️  OSV-scanner: Not found. Run 'make setup' to install."; fi
  if command -v trivy >/dev/null 2>&1; then log_success "✅ Trivy: Installed"; else log_warn "⚠️  Trivy: Not found. Run 'make setup' to install."; fi

  if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
    if command -v hadolint >/dev/null 2>&1; then log_success "✅ Hadolint: Installed"; else log_warn "⚠️  Hadolint: Not found."; fi
  fi
  if has_lang_files "go.mod" "*.go"; then
    if command -v golangci-lint >/dev/null 2>&1; then
      check_tool_version "golangci-lint" "golangci-lint" "1.55.0" "golangci-lint --version" 0
    else log_warn "⚠️  golangci-lint: Not found."; fi
  fi
  printf "\n"

  # 7. Project File Integrity
  log_info "── Project Integrity ──"
  local _f_chk
  for _f_chk in "Makefile" "$PACKAGE_JSON" "README.md" ".agent/rules/01-general.md"; do
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
