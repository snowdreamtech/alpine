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
info() { log_success "$1"; }
warn() { log_warn "$1"; }
error() {
  log_error "$1"
  exit 1
}

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
TMP_SUMMARY=$(mktemp)
log_summary() {
  _MOD="$1"
  _STAT="$2"
  printf "| %s | %s |\n" "$_MOD" "$_STAT" >>"$TMP_SUMMARY"
}

setup_node() {
  log_info "── Setting up Node.js & pnpm ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would enable corepack and pnpm install."
    log_summary "Node.js" "⚖️ Previewed"
    return 0
  fi

  if command -v corepack >/dev/null 2>&1; then
    corepack enable
  else
    warn "Warning: corepack not found. Ensure Node.js 16.9+ is installed."
  fi
  if [ -f package.json ]; then
    pnpm install
    info "Node.js dependencies installed."
    log_summary "Node.js" "✅ Installed"
  else
    log_summary "Node.js" "⏭️ Skipped (no package.json)"
  fi
}

setup_python() {
  log_info "── Setting up Python Virtual Environment ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would create $VENV and install requirements."
    log_summary "Python" "⚖️ Previewed"
    return 0
  fi

  if [ ! -d "$VENV" ]; then
    "$PYTHON" -m venv "$VENV"
  fi
  "$VENV/bin/pip" install --upgrade pip
  if [ -f requirements-dev.txt ]; then
    "$VENV/bin/pip" install -r requirements-dev.txt
    info "Python dev dependencies installed in ${VENV}."
    log_summary "Python" "✅ Installed"
  else
    log_summary "Python" "⏭️ Skipped (no requirements-dev.txt)"
  fi
}

install_gitleaks() {
  _BIN="${VENV}/bin/gitleaks${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Gitleaks" "✅ Already exists"
    return 0
  fi
  log_info "── Installing gitleaks ${GITLEAKS_VERSION} ──"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install gitleaks to $_BIN"
    log_summary "Gitleaks" "⚖️ Previewed"
    return 0
  fi

  _TAR_TAG="${_OS_TAG}"
  [ "${_OS_TAG}" = "windows" ] && _TAR_TAG="windows"
  _TMP=$(mktemp -d)

  if [ "${_OS_TAG}" = "windows" ]; then
    _ARCH_W="x64"
    [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_W="arm64"
    _TAR="gitleaks_${GITLEAKS_VERSION#v}_${_TAR_TAG}_${_ARCH_W}.zip"
    _URL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR}"

    if download_url "${_URL}" "${_TMP}/gitleaks.zip" "gitleaks"; then
      unzip -q "${_TMP}/gitleaks.zip" -d "${_TMP}"
      mv "${_TMP}/gitleaks.exe" "${_BIN}"
      chmod +x "${_BIN}"
      info "gitleaks installed."
      log_summary "Gitleaks" "✅ Installed"
    else
      log_summary "Gitleaks" "❌ Failed"
      error "Failed to download gitleaks."
    fi
  else
    _TAR="gitleaks_${GITLEAKS_VERSION#v}_${_TAR_TAG}_${_ARCH_N}.tar.gz"
    _URL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR}"

    if download_url "${_URL}" "${_TMP}/gitleaks.tar.gz" "gitleaks"; then
      tar -xzf "${_TMP}/gitleaks.tar.gz" -C "${_TMP}" gitleaks
      mv "${_TMP}/gitleaks" "${_BIN}"
      chmod +x "${_BIN}"
      info "gitleaks installed."
      log_summary "Gitleaks" "✅ Installed"
    else
      log_summary "Gitleaks" "❌ Failed"
      error "Failed to download gitleaks."
    fi
  fi
  rm -rf "${_TMP}"
}

