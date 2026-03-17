#!/usr/bin/env sh
# scripts/lib/langs/kmp.sh - Kotlin Multiplatform Module
#
# Standards:
#   - POSIX-compliant sh logic.
#   - Rule 01 (General), Rule 08 (Dev Env).

# Purpose: Checks for KMP development prerequisites.
# Examples:
#   check_kmp
check_kmp() {
  log_info "🔍 Checking KMP environment..."

  # Check for JDK (Prerequisite)
  if ! command -v java >/dev/null 2>&1; then
    log_warn "⚠️  KMP requires Java. Please install it first."
    return 1
  fi

  # Check for Kotlin project or KMP files
  if [ -f "build.gradle.kts" ] && grep -q "kotlin(\"multiplatform\")" build.gradle.kts; then
    log_success "✅ KMP project detected."
  elif [ -f "build.gradle" ] && grep -q "apply plugin: 'kotlin-multiplatform'" build.gradle; then
    log_success "✅ KMP project detected."
  else
    log_info "⏭️  KMP: Skipped (no KMP files found)"
    return 0
  fi

  return 0
}

# Purpose: Placeholder for KMP setup.
# Examples:
#   install_kmp
install_kmp() {
  log_info "🚀 KMP setup usually happens via: IntelliJ IDEA or Android Studio"
  log_info "Checking if kmp is already in project..."

  if [ -f "build.gradle.kts" ] && grep -q "kotlin(\"multiplatform\")" build.gradle.kts; then
    log_success "✅ KMP is already configured in this project."
  else
    log_info "KMP not found; project initialization recommended."
  fi
}
