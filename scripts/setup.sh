#!/bin/sh
# scripts/setup.sh - Modularized Project Setup Script
# This script is designed for both local development and CI/CD JIT installation.
# usage: sh scripts/setup.sh [OPTIONS] [module1] [module2] ...
# modules: node, python, gitleaks, hadolint, go, iac, hooks, all (default)
# Features: POSIX compliant, Execution Guard, CI Job Summary, Professional UX,
#           Verbosity Control, Dry-run support.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# ── Configuration ────────────────────────────────────────────────────────────
# Global variables (VENV, PYTHON, etc.) are sourced from common.sh
# Modules can be overridden by command line args

# 2. Help Message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] [MODULES]

Modularized Project Setup Script for local development and CI/CD environments.

Options:
  -q, --quiet        Suppress informational output.
  -v, --verbose      Enable verbose/debug output.
  --dry-run          Preview what will be installed without making changes.
  -h, --help         Show this help message.

Modules (default: all):
  node               Setup Node.js & pnpm
  python             Setup Python Virtual Environment & dependencies
  gitleaks           Install Gitleaks (secrets scanning)
  hadolint           Install Hadolint (Docker linting)
  go                 Install golangci-lint
  checkmake          Install checkmake (Makefile linting)
  iac                Install IaC tools (tflint, kube-linter)
  powershell         Setup PSScriptAnalyzer
  java               Install google-java-format
  ruby               Setup Rubocop
  php                Install php-cs-fixer
  dart               Check Dart SDK
  swift              Install Swift linters (macOS)
  dotnet             Check .NET SDK
  security           Install security audit tools (osv-scanner, trivy, etc.)
  hooks              Activate Pre-commit Hooks
  all                Run all of the above

Environment Variables:
  VENV               Virtualenv directory (default: .venv)
  PYTHON             Python executable (default: python3)
  GITHUB_PROXY       Github proxy URL for asset downloads

EOF
}

# ── Functions ────────────────────────────────────────────────────────────────

# Backward compatibility (some modules might still use log internally)
log() { log_info "$1"; }
# log_success, log_warn, log_error are used from common.sh

# ── Functions ────────────────────────────────────────────────────────────────

# OS/Arch Detection
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "${ARCH}" in
x86_64) _ARCH_N="x64" ;;
aarch64 | arm64) _ARCH_N="arm64" ;;
*) _ARCH_N="x64" ;;
esac

_EXE=""
case "${OS}" in
darwin) _OS_TAG="darwin" ;;
linux) _OS_TAG="linux" ;;
msys* | mingw* | cygwin*)
  _OS_TAG="windows"
  _EXE=".exe"
  ;;
*) _OS_TAG="linux" ;;
esac
# Execution timing
_START_TIME=$(date +%s)

# Privacy-aware path sanitizer
sanitize_path() {
  echo "$1" | sed "s|$HOME|~|g"
}

setup_node() {
  _T0=$(date +%s)
  log_info "── Setting up Node.js & pnpm ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Runtime" "Node.js" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if command -v corepack >/dev/null 2>&1; then
    corepack enable
  fi

  if [ -f package.json ]; then
    _STAT="✅ Installed"
    run_quiet "$NPM" install || _STAT="❌ Failed"
    _V=$(get_version node)
    _D=$(($(date +%s) - _T0))
    log_summary "Runtime" "Node.js" "$_STAT" "$_V" "$_D"

    if [ "$_STAT" = "✅ Installed" ]; then
      # Detect Frameworks from package.json
      if grep -q '"vitepress"' package.json; then
        log_summary "Framework" "VitePress" "✅ Detected" "$(get_version "$NPM" "exec vitepress --version")" "0"
      fi
      if grep -q '"vue"' package.json; then
        log_summary "Framework" "Vue" "✅ Detected" "-" "0"
      fi
      if grep -q '"react"' package.json; then
        log_summary "Framework" "React" "✅ Detected" "-" "0"
      fi
      if grep -q '"tailwindcss"' package.json; then
        log_summary "Framework" "Tailwind" "✅ Detected" "-" "0"
      fi
    fi
  else
    log_summary "Runtime" "Node.js" "⏭️ Skipped" "-" "0"
  fi
}

