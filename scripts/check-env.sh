#!/bin/sh
# scripts/check-env.sh - Environment Health Auditor
# Validates the developer workstation against project-required runtimes and tools.
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Language-aware runtime detection (Node, Go, Python, etc.).
#   - High-performance, non-destructive validation scans.
#   - Professional UX with version-compatibility reporting.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Argument parsing
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "🔍 Checking Development Environment Health...\n"

  _HEALTHY=0
  _CORE_HEALTHY=0

  # Internal helper for version checking
  _check_version() {
    _NAME_PROC="$1"
    _CMD_PROC="$2"
    _MIN_VER_PROC="$3"
    _VER_CMD_PROC="$4"
    _CRITICAL_PROC="${5:-0}"

    log_debug "Checking $_NAME_PROC (min: $_MIN_VER_PROC)..."

    if ! command -v "$_CMD_PROC" >/dev/null 2>&1; then
      log_warn "❌ $_NAME_PROC: Not found."
      _HEALTHY=1
      [ "$_CRITICAL_PROC" -eq 1 ] && _CORE_HEALTHY=1
      return 1
    fi

    _CURRENT_VER_PROC=$(get_version "$_CMD_PROC")
    [ "$_CURRENT_VER_PROC" = "-" ] && _CURRENT_VER_PROC="0.0"

    _LOWER_VER_PROC=$(printf "%s\n%s" "$_MIN_VER_PROC" "$_CURRENT_VER_PROC" | sort -n -t. -k1,1 -k2,2 -k3,3 | head -n1)

    if [ "$_LOWER_VER_PROC" = "$_MIN_VER_PROC" ] || [ "$_CURRENT_VER_PROC" = "$_MIN_VER_PROC" ]; then
      log_success "✅ $_NAME_PROC: v$_CURRENT_VER_PROC (matches/exceeds v$_MIN_VER_PROC)"
    else
      log_warn "⚠️  $_NAME_PROC: v$_CURRENT_VER_PROC (below recommended v$_MIN_VER_PROC)"
      _HEALTHY=1
      [ "$_CRITICAL_PROC" -eq 1 ] && _CORE_HEALTHY=1
    fi
  }

  # 3. Group: Core Infrastructure
  log_info "── Core Infrastructure ──"
  _check_version "Git" "git" "2.30.0" "git --version" 1

  if command -v make >/dev/null 2>&1; then
    log_success "✅ Make: Installed"
  else
    log_error "❌ Make: Not found."
    _HEALTHY=1
    _CORE_HEALTHY=1
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
    _check_version "Node.js" "node" "24.1.0" "node -v" 1
    _check_version "pnpm" "pnpm" "9.0.0" "pnpm -v" 1
  else
    log_info "⏭️  Node.js/pnpm: Skipped (no package.json)"
  fi

  # Python
  if has_lang_files "requirements.txt requirements-dev.txt pyproject.toml" "*.py"; then
    _check_version "Python" "$PYTHON" "3.10.0" "$PYTHON --version" 1
  else
    log_info "⏭️  Python: Skipped (no python files)"
  fi

  # Go
  if has_lang_files "go.mod" "*.go"; then
    _check_version "Go" "go" "1.21.0" "go version" 0
  else
    log_info "⏭️  Go: Skipped (no go files)"
  fi

  # Ruby
  if has_lang_files "Gemfile .ruby-version package.json" "*.rb"; then
    _check_version "Ruby" "ruby" "3.0.0" "ruby -v" 0
  else
    log_info "⏭️  Ruby: Skipped (no ruby files)"
  fi

  # Java
  if has_lang_files "pom.xml build.gradle" "*.java"; then
    _check_version "Java" "java" "17" "java -version" 0
  else
    log_info "⏭️  Java: Skipped (no java files)"
  fi

  # PHP
  if has_lang_files "composer.json" "*.php"; then
    _check_version "PHP" "php" "8.0.0" "php -v" 0
  else
    log_info "⏭️  PHP: Skipped (no php files)"
  fi

  # .NET
  if has_lang_files "global.json" "*.csproj *.sln *.cs"; then
    _check_version ".NET" "dotnet" "6.0.0" "dotnet --version" 0
  else
    log_info "⏭️  .NET: Skipped (no dotnet files)"
  fi

  # Rust
  if has_lang_files "Cargo.toml" "*.rs"; then
    _check_version "Rust" "cargo" "1.70.0" "cargo --version" 0
  else
    log_info "⏭️  Rust: Skipped (no rust files)"
  fi
  printf "\n"

  # 5. Group: Mobile Support
  if has_lang_files "Package.swift pubspec.yaml build.gradle.kts" "*.swift *.kt *.dart"; then
    log_info "── Mobile Support ──"
    if has_lang_files "Package.swift" "*.swift"; then _check_version "Swift" "swift" "5.0" "swift --version" 0; fi
    if has_lang_files "build.gradle.kts" "*.kt *.kts"; then _check_version "Kotlin" "kotlin" "1.9.0" "kotlin -version" 0; fi
    if [ -f "pubspec.yaml" ] || has_lang_files "" "*.dart"; then
      if command -v flutter >/dev/null 2>&1; then
        _check_version "Flutter" "flutter" "3.0.0" "flutter --version" 0
      else _check_version "Dart" "dart" "3.0.0" "dart --version" 0; fi
    fi
    printf "\n"
  fi

  # 6. Group: Security & Quality Tools
  log_info "── Security & Quality Tools ──"
  if command -v gitleaks >/dev/null 2>&1; then log_success "✅ Gitleaks: Installed"; else
    log_warn "⚠️  Gitleaks: Not found."
    _HEALTHY=1
  fi
  if command -v osv-scanner >/dev/null 2>&1; then log_success "✅ OSV-scanner: Installed"; else log_warn "⚠️  OSV-scanner: Not found."; fi
  if command -v trivy >/dev/null 2>&1; then log_success "✅ Trivy: Installed"; else log_warn "⚠️  Trivy: Not found."; fi

  if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
    if command -v hadolint >/dev/null 2>&1; then log_success "✅ Hadolint: Installed"; else log_warn "⚠️  Hadolint: Not found."; fi
  fi
  if has_lang_files "go.mod" "*.go"; then
    if command -v golangci-lint >/dev/null 2>&1; then
      _check_version "golangci-lint" "golangci-lint" "1.55.0" "golangci-lint --version" 0
    else log_warn "⚠️  golangci-lint: Not found."; fi
  fi
  printf "\n"

  # 7. Project File Integrity
  log_info "── Project Integrity ──"
  for f in "Makefile" "$PACKAGE_JSON" "README.md" ".agent/rules/01-general.md"; do
    if [ -f "$f" ]; then
      log_debug "Found $f"
    else
      log_error "❌ Missing critical file: $f"
      _HEALTHY=1
      _CORE_HEALTHY=1
    fi
  done
  [ "$_CORE_HEALTHY" -eq 0 ] && log_success "✅ Basic project structure is intact."

  # Final combined health check
  if [ "$_HEALTHY" -eq 0 ]; then
    log_success "\n✨ Environment is HEALTHY! Ready for development."
    exit 0
  elif [ "$_CORE_HEALTHY" -eq 0 ]; then
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
