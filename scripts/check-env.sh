#!/bin/sh
# scripts/check-env.sh - Environment Health Check Script
# Validates the development environment and required tool versions.
# Features: POSIX compliant, Execution Guard, Language-Aware detection, Professional UX.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# Help message
# shellcheck disable=SC2329
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Validates the development environment and required tool versions.
Groups results by Core Infrastructure, Language Runtimes, and Security & Quality.

Options:
  -q, --quiet      Only show errors.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# Argument parsing
parse_common_args "$@"

check_version() {
  _NAME="$1"
  _CMD="$2"
  _MIN_VER="$3"
  _VER_CMD="$4"
  _CRITICAL="${5:-0}"

  log_debug "Checking $_NAME (min: $_MIN_VER)..."

  if ! command -v "$_CMD" >/dev/null 2>&1; then
    log_warn "❌ $_NAME: Not found."
    HEALTHY=1
    [ "$_CRITICAL" -eq 1 ] && CORE_HEALTHY=1
    return 1
  fi

  # Use unified version detection from common.sh
  _CURRENT_VER=$(get_version "$_CMD")
  [ "$_CURRENT_VER" = "-" ] && _CURRENT_VER="0.0"

  # Simple version comparison using sort -n
  _LOWER_VER=$(printf "%s\n%s" "$_MIN_VER" "$_CURRENT_VER" | sort -n -t. -k1,1 -k2,2 -k3,3 | head -n1)

  if [ "$_LOWER_VER" = "$_MIN_VER" ] || [ "$_CURRENT_VER" = "$_MIN_VER" ]; then
    log_success "✅ $_NAME: v$_CURRENT_VER (matches/exceeds v$_MIN_VER)"
  else
    log_warn "⚠️  $_NAME: v$_CURRENT_VER (below recommended v$_MIN_VER)"
    HEALTHY=1
    [ "$_CRITICAL" -eq 1 ] && CORE_HEALTHY=1
  fi
}

