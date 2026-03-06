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
msys* | mingw*)
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
  [ "${_OS_TAG}" = "windows" ] && _TAR_TAG="windows" # redundant but explicit
  _TAR="gitleaks_${GITLEAKS_VERSION#v}_${_TAR_TAG}_${_ARCH_N}.tar.gz"
  # zip for windows? No, gitleaks provides .tar.gz even for windows.
  _URL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR}"
  _TMP=$(mktemp -d)
  if download_url "${_URL}" "${_TMP}/gitleaks.tar.gz" "gitleaks"; then
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
  if [ ! -x "${VENV}/bin/tflint" ]; then
    _URL="${GITHUB_PROXY}https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh"
    if [ "${OS}" = "darwin" ]; then
      # Manual download for darwin as script uses sudo/usr/local
      _TAR="tflint_darwin_arm64.zip" # approximation
      [ "${_ARCH_N}" = "x64" ] && _TAR="tflint_darwin_amd64.zip"
      _URL="${GITHUB_PROXY}https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/${_TAR}"
      _TMP=$(mktemp -d)
      if download_url "${_URL}" "${_TMP}/tflint.zip" "tflint"; then
        unzip -q "${_TMP}/tflint.zip" -d "${_TMP}"
        mv "${_TMP}/tflint" "${VENV}/bin/tflint"
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
  if [ ! -x "${VENV}/bin/kube-linter" ]; then
    _SUFFIX="linux"
    [ "${OS}" = "darwin" ] && _SUFFIX="darwin"
    _URL="${GITHUB_PROXY}https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/kube-linter-$_SUFFIX"
    if download_url "${_URL}" "${VENV}/bin/kube-linter" "kube-linter"; then
      chmod +x "${VENV}/bin/kube-linter"
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

# ── Main Execution ───────────────────────────────────────────────────────────

if [ $# -eq 0 ]; then
  modules="node python gitleaks checkmake hooks"
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
  hooks) setup_hooks ;;
  all)
    setup_node
    setup_python
    install_gitleaks
    install_checkmake
    install_hadolint
    install_go_lint
    install_iac_lint
    setup_hooks
    ;;
  *) error "Unknown module: $module" ;;
  esac
done

info "\n✨ Setup step $modules complete!"