setup_python() {
  _T0=$(date +%s)
  log_info "── Setting up Python Virtual Environment ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Runtime" "Python" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _STAT="✅ Installed"
  if [ ! -d "$VENV" ]; then
    "$PYTHON" -m venv "$VENV" || _STAT="❌ Failed"
  fi

  if [ "$_STAT" = "✅ Installed" ]; then
    run_quiet "$VENV/bin/pip" install --upgrade pip || _STAT="⚠️ Warning"
    if [ -f requirements-dev.txt ]; then
      run_quiet "$VENV/bin/pip" install -r requirements-dev.txt || _STAT="❌ Failed"
    fi
  fi

  if [ -d "$VENV" ]; then
    _V=$(get_version "$VENV/bin/python")
    _D=$(($(date +%s) - _T0))
    log_summary "Runtime" "Python" "$_STAT" "$_V" "$_D"
  else
    log_summary "Runtime" "Python" "❌ Failed" "-" "0"
  fi
}

install_gitleaks() {
  _T0=$(date +%s)
  _BIN="${VENV}/bin/gitleaks${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "Gitleaks" "✅ Exists" "$(get_version "$_BIN")" "0"
    return 0
  fi
  log_info "── Installing gitleaks ──"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "Gitleaks" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _TAR_TAG="${_OS_TAG}"
  _TMP=$(mktemp -d)
  _STAT="✅ Installed"

  if [ "${_OS_TAG}" = "windows" ]; then
    _ARCH_W="x64"
    [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_W="arm64"
    _TAR="gitleaks_${GITLEAKS_VERSION#v}_windows_${_ARCH_W}.zip"
    _URL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR}"

    if download_url "${_URL}" "${_TMP}/gitleaks.zip" "gitleaks"; then
      unzip -q "${_TMP}/gitleaks.zip" -d "${_TMP}" || _STAT="❌ Failed"
      if [ "$_STAT" = "✅ Installed" ]; then
        mv "${_TMP}/gitleaks.exe" "${_BIN}" || _STAT="❌ Failed"
      fi
    else
      _STAT="❌ Failed"
    fi
  else
    _TAR="gitleaks_${GITLEAKS_VERSION#v}_${_TAR_TAG}_${_ARCH_N}.tar.gz"
    _URL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR}"
    if download_url "${_URL}" "${_TMP}/gitleaks.tar.gz" "gitleaks"; then
      tar -xzf "${_TMP}/gitleaks.tar.gz" -C "${_TMP}" gitleaks || _STAT="❌ Failed"
      if [ "$_STAT" = "✅ Installed" ]; then
        mv "${_TMP}/gitleaks" "${_BIN}" || _STAT="❌ Failed"
      fi
    else
      _STAT="❌ Failed"
    fi
  fi
  if "${_BIN}" --version >/dev/null 2>&1; then
    _D=$(($(date +%s) - _T0))
    log_summary "Lint Tool" "Gitleaks" "$_STAT" "$(get_version "$_BIN")" "$_D"
  else
    log_summary "Lint Tool" "Gitleaks" "❌ Failed" "-" "0"
  fi
}