main() {
  log_info "🔍 Checking Development Environment Health...\n"

  HEALTHY=0
  CORE_HEALTHY=0

  # 2. Group: Core Infrastructure
  log_info "── Core Infrastructure ──"
  check_version "Git" "git" "2.30.0" "git --version" 1

  if command -v make >/dev/null 2>&1; then
    log_success "✅ Make: Installed"
  else
    log_error "❌ Make: Not found."
    HEALTHY=1
    CORE_HEALTHY=1
  fi

  if command -v docker >/dev/null 2>&1; then
    log_success "✅ Docker: Installed"
  else
    log_warn "⚠️  Docker: Not found (optional for some tasks)"
  fi
  printf "\n"

  # 3. Group: Language Runtimes (Dynamic Detection)
  log_info "── Language Runtimes ──"

  # Node.js (Checked if package.json exists)
  if [ -f "$PACKAGE_JSON" ]; then
    check_version "Node.js" "node" "24.1.0" "node -v" 1
    check_version "pnpm" "pnpm" "9.0.0" "pnpm -v" 1
  else
    log_info "⏭️  Node.js/pnpm: Skipped (no package.json)"
  fi

  # Python (Checked if requirements or pyproject exists)
  if has_lang_files "requirements.txt requirements-dev.txt pyproject.toml" "*.py"; then
    check_version "Python" "$PYTHON" "3.10.0" "$PYTHON --version" 1
  else
    log_info "⏭️  Python: Skipped (no python files)"
  fi

  # Go (Checked if go.mod exists)
  if has_lang_files "go.mod" "*.go"; then
    check_version "Go" "go" "1.21.0" "go version" 0
  else
    log_info "⏭️  Go: Skipped (no go files)"
  fi

  # Ruby (Checked if Gemfile, .ruby-version or *.rb files exist)
  if has_lang_files "Gemfile .ruby-version package.json" "*.rb"; then
    check_version "Ruby" "ruby" "3.0.0" "ruby -v" 0
  else
    log_info "⏭️  Ruby: Skipped (no ruby files)"
  fi

  # Java (Checked if pom.xml or build.gradle exists)
  if has_lang_files "pom.xml build.gradle" "*.java"; then
    check_version "Java" "java" "17" "java -version" 0
  else
    log_info "⏭️  Java: Skipped (no java files)"
  fi

  # PHP (Checked if composer.json or *.php exists)
  if has_lang_files "composer.json" "*.php"; then
    check_version "PHP" "php" "8.0.0" "php -v" 0
  else
    log_info "⏭️  PHP: Skipped (no php files)"
  fi

  # .NET (Checked if project/solution files exist)
  if has_lang_files "global.json" "*.csproj *.sln *.cs"; then
    check_version ".NET" "dotnet" "6.0.0" "dotnet --version" 0
  else
    log_info "⏭️  .NET: Skipped (no dotnet files)"
  fi

  # Rust (Checked if Cargo.toml exists)
  if has_lang_files "Cargo.toml" "*.rs"; then
    check_version "Rust" "cargo" "1.70.0" "cargo --version" 0
  else
    log_info "⏭️  Rust: Skipped (no rust files)"
  fi
  printf "\n"

  # 4. Group: Mobile Support (Dynamic Detection)
  if has_lang_files "Package.swift pubspec.yaml build.gradle.kts" "*.swift *.kt *.dart"; then
    log_info "── Mobile Support ──"

    # Swift (macOS only for real usage)
    if has_lang_files "Package.swift" "*.swift"; then
      check_version "Swift" "swift" "5.0" "swift --version" 0
    fi

    # Kotlin
    if has_lang_files "build.gradle.kts" "*.kt *.kts"; then
      check_version "Kotlin" "kotlin" "1.9.0" "kotlin -version" 0
    fi

    # Dart/Flutter
    if [ -f "pubspec.yaml" ] || has_lang_files "" "*.dart"; then
      if command -v flutter >/dev/null 2>&1; then
        check_version "Flutter" "flutter" "3.0.0" "flutter --version" 0
      else
        check_version "Dart" "dart" "3.0.0" "dart --version" 0
      fi
    fi
    printf "\n"
  fi

  # 5. Group: Security & Quality Tools
  log_info "── Security & Quality Tools ──"

  # Security Tools (Always recommended)
  if command -v gitleaks >/dev/null 2>&1; then
    log_success "✅ Gitleaks: Installed"
  else
    log_warn "⚠️  Gitleaks: Not found."
    HEALTHY=1
  fi

  if command -v osv-scanner >/dev/null 2>&1; then
    log_success "✅ OSV-scanner: Installed"
  else
    log_warn "⚠️  OSV-scanner: Not found."
  fi

  if command -v trivy >/dev/null 2>&1; then
    log_success "✅ Trivy: Installed"
  else
    log_warn "⚠️  Trivy: Not found."
  fi

  # Linters (Checked if relevant files exist)
  if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
    if command -v hadolint >/dev/null 2>&1; then
      log_success "✅ Hadolint: Installed"
    else
      log_warn "⚠️  Hadolint: Not found."
    fi
  fi

  if has_lang_files "go.mod" "*.go"; then
    if command -v golangci-lint >/dev/null 2>&1; then
      check_version "golangci-lint" "golangci-lint" "1.55.0" "golangci-lint --version" 0
    else
      log_warn "⚠️  golangci-lint: Not found."
    fi
  fi
  printf "\n"

  # 6. Project File Integrity
  log_info "── Project Integrity ──"
  for f in "Makefile" "$PACKAGE_JSON" "README.md" ".agent/rules/01-general.md"; do
    if [ -f "$f" ]; then
      log_debug "Found $f"
    else
      log_error "❌ Missing critical file: $f"
      HEALTHY=1
      CORE_HEALTHY=1
    fi
  done
  [ "$CORE_HEALTHY" -eq 0 ] && log_success "✅ Basic project structure is intact."

  # Final combined health check
  if [ "$HEALTHY" -eq 0 ]; then
    log_success "\n✨ Environment is HEALTHY! Ready for development."
    exit 0
  elif [ "$CORE_HEALTHY" -eq 0 ]; then
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
