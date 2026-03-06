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
TFLINT_VERSION=${TFLINT_VERSION:-v0.55.1}
KUBE_LINTER_VERSION=${KUBE_LINTER_VERSION:-v0.7.2}

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
case "${OS}" in
darwin) _OS_TAG="darwin" ;;
linux) _OS_TAG="linux" ;;
*) _OS_TAG="linux" ;;
esac

# ── Functions ────────────────────────────────────────────────────────────────

log() { printf "%b%s%b\n" "${BLUE}" "$1" "${NC}"; }
info() { printf "%b%s%b\n" "${GREEN}" "$1" "${NC}"; }
warn() { printf "%b%s%b\n" "${YELLOW}" "$1" "${NC}"; }
error() { printf "%b%s%b\n" "${RED}" "$1" "${NC}"; }

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
  _BIN="${VENV}/bin/gitleaks"
  if [ -x "${_BIN}" ]; then return 0; fi
  log "── Installing gitleaks ${GITLEAKS_VERSION} ──"
  _TAR="gitleaks_${GITLEAKS_VERSION#v}_${_OS_TAG}_${_ARCH_N}.tar.gz"
  _URL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR}"
  _TMP=$(mktemp -d)
  if curl --retry 3 -fsSL "${_URL}" -o "${_TMP}/gitleaks.tar.gz"; then
    tar -xzf "${_TMP}/gitleaks.tar.gz" -C "${_TMP}" gitleaks
    mv "${_TMP}/gitleaks" "${_BIN}"
    chmod +x "${_BIN}"
    info "gitleaks installed."
  else
    error "Failed to download gitleaks."
  fi
  rm -rf "${_TMP}"
}

install_hadolint() {
  _BIN="${VENV}/bin/hadolint"
  if [ -x "${_BIN}" ]; then return 0; fi
  log "── Installing hadolint ${HADOLINT_VERSION} ──"
  _SUFFIX="Linux-x86_64"
  if [ "${OS}" = "darwin" ]; then _SUFFIX="Darwin-x86_64"; fi
  _URL="${GITHUB_PROXY}https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${_SUFFIX}"
  if curl --retry 3 -fsSL "${_URL}" -o "${_BIN}"; then
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
  # Official install script via curl
  export BINDIR="${VENV}/bin"
  curl -sSfL "${GITHUB_PROXY}https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh" | sh -s -- "${GOLANGCI_VERSION}"
  info "golangci-lint installed."
}

install_iac_lint() {
  log "── Installing IaC tools (tflint, kube-linter) ──"
  # TFLint
  if [ ! -x "${VENV}/bin/tflint" ]; then
    _URL="${GITHUB_PROXY}https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh"
    if [ "${OS}" = "darwin" ]; then
      # Manual download for darwin as script uses sudo/usr/local
      _TAR="tflint_darwin_arm64.zip" # approximation
      [ "${_ARCH_N}" = "x64" ] && _TAR="tflint_darwin_amd64.zip"
      _URL="${GITHUB_PROXY}https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/${_TAR}"
      _TMP=$(mktemp -d)
      curl -fsSL "${_URL}" -o "${_TMP}/tflint.zip"
      unzip -q "${_TMP}/tflint.zip" -d "${_TMP}"
      mv "${_TMP}/tflint" "${VENV}/bin/tflint"
      rm -rf "${_TMP}"
    else
      curl -sSfL "${_URL}" | TFLINT_INSTALL_PATH="${VENV}/bin" sh
    fi
  fi
  # Kube-Linter
  if [ ! -x "${VENV}/bin/kube-linter" ]; then
    _SUFFIX="linux"
    [ "${OS}" = "darwin" ] && _SUFFIX="darwin"
    _URL="${GITHUB_PROXY}https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/kube-linter-$_SUFFIX"
    curl -fsSL "${_URL}" -o "${VENV}/bin/kube-linter"
    chmod +x "${VENV}/bin/kube-linter"
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

# ── Main Execution ───────────────────────────────────────────────────────────

if [ $# -eq 0 ]; then
  modules="node python gitleaks hooks"
else
  modules="$*"
fi

for module in $modules; do
  case $module in
  node) setup_node ;;
  python) setup_python ;;
  gitleaks) install_gitleaks ;;
  hadolint) install_hadolint ;;
  go) install_go_lint ;;
  iac) install_iac_lint ;;
  hooks) setup_hooks ;;
  all)
    setup_node
    setup_python
    install_gitleaks
    install_hadolint
    install_go_lint
    install_iac_lint
    setup_hooks
    ;;
  *) error "Unknown module: $module" ;;
  esac
done

info "\n✨ Setup step $modules complete!"