install_hadolint() {
  _T0=$(date +%s)
  _BIN="${VENV}/bin/hadolint${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "Hadolint" "✅ Exists" "$(get_version "$_BIN")" "0"
    return 0
  fi

  if ! has_lang_files "Dockerfile docker-compose.yml" "*.dockerfile *.Dockerfile"; then
    log_summary "Lint Tool" "Hadolint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing hadolint ──"

  _H_ARCH="x86_64"
  [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _H_ARCH="arm64"

  _H_OS="Linux"
  [ "${OS}" = "darwin" ] && _H_OS="Darwin"
  [ "${_OS_TAG}" = "windows" ] && _H_OS="Windows"

  _SUFFIX="${_H_OS}-${_H_ARCH}"
  [ "${_OS_TAG}" = "windows" ] && _SUFFIX="${_SUFFIX}.exe"

  _URL="${GITHUB_PROXY}https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${_SUFFIX}"
  _STAT="✅ Installed"
  if download_url "${_URL}" "${_BIN}" "hadolint"; then
    chmod +x "${_BIN}" 2>/dev/null || true
  else
    _STAT="❌ Failed"
  fi
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "Hadolint" "$_STAT" "$(get_version "$_BIN")" "$_D"
}

install_go_lint() {
  _T0=$(date +%s)
  _BIN="${VENV}/bin/golangci-lint"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "Go Lint" "✅ Exists" "$(get_version "$_BIN")" "0"
    return 0
  fi

  if ! has_lang_files "go.mod go.sum" "*.go"; then
    log_summary "Lint Tool" "Go Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing golangci-lint ──"

  _URL="${GITHUB_PROXY}https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"
  _TMP=$(mktemp -d)
  _STAT="✅ Installed"
  if download_url "${_URL}" "${_TMP}/install_go.sh" "golangci-lint-installer"; then
    export BINDIR="${VENV}/bin"
    run_quiet sh "${_TMP}/install_go.sh" "${GOLANGCI_VERSION}"
  else
    _STAT="❌ Failed"
  fi
  rm -rf "${_TMP}"
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "Go Lint" "$_STAT" "$(get_version "$_BIN")" "$_D"
}

install_checkmake() {
  _T0=$(date +%s)
  if ! has_lang_files "Makefile" "*.make"; then
    log_summary "Lint Tool" "Checkmake" "基础 Skipped" "-" "0"
    return 0
  fi
  _BIN="${VENV}/bin/checkmake${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "Checkmake" "✅ Exists" "$(get_version "$_BIN")" "0"
    return 0
  fi

  log_info "── Installing checkmake ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "Checkmake" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _OS_S="${_OS_TAG}"
  _ARCH_S="amd64"
  [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_S="arm64"
  _FILE="checkmake-${CHECKMAKE_VERSION}.${_OS_S}.${_ARCH_S}${_EXE}"
  _URL="${GITHUB_PROXY}https://github.com/checkmake/checkmake/releases/download/${CHECKMAKE_VERSION}/${_FILE}"

  _STAT="✅ Installed"
  if download_url "${_URL}" "${_BIN}" "checkmake"; then
    chmod +x "${_BIN}" 2>/dev/null || true
  else
    _STAT="❌ Failed"
  fi
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "Checkmake" "$_STAT" "$(get_version "$_BIN")" "$_D"
}

install_iac_lint() {
  _T0=$(date +%s)
  if ! has_lang_files "" "*.tf *.tfvars *.yaml *.yml *.json"; then
    log_summary "Lint Tool" "IaC" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing IaC tools ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "TFLint" "⚖️ Previewed" "-" "0"
    log_summary "Lint Tool" "Kube-Linter" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # TFLint
  if [ ! -x "${VENV}/bin/tflint${_EXE}" ]; then
    _TAR_OS="${_OS_TAG}"
    _TAR_ARCH="amd64"
    [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _TAR_ARCH="arm64"
    _TAR="tflint_${_TAR_OS}_${_TAR_ARCH}.zip"
    _URL="${GITHUB_PROXY}https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/${_TAR}"
    _TMP=$(mktemp -d)
    if download_url "${_URL}" "${_TMP}/tflint.zip" "tflint"; then
      unzip -q "${_TMP}/tflint.zip" -d "${_TMP}" || _T_STAT="failed"
      if [ "$_T_STAT" != "failed" ]; then
        mv "${_TMP}/tflint${_EXE}" "${VENV}/bin/tflint${_EXE}" || _T_STAT="failed"
        chmod +x "${VENV}/bin/tflint${_EXE}" 2>/dev/null || true
        log_summary "Lint Tool" "TFLint" "✅ Installed" "$(get_version "${VENV}/bin/tflint${_EXE}")" "$(($(date +%s) - _T0))"
      else
        log_summary "Lint Tool" "TFLint" "❌ Failed" "-" "0"
      fi
    else
      log_summary "Lint Tool" "TFLint" "❌ Failed" "-" "0"
    fi
    rm -rf "${_TMP}"
  else
    log_summary "Lint Tool" "TFLint" "✅ Exists" "$(get_version "${VENV}/bin/tflint${_EXE}")" "0"
  fi

  # Kube-Linter
  if [ ! -x "${VENV}/bin/kube-linter${_EXE}" ]; then
    _K_OS="linux"
    [ "${OS}" = "darwin" ] && _K_OS="darwin"
    _K_SUFFIX=""
    { [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ]; } && _K_SUFFIX="_arm64"
    if [ "${_OS_TAG}" = "windows" ]; then
      _FILE="kube-linter${_K_SUFFIX}.exe"
    else
      _FILE="kube-linter-${_K_OS}${_K_SUFFIX}"
    fi
    _URL="${GITHUB_PROXY}https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/${_FILE}"
    if download_url "${_URL}" "${VENV}/bin/kube-linter${_EXE}" "kube-linter"; then
      chmod +x "${VENV}/bin/kube-linter${_EXE}" 2>/dev/null || true
      log_summary "Lint Tool" "Kube-Linter" "✅ Installed" "$(get_version "${VENV}/bin/kube-linter${_EXE}" "version")" "$(($(date +%s) - _T0))"
    else
      log_summary "Lint Tool" "Kube-Linter" "❌ Failed" "-" "0"
    fi
  else
    log_summary "Lint Tool" "Kube-Linter" "✅ Exists" "$(get_version "${VENV}/bin/kube-linter${_EXE}" "version")" "0"
  fi
}

setup_hooks() {
  _T0=$(date +%s)
  log_info "── Setting up Pre-commit Hooks ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Other" "Hooks" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if [ -x "$VENV/bin/pre-commit" ]; then
    _STAT="✅ Activated"
    run_quiet "$VENV/bin/pre-commit" install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg || _STAT="❌ Failed"
    _V=$(get_version "$VENV/bin/pre-commit")
    _D=$(($(date +%s) - _T0))
    log_summary "Other" "Hooks" "$_STAT" "$_V" "$_D"
  else
    log_summary "Other" "Hooks" "❌ Failed (missing pre-commit)" "-" "0"
  fi
}

setup_powershell() {
  _T0=$(date +%s)
  if ! has_lang_files "" "*.ps1 *.psm1 *.psd1"; then
    log_summary "Lint Tool" "PowerShell" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Setting up PowerShell Linter ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "PowerShell" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if command -v pwsh >/dev/null 2>&1; then
    _STAT="✅ Installed"
    run_quiet pwsh -NoProfile -Command "if (!(Get-Module -ListAvailable PSScriptAnalyzer)) { Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser }" || _STAT="❌ Failed"
    # shellcheck disable=SC2016
    _V=$(pwsh -NoProfile -Command '(Get-Module PSScriptAnalyzer -ListAvailable).Version | Select-Object -First 1 | ForEach-Object { $_.ToString() }' 2>/dev/null || echo "installed")
    _D=$(($(date +%s) - _T0))
    log_summary "Lint Tool" "PowerShell" "$_STAT" "$_V" "$_D"
  else
    log_summary "Lint Tool" "PowerShell" "⏭️ Skipped (pwsh missing)" "-" "0"
  fi
}

install_java_lint() {
  _T0=$(date +%s)
  _JAR="${VENV}/bin/google-java-format.jar"
  _BIN="${VENV}/bin/google-java-format"
  if [ -f "${_JAR}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "Java Lint" "✅ Exists" "$JAVA_FORMAT_VERSION" "0"
    return 0
  fi

  if ! has_lang_files "pom.xml build.gradle" "*.java"; then
    log_summary "Lint Tool" "Java Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing google-java-format ──"

  _URL="${GITHUB_PROXY}https://github.com/google/google-java-format/releases/download/v${JAVA_FORMAT_VERSION}/google-java-format-${JAVA_FORMAT_VERSION}-all-deps.jar"
  _STAT="✅ Installed"
  if download_url "${_URL}" "${_JAR}" "google-java-format"; then
    printf "#!/bin/sh\njava -jar \"%s\" \"\$@\"\n" "${_JAR}" >"${_BIN}" || _STAT="❌ Failed"
    chmod +x "${_BIN}" 2>/dev/null || true
  else
    _STAT="❌ Failed"
  fi
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "Java Lint" "$_STAT" "$JAVA_FORMAT_VERSION" "$_D"
}

install_ruby_lint() {
  _T0=$(date +%s)
  if ! has_lang_files "Gemfile Gemfile.lock" "*.rb"; then
    log_summary "Lint Tool" "Rubocop" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Setting up Rubocop ──"

  # Check in PATH and common user-gem locations to avoid redundant slow gem install
  _RUBO_BIN="rubocop"
  if ! command -v rubocop >/dev/null 2>&1; then
    _GEM_BIN=$(gem environment 2>/dev/null | grep "EXECUTABLE DIRECTORY" | awk '{print $NF}')
    if [ -x "$_GEM_BIN/rubocop" ]; then
      _RUBO_BIN="$_GEM_BIN/rubocop"
    fi
  fi

  if command -v "$_RUBO_BIN" >/dev/null 2>&1 && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "Rubocop" "✅ Exists" "$(get_version "$_RUBO_BIN")" "0"
    return 0
  fi

  if command -v gem >/dev/null 2>&1; then
    _STAT="✅ Installed"
    run_quiet gem install rubocop --user-install --no-document --quiet || _STAT="❌ Failed"
    _V=$(get_version rubocop)
    _D=$(($(date +%s) - _T0))
    log_summary "Lint Tool" "Rubocop" "$_STAT" "$_V" "$_D"
  else
    log_summary "Lint Tool" "Rubocop" "⏭️ Skipped (gem missing)" "-" "0"
  fi
}

install_php_lint() {
  _T0=$(date +%s)
  _BIN="${VENV}/bin/php-cs-fixer"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "PHP Lint" "✅ Exists" "$PHP_CS_FIXER_VERSION" "0"
    return 0
  fi

  if ! has_lang_files "composer.json composer.lock" "*.php"; then
    log_summary "Lint Tool" "PHP Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing php-cs-fixer ──"

  _URL="${GITHUB_PROXY}https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/releases/download/${PHP_CS_FIXER_VERSION}/php-cs-fixer.phar"
  _STAT="✅ Installed"
  if download_url "${_URL}" "${_BIN}" "php-cs-fixer"; then
    chmod +x "${_BIN}" 2>/dev/null || true
  else
    _STAT="❌ Failed"
  fi
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "PHP Lint" "$_STAT" "$PHP_CS_FIXER_VERSION" "$_D"
}

setup_dart() {
  log_info "── Checking Dart SDK ──"
  if command -v dart >/dev/null 2>&1; then
    log_summary "Runtime" "Dart" "✅ Available" "$(get_version dart)" "0"
  else
    log_summary "Runtime" "Dart" "⏭️ Missing" "-" "0"
  fi
}

setup_swift() {
  _T0=$(date +%s)
  if ! has_lang_files "Package.swift" "*.swift"; then
    log_summary "Lint Tool" "Swift" "⏭️ Skipped" "-" "0"
    return 0
  fi
  if [ "${OS}" = "darwin" ]; then
    log_info "── Setting up Swift Linters (macOS) ──"

    _PKG_MGR=$(get_macos_pkg_mgr)
    if [ "$_PKG_MGR" = "brew" ]; then
      _STAT="✅ Installed"
      brew list swiftformat >/dev/null 2>&1 || brew install swiftformat >/dev/null 2>&1 || _STAT="⚠️ Partial"
      brew list swiftlint >/dev/null 2>&1 || brew install swiftlint >/dev/null 2>&1 || _STAT="❌ Failed"
      _D=$(($(date +%s) - _T0))
      log_summary "Lint Tool" "Swift" "$_STAT" "$(get_version swiftlint lint --version)" "$_D"
    elif [ "$_PKG_MGR" = "port" ]; then
      _STAT="✅ Installed"
      log_info "Installing Swift formatters via MacPorts (requires sudo)..."
      port installed swiftformat 2>/dev/null | grep -q active || sudo port install swiftformat || _STAT="⚠️ Partial"
      port installed swiftlint 2>/dev/null | grep -q active || sudo port install swiftlint || _STAT="❌ Failed"
      _D=$(($(date +%s) - _T0))
      log_summary "Lint Tool" "Swift" "$_STAT" "$(get_version swiftlint lint --version)" "$_D"
    else
      log_summary "Lint Tool" "Swift" "⏭️ Skipped (brew/port missing)" "-" "0"
    fi
  else
    log_summary "Lint Tool" "Swift" "⏭️ Skipped" "-" "0"
  fi
}

setup_dotnet() {
  if ! has_lang_files "global.json" "*.csproj *.sln *.cs"; then
    log_summary "Runtime" ".NET" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Checking .NET SDK ──"
  if command -v dotnet >/dev/null 2>&1; then
    log_summary "Runtime" ".NET" "✅ Available" "$(get_version dotnet)" "0"
  else
    log_summary "Runtime" ".NET" "⏭️ Missing" "-" "0"
  fi
}

install_osv_scanner() {
  _T0=$(date +%s)
  _BIN="${VENV}/bin/osv-scanner${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Security Tool" "OSV-Scanner" "✅ Exists" "$(get_version "$_BIN")" "0"
    return 0
  fi

  log_info "── Installing osv-scanner ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Security Tool" "OSV-Scanner" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _O_OS="${_OS_TAG}"
  _O_ARCH="amd64"
  [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _O_ARCH="arm64"
  # osv-scanner asset naming: osv-scanner_{os}_{arch}[.exe] (no version in filename)
  _FILE="osv-scanner_${_O_OS}_${_O_ARCH}${_EXE}"
  _URL="${GITHUB_PROXY}https://github.com/google/osv-scanner/releases/download/${OSV_SCANNER_VERSION}/${_FILE}"

  _STAT="✅ Installed"
  if download_url "${_URL}" "${_BIN}" "osv-scanner"; then
    chmod +x "${_BIN}" 2>/dev/null || true
  else
    _STAT="❌ Failed"
  fi
  _D=$(($(date +%s) - _T0))
  log_summary "Security Tool" "OSV-Scanner" "$_STAT" "$(get_version "$_BIN")" "$_D"
}

install_trivy() {
  _T0=$(date +%s)
  _BIN="${VENV}/bin/trivy${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Security Tool" "Trivy" "✅ Exists" "$(get_version "$_BIN")" "0"
    return 0
  fi

  log_info "── Installing trivy ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Security Tool" "Trivy" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _T_OS="Linux"
  [ "${OS}" = "darwin" ] && _T_OS="macOS"
  # trivy arch naming: ARM64 for arm64, 64bit for amd64
  _T_ARCH="64bit"
  { [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ]; } && _T_ARCH="ARM64"

  if [ "${_OS_TAG}" = "windows" ]; then
    _TAR="trivy_${TRIVY_VERSION#v}_windows-64bit.zip"
  else
    _TAR="trivy_${TRIVY_VERSION#v}_${_T_OS}-${_T_ARCH}.tar.gz"
  fi

  _URL="${GITHUB_PROXY}https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/${_TAR}"
  _TMP=$(mktemp -d)
  _STAT="✅ Installed"

  if download_url "${_URL}" "${_TMP}/trivy_pkg" "trivy"; then
    if [ "${_OS_TAG}" = "windows" ]; then
      unzip -q "${_TMP}/trivy_pkg" -d "${_TMP}" || _STAT="❌ Failed"
      mv "${_TMP}/trivy.exe" "${_BIN}" 2>/dev/null || _STAT="❌ Failed"
    else
      tar -xzf "${_TMP}/trivy_pkg" -C "${_TMP}" trivy || _STAT="❌ Failed"
      mv "${_TMP}/trivy" "${_BIN}" 2>/dev/null || _STAT="❌ Failed"
    fi
    chmod +x "${_BIN}" 2>/dev/null || true
  else
    _STAT="❌ Failed"
  fi
  rm -rf "${_TMP}"
  _D=$(($(date +%s) - _T0))
  log_summary "Security Tool" "Trivy" "$_STAT" "$(get_version "$_BIN")" "$_D"
}

setup_security() {
  log_info "── Setting up Security Audit Tools ──"
  install_osv_scanner
  install_trivy

  # Install govulncheck if go exists
  if command -v go >/dev/null 2>&1; then
    _T0=$(date +%s)
    log_info "Installing govulncheck..."
    if run_quiet go install golang.org/x/vuln/cmd/govulncheck@latest; then
      log_summary "Security Tool" "Govulncheck" "✅ Installed" "$(get_version govulncheck)" "$(($(date +%s) - _T0))"
    else
      log_summary "Security Tool" "Govulncheck" "❌ Failed" "-" "0"
    fi
  fi

  # Install cargo-audit if cargo exists
  if command -v cargo >/dev/null 2>&1; then
    _T0=$(date +%s)
    log_info "Installing cargo-audit..."
    if run_quiet cargo install cargo-audit; then
      log_summary "Security Tool" "Cargo-Audit" "✅ Installed" "$(get_version cargo-audit)" "$(($(date +%s) - _T0))"
    else
      log_summary "Security Tool" "Cargo-Audit" "❌ Failed" "-" "0"
    fi
  fi
}

# ── Main Execution ───────────────────────────────────────────────────────────

# Argument parsing for flags
parse_common_args "$@"
# Re-extract raw args to avoid flags
RAW_ARGS=""
for arg in "$@"; do
  case "$arg" in
  -q | --quiet | -v | --verbose | --dry-run | -h | --help) ;;
  *) RAW_ARGS="${RAW_ARGS} ${arg}" ;;
  esac
done

# ── Execution Timing & Summary Management ──
_START_TIME=$(date +%s)

if [ -z "$SETUP_SUMMARY_FILE" ]; then
  SETUP_SUMMARY_FILE=$(mktemp)
  export SETUP_SUMMARY_FILE
  _CREATED_SUMMARY=true

  # Initialize Summary (Only once per CI Job or first call)
  if [ "$_SETUP_SUMMARY_INITIALIZED" != "true" ]; then
    {
      printf "### Setup Execution Summary\n\n"
      cat <<EOF
> **Status Legend:**
> ⚖️ **Previewed**: Running in \`--dry-run\` mode.
> ✅ **Active/Detected/Available**: System/Shell active or Runtime detected.
> ✅ **Installed**: Tool was missing and successfully installed.
> ✅ **Exists**: Tool already exists in \`$VENV/bin\`.
> ✅ **Activated**: Git Hooks successfully attached to \`.git/\`.
> ⏭️ **Skipped/Missing**: Module skipped or required runtime not found.
> ⚠️ **Warning**: Tool exists but version verification failed.
> ❌ **Failed**: An error occurred during installation or setup.

EOF
      # Add Global Environment Detections immediately after the legend
      log_summary "Environment" "System" "✅ Active" "${OS}/${ARCH}" "0"
      log_summary "Environment" "Shell" "✅ Active" "$(basename "$SHELL")" "0"

      # Detect Go/Rust even if not explicitly setup
      if command -v go >/dev/null 2>&1; then
        log_summary "Runtime" "Go" "✅ Detected" "$(get_version go)" "0"
      fi
      if command -v cargo >/dev/null 2>&1; then
        log_summary "Runtime" "Rust" "✅ Detected" "$(get_version cargo)" "0"
      fi
    } >"$SETUP_SUMMARY_FILE"

    # Set master sentinel for subsequent steps in CI
    if [ -n "$GITHUB_ENV" ]; then
      echo "_SETUP_SUMMARY_INITIALIZED=true" >>"$GITHUB_ENV"
    fi
    export _SETUP_SUMMARY_INITIALIZED=true
  else
    touch "$SETUP_SUMMARY_FILE"
  fi

  # Always provide a table header for the current process invocation
  {
    printf "| Category | Module | Status | Version | Time |\n"
    printf "| :--- | :--- | :--- | :--- | :--- |\n"
  } >>"$SETUP_SUMMARY_FILE"
fi

# ── Module Selection ──
if [ -z "$(echo "${RAW_ARGS}" | tr -d ' ')" ] || [ "${RAW_ARGS# *}" = "all" ]; then
  modules="node python gitleaks hadolint go checkmake iac powershell java ruby php dart swift dotnet security hooks"
else
  modules="${RAW_ARGS}"
fi

for module in $modules; do
  case $module in
  node) setup_node ;;
  python) setup_python ;;
  gitleaks) install_gitleaks ;;
  checkmake) install_checkmake ;;
  hadolint) install_hadolint ;;
  go) install_go_lint ;;
  iac) install_iac_lint ;;
  powershell) setup_powershell ;;
  java) install_java_lint ;;
  ruby) install_ruby_lint ;;
  php) install_php_lint ;;
  dart) setup_dart ;;
  swift) setup_swift ;;
  dotnet) setup_dotnet ;;
  security) setup_security ;;
  hooks) setup_hooks ;;
  *) error "Unknown module: $module" ;;
  esac
done

# ── Final Output Management ──
if [ "$_CREATED_SUMMARY" = "true" ]; then
  _TOTAL_DUR=$(($(date +%s) - _START_TIME))
  printf "\n**Total Duration: %ss**\n" "$_TOTAL_DUR" >>"$SETUP_SUMMARY_FILE"

  printf "\n"
  cat "$SETUP_SUMMARY_FILE"
  if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    cat "$SETUP_SUMMARY_FILE" >>"$GITHUB_STEP_SUMMARY"
  fi
  rm -f "$SETUP_SUMMARY_FILE"
fi

if [ "$_IS_TOP_LEVEL" = "true" ]; then
  log_info "\n✨ Setup step $modules complete!"

  # Next Actions
  if [ "$DRY_RUN" -eq 0 ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake install%b to install project dependencies.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake verify%b to ensure environment health.\n" "${GREEN}" "${NC}"
  fi
fi