install_hadolint() {
  _BIN="${VENV}/bin/hadolint${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Hadolint" "✅ Already exists"
    return 0
  fi

  log_info "── Installing hadolint ${HADOLINT_VERSION} ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install hadolint to $_BIN"
    log_summary "Hadolint" "⚖️ Previewed"
    return 0
  fi

  _SUFFIX="Linux-x86_64"
  if [ "${OS}" = "darwin" ]; then
    _SUFFIX="Darwin-x86_64"
  elif [ "${_OS_TAG}" = "windows" ]; then
    _SUFFIX="Windows-x86_64.exe"
  fi

  _URL="${GITHUB_PROXY}https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${_SUFFIX}"
  if download_url "${_URL}" "${_BIN}" "hadolint"; then
    chmod +x "${_BIN}"
    info "hadolint installed."
    log_summary "Hadolint" "✅ Installed"
  else
    log_summary "Hadolint" "❌ Failed"
    error "Failed to download hadolint."
  fi
}

install_go_lint() {
  _BIN="${VENV}/bin/golangci-lint"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Go Lint" "✅ Already exists"
    return 0
  fi

  log_info "── Installing golangci-lint ${GOLANGCI_VERSION} ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install golangci-lint to $_BIN"
    log_summary "Go Lint" "⚖️ Previewed"
    return 0
  fi

  _URL="${GITHUB_PROXY}https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"
  _TMP=$(mktemp -d)
  if download_url "${_URL}" "${_TMP}/install_go.sh" "golangci-lint-installer"; then
    export BINDIR="${VENV}/bin"
    sh "${_TMP}/install_go.sh" "${GOLANGCI_VERSION}"
    rm -rf "${_TMP}"
    info "golangci-lint installed."
    log_summary "Go Lint" "✅ Installed"
  else
    log_summary "Go Lint" "❌ Failed"
    error "Failed to download golangci-lint installer."
  fi
}

