#!/bin/sh
# scripts/setup.sh - Modularized Project Setup Script
# This script is designed for both local development and CI/CD JIT installation.
# usage: sh scripts/setup.sh [module1] [module2] ...
# modules: node, python, gitleaks, hadolint, go, iac, hooks, all (default)

set -e

# ── Configuration ────────────────────────────────────────────────────────────
VENV=${VENV:-.venv}
PYTHON=${PYTHON:-python3}
GITHUB_PROXY=${GITHUB_PROXY:-https://gh-proxy.sn0wdr1am.com/}

# Tool Versions
GITLEAKS_VERSION=${GITLEAKS_VERSION:-v8.26.0}
HADOLINT_VERSION=${HADOLINT_VERSION:-v2.12.0}
GOLANGCI_VERSION=${GOLANGCI_VERSION:-v1.64.6}
CHECKMAKE_VERSION=${CHECKMAKE_VERSION:-v0.3.2}
TFLINT_VERSION=${TFLINT_VERSION:-v0.55.1}
KUBE_LINTER_VERSION=${KUBE_LINTER_VERSION:-v0.7.2}
JAVA_FORMAT_VERSION=${JAVA_FORMAT_VERSION:-1.34.1}
PHP_CS_FIXER_VERSION=${PHP_CS_FIXER_VERSION:-v3.94.2}

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# ── Functions ────────────────────────────────────────────────────────────────

log() { printf "%b%s%b\n" "${BLUE}" "$1" "${NC}"; }
info() { printf "%b%s%b\n" "${GREEN}" "$1" "${NC}"; }
warn() { printf "%b%s%b\n" "${YELLOW}" "$1" "${NC}"; }
error() {
  printf "%b%s%b\n" "${RED}" "$1" "${NC}" >&2
  exit 1
}

# Robust download helper with proxy fallback
download_url() {
  _URL="$1"
  _OUT="$2"
  _DESC="$3"

  if curl --retry 3 -fsSL "${_URL}" -o "${_OUT}"; then
    return 0
  fi

  # Fallback if proxy failed (522, etc.)
  if [ -n "${GITHUB_PROXY}" ] && echo "${_URL}" | grep -q "^${GITHUB_PROXY}"; then
    _FALLBACK_URL="${_URL#"$GITHUB_PROXY"}"
    warn "Proxy download failed for ${_DESC}, retrying directly from ${_FALLBACK_URL}..."
    if curl --retry 3 -fsSL "${_FALLBACK_URL}" -o "${_OUT}"; then
      return 0
    fi
  fi

  return 1
}

setup_node() {
  log "── Setting up Node.js & pnpm ──"
  if command -v corepack >/dev/null 2>&1; then
    corepack enable
  else
    warn "Warning: corepack not found. Ensure Node.js 16.9+ is installed."
  fi
  if [ -f package.json ]; then
    pnpm install
    info "Node.js dependencies installed."
  fi
}

setup_python() {
  log "── Setting up Python Virtual Environment ──"
  if [ ! -d "$VENV" ]; then
    "$PYTHON" -m venv "$VENV"
  fi
  "$VENV/bin/pip" install --upgrade pip
  if [ -f requirements-dev.txt ]; then
    "$VENV/bin/pip" install -r requirements-dev.txt
    info "Python dev dependencies installed in ${VENV}."
  fi
}

install_gitleaks() {
  _BIN="${VENV}/bin/gitleaks${_EXE}"
  if [ -x "${_BIN}" ]; then return 0; fi
  log "── Installing gitleaks ${GITLEAKS_VERSION} ──"
  _TAR_TAG="${_OS_TAG}"
  [ "${_OS_TAG}" = "windows" ] && _TAR_TAG="windows"
  _TMP=$(mktemp -d)

  if [ "${_OS_TAG}" = "windows" ]; then
    _ARCH_W="x64"
    [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_W="arm64" # approximations based on known variants
    # actually gitleaks uses x64, x32, armv6, armv7. Assuming x64 for typical Windows setups.
    _ARCH_W="x64"
    _TAR="gitleaks_${GITLEAKS_VERSION#v}_${_TAR_TAG}_${_ARCH_W}.zip"
    _URL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR}"

    if download_url "${_URL}" "${_TMP}/gitleaks.zip" "gitleaks"; then
      unzip -q "${_TMP}/gitleaks.zip" -d "${_TMP}"
      mv "${_TMP}/gitleaks.exe" "${_BIN}"
      chmod +x "${_BIN}"
      info "gitleaks installed."
    else
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
    else
      error "Failed to download gitleaks."
    fi
  fi
  rm -rf "${_TMP}"
}

install_hadolint() {
  _BIN="${VENV}/bin/hadolint${_EXE}"
  if [ -x "${_BIN}" ]; then return 0; fi
  log "── Installing hadolint ${HADOLINT_VERSION} ──"
  _SUFFIX="Linux-x86_64"
  if [ "${OS}" = "darwin" ]; then
    _SUFFIX="Darwin-x86_64"
  elif [ "${_OS_TAG}" = "windows" ]; then _SUFFIX="Windows-x86_64.exe"; fi
  _URL="${GITHUB_PROXY}https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${_SUFFIX}"
  if download_url "${_URL}" "${_BIN}" "hadolint"; then
    chmod +x "${_BIN}"
    info "hadolint installed."
  else
    error "Failed to download hadolint."
  fi
}

install_go_lint() {
  _BIN="${VENV}/bin/golangci-lint"
  if [ -x "${_BIN}" ]; then return 0; fi
  log "── Installing golangci-lint ${GOLANGCI_VERSION} ──"
  _URL="${GITHUB_PROXY}https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"
  _TMP=$(mktemp -d)
  if download_url "${_URL}" "${_TMP}/install_go.sh" "golangci-lint-installer"; then
    export BINDIR="${VENV}/bin"
    bash "${_TMP}/install_go.sh" "${GOLANGCI_VERSION}"
    rm -rf "${_TMP}"
    info "golangci-lint installed."
  else
    error "Failed to download golangci-lint installer."
  fi
}

install_checkmake() {
  _BIN="${VENV}/bin/checkmake${_EXE}"
  if [ -x "${_BIN}" ]; then return 0; fi
  log "── Installing checkmake ${CHECKMAKE_VERSION} ──"
  _OS_S="${_OS_TAG}"
  _ARCH_S="amd64"
  [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_S="arm64"

  # Asset name: checkmake-v0.3.2.darwin.arm64 (direct binary)
  _FILE="checkmake-${CHECKMAKE_VERSION}.${_OS_S}.${_ARCH_S}${_EXE}"
  _URL="${GITHUB_PROXY}https://github.com/checkmake/checkmake/releases/download/${CHECKMAKE_VERSION}/${_FILE}"

  if download_url "${_URL}" "${_BIN}" "checkmake"; then
    chmod +x "${_BIN}"
    info "checkmake installed."
  else
    error "Failed to download checkmake from ${_URL}"
  fi
}

install_iac_lint() {
  log "── Installing IaC tools (tflint, kube-linter) ──"
  # TFLint
  if [ ! -x "${VENV}/bin/tflint${_EXE}" ]; then
    _URL="${GITHUB_PROXY}https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh"
    if [ "${OS}" = "darwin" ] || [ "${_OS_TAG}" = "windows" ]; then
      # Manual download for darwin and windows to bypass linux-only bash script
      _TAR_OS="${_OS_TAG}"
      _TAR_ARCH="amd64"
      [ "${_ARCH_N}" = "arm64" ] && _TAR_ARCH="arm64"

      _TAR="tflint_${_TAR_OS}_${_TAR_ARCH}.zip"
      _URL="${GITHUB_PROXY}https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/${_TAR}"
      _TMP=$(mktemp -d)
      if download_url "${_URL}" "${_TMP}/tflint.zip" "tflint"; then
        unzip -q "${_TMP}/tflint.zip" -d "${_TMP}"
        mv "${_TMP}/tflint${_EXE}" "${VENV}/bin/tflint${_EXE}"
        chmod +x "${VENV}/bin/tflint${_EXE}"
        rm -rf "${_TMP}"
      else
        error "Failed to download tflint."
      fi
    else
      _TMP=$(mktemp -d)
      if download_url "${_URL}" "${_TMP}/install_tflint.sh" "tflint-installer"; then
        TFLINT_INSTALL_PATH="${VENV}/bin" bash "${_TMP}/install_tflint.sh"
        rm -rf "${_TMP}"
      else
        error "Failed to download tflint installer."
      fi
    fi
  fi
  # Kube-Linter
  if [ ! -x "${VENV}/bin/kube-linter${_EXE}" ]; then
    _SUFFIX="linux"
    [ "${OS}" = "darwin" ] && _SUFFIX="darwin"
    [ "${_OS_TAG}" = "windows" ] && _SUFFIX="windows.exe"

    _URL="${GITHUB_PROXY}https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/kube-linter-$_SUFFIX"
    if download_url "${_URL}" "${VENV}/bin/kube-linter${_EXE}" "kube-linter"; then
      chmod +x "${VENV}/bin/kube-linter${_EXE}"
    else
      error "Failed to download kube-linter."
    fi
  fi
  info "IaC tools installed."
}

setup_hooks() {
  log "── Activating Pre-commit Hooks ──"
  if [ -x "$VENV/bin/pre-commit" ]; then
    "$VENV/bin/pre-commit" install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg
    info "Pre-commit hooks activated."
  else
    warn "Warning: pre-commit not found. Run python module first."
  fi
}

setup_powershell() {
  log "── Setting up PowerShell Linter ──"
  if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -Command "if (!(Get-Module -ListAvailable PSScriptAnalyzer)) { Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser }"
    info "PSScriptAnalyzer installed."
  else
    warn "Warning: pwsh not found. Skipping PowerShell linter setup."
  fi
}

install_java_lint() {
  _JAR="${VENV}/bin/google-java-format.jar"
  _BIN="${VENV}/bin/google-java-format"
  if [ -f "${_JAR}" ]; then return 0; fi
  log "── Installing google-java-format ${JAVA_FORMAT_VERSION} ──"
  _URL="${GITHUB_PROXY}https://github.com/google/google-java-format/releases/download/v${JAVA_FORMAT_VERSION}/google-java-format-${JAVA_FORMAT_VERSION}-all-deps.jar"
  if download_url "${_URL}" "${_JAR}" "google-java-format"; then
    printf "#!/bin/sh\njava -jar \"%s\" \"\$@\"\n" "${_JAR}" >"${_BIN}"
    chmod +x "${_BIN}"
    info "google-java-format installed."
  else
    error "Failed to download google-java-format."
  fi
}

install_ruby_lint() {
  log "── Setting up Rubocop ──"
  if command -v gem >/dev/null 2>&1; then
    _RUBY_VER=$(ruby -e 'print RUBY_VERSION')
    _RUBY_MAJOR=$(echo "$_RUBY_VER" | cut -d. -f1)
    _RUBY_MINOR=$(echo "$_RUBY_VER" | cut -d. -f2)

    if [ "$_RUBY_MAJOR" -lt 2 ] || { [ "$_RUBY_MAJOR" -eq 2 ] && [ "$_RUBY_MINOR" -lt 7 ]; }; then
      warn "Warning: Ruby version $_RUBY_VER is too old (< 2.7.0). Attempting to install Rubocop v0.93.1 which is compatible with older Ruby."
      gem install rubocop -v 0.93.1 --user-install --no-document --quiet || warn "Failed to install Rubocop. Please upgrade Ruby."
    else
      gem install rubocop --user-install --no-document --quiet || warn "Failed to install Rubocop."
    fi
    info "Rubocop setup finished."
  else
    warn "Warning: gem not found. Skipping Rubocop setup."
  fi
}

install_php_lint() {
  _BIN="${VENV}/bin/php-cs-fixer"
  if [ -x "${_BIN}" ]; then return 0; fi
  log "── Installing php-cs-fixer ${PHP_CS_FIXER_VERSION} ──"
  _URL="${GITHUB_PROXY}https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/releases/download/${PHP_CS_FIXER_VERSION}/php-cs-fixer.phar"
  if download_url "${_URL}" "${_BIN}" "php-cs-fixer"; then
    chmod +x "${_BIN}"
    info "php-cs-fixer installed."
  else
    error "Failed to download php-cs-fixer."
  fi
}

setup_dart() {
  log "── Checking Dart SDK ──"
  command -v dart >/dev/null 2>&1 || warn "Warning: dart SDK not found."
}

setup_swift() {
  if [ "${OS}" = "darwin" ]; then
    log "── Setting up Swift Linters (macOS) ──"
    if command -v brew >/dev/null 2>&1; then
      brew list swiftformat >/dev/null 2>&1 || brew install swiftformat
      brew list swiftlint >/dev/null 2>&1 || brew install swiftlint
      info "Swift linters ensured."
    else
      warn "Warning: brew not found. Cannot install Swift linters."
    fi
  fi
}

setup_dotnet() {
  log "── Checking .NET SDK ──"
  command -v dotnet >/dev/null 2>&1 || warn "Warning: .NET SDK not found."
}

# ── Main Execution ───────────────────────────────────────────────────────────

if [ $# -eq 0 ]; then
  modules="node python gitleaks checkmake powershell java ruby php dart swift dotnet hooks"
else
  modules="$*"
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

info "\n✨ Setup step $modules complete!"