install_checkmake() {
  _BIN="${VENV}/bin/checkmake${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Checkmake" "✅ Already exists"
    return 0
  fi

  log_info "── Installing checkmake ${CHECKMAKE_VERSION} ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install checkmake to $_BIN"
    log_summary "Checkmake" "⚖️ Previewed"
    return 0
  fi

  _OS_S="${_OS_TAG}"
  _ARCH_S="amd64"
  [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_S="arm64"

  _FILE="checkmake-${CHECKMAKE_VERSION}.${_OS_S}.${_ARCH_S}${_EXE}"
  _URL="${GITHUB_PROXY}https://github.com/checkmake/checkmake/releases/download/${CHECKMAKE_VERSION}/${_FILE}"

  if download_url "${_URL}" "${_BIN}" "checkmake"; then
    chmod +x "${_BIN}"
    info "checkmake installed."
    log_summary "Checkmake" "✅ Installed"
  else
    log_summary "Checkmake" "❌ Failed"
    error "Failed to download checkmake from ${_URL}"
  fi
}

install_iac_lint() {
  log_info "── Installing IaC tools (tflint, kube-linter) ──"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install tflint and kube-linter to ${VENV}/bin"
    log_summary "TFLint" "⚖️ Previewed"
    log_summary "Kube-Linter" "⚖️ Previewed"
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
      unzip -q "${_TMP}/tflint.zip" -d "${_TMP}"
      mv "${_TMP}/tflint${_EXE}" "${VENV}/bin/tflint${_EXE}"
      chmod +x "${VENV}/bin/tflint${_EXE}"
      rm -rf "${_TMP}"
      log_summary "TFLint" "✅ Installed"
    else
      log_summary "TFLint" "❌ Failed"
      error "Failed to download tflint."
    fi
  else
    log_summary "TFLint" "✅ Already exists"
  fi
  # Kube-Linter
  if [ ! -x "${VENV}/bin/kube-linter${_EXE}" ]; then
    _SUFFIX="linux"
    [ "${OS}" = "darwin" ] && _SUFFIX="darwin"
    [ "${_OS_TAG}" = "windows" ] && _SUFFIX="windows.exe"

    _URL="${GITHUB_PROXY}https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/kube-linter-$_SUFFIX"
    if download_url "${_URL}" "${VENV}/bin/kube-linter${_EXE}" "kube-linter"; then
      chmod +x "${VENV}/bin/kube-linter${_EXE}"
      log_summary "Kube-Linter" "✅ Installed"
    else
      log_summary "Kube-Linter" "❌ Failed"
      error "Failed to download kube-linter."
    fi
  else
    log_summary "Kube-Linter" "✅ Already exists"
  fi
  info "IaC tools installed."
}

setup_hooks() {
  log_info "── Activating Pre-commit Hooks ──"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would activate pre-commit hooks."
    log_summary "Hooks" "⚖️ Previewed"
    return 0
  fi

  if [ -x "$VENV/bin/pre-commit" ]; then
    "$VENV/bin/pre-commit" install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg
    info "Pre-commit hooks activated."
    log_summary "Hooks" "✅ Activated"
  else
    warn "Warning: pre-commit not found. Run python module first."
    log_summary "Hooks" "❌ Failed (missing pre-commit)"
  fi
}

setup_powershell() {
  log_info "── Setting up PowerShell Linter ──"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install PSScriptAnalyzer."
    log_summary "PowerShell" "⚖️ Previewed"
    return 0
  fi

  if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -Command "if (!(Get-Module -ListAvailable PSScriptAnalyzer)) { Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser }"
    info "PSScriptAnalyzer installed."
    log_summary "PowerShell" "✅ Installed"
  else
    warn "Warning: pwsh not found. Skipping PowerShell linter setup."
    log_summary "PowerShell" "⏭️ Skipped (no pwsh)"
  fi
}

install_java_lint() {
  _JAR="${VENV}/bin/google-java-format.jar"
  _BIN="${VENV}/bin/google-java-format"
  if [ -f "${_JAR}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Java Lint" "✅ Already exists"
    return 0
  fi

  log_info "── Installing google-java-format ${JAVA_FORMAT_VERSION} ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install google-java-format to $_BIN"
    log_summary "Java Lint" "⚖️ Previewed"
    return 0
  fi

  _URL="${GITHUB_PROXY}https://github.com/google/google-java-format/releases/download/v${JAVA_FORMAT_VERSION}/google-java-format-${JAVA_FORMAT_VERSION}-all-deps.jar"
  if download_url "${_URL}" "${_JAR}" "google-java-format"; then
    printf "#!/bin/sh\njava -jar \"%s\" \"\$@\"\n" "${_JAR}" >"${_BIN}"
    chmod +x "${_BIN}"
    info "google-java-format installed."
    log_summary "Java Lint" "✅ Installed"
  else
    log_summary "Java Lint" "❌ Failed"
    error "Failed to download google-java-format."
  fi
}

install_ruby_lint() {
  log_info "── Setting up Rubocop ──"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install Rubocop via gem."
    log_summary "Rubocop" "⚖️ Previewed"
    return 0
  fi

  if command -v gem >/dev/null 2>&1; then
    _RUBY_VER=$(ruby -e 'print RUBY_VERSION')
    _RUBY_MAJOR=$(echo "$_RUBY_VER" | cut -d. -f1)
    _RUBY_MINOR=$(echo "$_RUBY_VER" | cut -d. -f2)

    if [ "$_RUBY_MAJOR" -lt 2 ] || { [ "$_RUBY_MAJOR" -eq 2 ] && [ "$_RUBY_MINOR" -lt 7 ]; }; then
      warn "Warning: Ruby version $_RUBY_VER is too old (< 2.7.0). Attempting to install Rubocop v0.93.1."
      gem install rubocop -v 0.93.1 --user-install --no-document --quiet || warn "Failed to install Rubocop."
    else
      gem install rubocop --user-install --no-document --quiet || warn "Failed to install Rubocop."
    fi
    info "Rubocop setup finished."
    log_summary "Rubocop" "✅ Installed"
  else
    warn "Warning: gem not found. Skipping Rubocop setup."
    log_summary "Rubocop" "⏭️ Skipped (no gem)"
  fi
}

install_php_lint() {
  _BIN="${VENV}/bin/php-cs-fixer"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "PHP Lint" "✅ Already exists"
    return 0
  fi

  log_info "── Installing php-cs-fixer ${PHP_CS_FIXER_VERSION} ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY-RUN: Would install php-cs-fixer to $_BIN"
    log_summary "PHP Lint" "⚖️ Previewed"
    return 0
  fi

  _URL="${GITHUB_PROXY}https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/releases/download/${PHP_CS_FIXER_VERSION}/php-cs-fixer.phar"
  if download_url "${_URL}" "${_BIN}" "php-cs-fixer"; then
    chmod +x "${_BIN}"
    info "php-cs-fixer installed."
    log_summary "PHP Lint" "✅ Installed"
  else
    log_summary "PHP Lint" "❌ Failed"
    error "Failed to download php-cs-fixer."
  fi
}

setup_dart() {
  log_info "── Checking Dart SDK ──"
  if command -v dart >/dev/null 2>&1; then
    log_summary "Dart" "✅ Available"
  else
    warn "Warning: dart SDK not found."
    log_summary "Dart" "⏭️ Not found"
  fi
}

setup_swift() {
  if [ "${OS}" = "darwin" ]; then
    log_info "── Setting up Swift Linters (macOS) ──"

    if [ "$DRY_RUN" -eq 1 ]; then
      log_info "DRY-RUN: Would install swiftformat and swiftlint via brew."
      log_summary "Swift" "⚖️ Previewed"
      return 0
    fi

    if command -v brew >/dev/null 2>&1; then
      brew list swiftformat >/dev/null 2>&1 || brew install swiftformat
      brew list swiftlint >/dev/null 2>&1 || brew install swiftlint
      info "Swift linters ensured."
      log_summary "Swift" "✅ Installed via brew"
    else
      warn "Warning: brew not found. Cannot install Swift linters."
      log_summary "Swift" "❌ Failed (no brew)"
    fi
  else
    log_summary "Swift" "⏭️ Skipped (non-macOS)"
  fi
}

setup_dotnet() {
  log_info "── Checking .NET SDK ──"
  if command -v dotnet >/dev/null 2>&1; then
    log_summary ".NET" "✅ Available"
  else
    warn "Warning: .NET SDK not found."
    log_summary ".NET" "⏭️ Not found"
  fi
}

# ── Main Execution ───────────────────────────────────────────────────────────

# Argument parsing for flags
RAW_ARGS=""
for arg in "$@"; do
  case "$arg" in
  -q | --quiet)
    VERBOSE=0
    ;;
  -v | --verbose)
    # shellcheck disable=SC2034
    VERBOSE=2
    ;;
  --dry-run)
    DRY_RUN=1
    log_warn "Running in DRY-RUN mode. No changes will be applied."
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  *) RAW_ARGS="${RAW_ARGS} ${arg}" ;;
  esac
done

if [ -z "$(echo "${RAW_ARGS}" | tr -d ' ')" ]; then
  modules="node python gitleaks checkmake powershell java ruby php dart swift dotnet hooks"
else
  modules="${RAW_ARGS}"
fi

printf "### Setup Execution Summary\n\n" >"$TMP_SUMMARY"
printf "| Module | Status |\n" >>"$TMP_SUMMARY"
printf "| :--- | :--- |\n" >>"$TMP_SUMMARY"

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
  hooks) setup_hooks ;;
  all)
    setup_node
    setup_python
    install_gitleaks
    install_checkmake
    install_hadolint
    install_go_lint
    install_iac_lint
    setup_powershell
    install_java_lint
    install_ruby_lint
    install_php_lint
    setup_dart
    setup_swift
    setup_dotnet
    setup_hooks
    ;;
  *) error "Unknown module: $module" ;;
  esac
done

# Write summary to CI if available
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
  cat "$TMP_SUMMARY" >>"$GITHUB_STEP_SUMMARY"
fi
rm -f "$TMP_SUMMARY"

info "\n✨ Setup step $modules complete!"
