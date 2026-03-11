#!/bin/sh
# scripts/setup.sh - Modular Project Setup Engine
#
# Purpose:
#   Facilitates local development and CI/CD JIT toolchain installation.
#   Maintains an isolated, reproducible development environment.
#
# Usage:
#   sh scripts/setup.sh [OPTIONS] [MODULES]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Network), Rule 04 (Security), Rule 05 (Dependencies), Rule 08 (Dev Env).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Delta-based installation (cooldown 24h).
#   - Multi-language support (Node, Python, Go, Rust, Java, etc.).
#   - JIT security toolchain (Trivy, OSV-Scanner).

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Configuration ────────────────────────────────────────────────────────────
# Global variables (VENV, PYTHON, etc.) are sourced from common.sh
# Modules can be overridden by command line args

# Purpose: Displays usage information for the setup engine.
# Examples:
#   show_help
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
  editorconfig-checker Install editorconfig-checker
  hooks              Activate Pre-commit Hooks
  all                Run all of the above

Environment Variables:
  VENV               Virtualenv directory (default: .venv)
  PYTHON             Python executable (default: python3)
  GITHUB_PROXY       Github proxy URL for asset downloads

EOF
}

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Internal logging wrapper for informational output.
#          Delegates to log_info in the common library.
# Params:
#   $1 - Message to log
# Examples:
#   log "Starting setup..."
log() {
  log_info "$1"
}

# Note: log_success, log_warn, and log_error are provided by common.sh

# ── Environment Detection ────────────────────────────────────────────────────

# OS/Arch Detection for module-specific binaries
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

# Purpose: Sanitizes a file path by replacing the home directory with a tilde.
# Params:
#   $1 - Path to sanitize
# Examples:
#   sanitize_path "/Users/john/work" -> "~/work"
sanitize_path() {
  local _PATH_SAN="$1"
  echo "$_PATH_SAN" | sed "s|$HOME|~|g"
}

# Purpose: Configures Node.js runtime and installs pnpm dependencies.
# Params:
#   None (uses global SSoT variables)
# Examples:
#   setup_node
setup_node() {
  local _T0_NODE
  _T0_NODE=$(date +%s)
  log_info "── Setting up Node.js & pnpm ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Node.js" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if command -v corepack >/dev/null 2>&1; then
    corepack enable
  fi

  if [ -f package.json ]; then
    local _STAT_NODE="✅ Installed"
    run_quiet "$NPM" install || _STAT_NODE="❌ Failed"
    local _VER_NODE
    _VER_NODE=$(get_version node)
    local _DUR_NODE
    _DUR_NODE=$(($(date +%s) - _T0_NODE))
    log_summary "Runtime" "Node.js" "$_STAT_NODE" "$_VER_NODE" "$_DUR_NODE"

    if [ "$_STAT_NODE" = "✅ Installed" ]; then
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

# Purpose: Initializes a Python virtual environment and installs development dependencies.
# Params:
#   None (uses global SSoT variables)
# Examples:
#   setup_python
setup_python() {
  local _T0_PY
  _T0_PY=$(date +%s)
  log_info "── Setting up Python Virtual Environment ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Python" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_PY="✅ Installed"
  if [ ! -d "$VENV" ]; then
    "$PYTHON" -m venv "$VENV" || _STAT_PY="❌ Failed"
  fi

  if [ "$_STAT_PY" = "✅ Installed" ]; then
    run_quiet "$VENV/bin/pip" install --upgrade pip || _STAT_PY="⚠️ Warning"
    if [ -f requirements-dev.txt ]; then
      run_quiet "$VENV/bin/pip" install -r requirements-dev.txt || _STAT_PY="❌ Failed"
    fi
  fi

  if [ -d "$VENV" ]; then
    local _VER_PY
    _VER_PY=$(get_version "$VENV/bin/python")
    local _DUR_PY
    _DUR_PY=$(($(date +%s) - _T0_PY))
    log_summary "Runtime" "Python" "$_STAT_PY" "$_VER_PY" "$_DUR_PY"
  else
    log_summary "Runtime" "Python" "❌ Failed" "-" "0"
  fi
}

# Purpose: Installs Gitleaks for secrets scanning into the project's virtualenv.
# Params:
#   None (uses global GITLEAKS_VERSION)
# Examples:
#   install_gitleaks
install_gitleaks() {
  local _T0_GITL
  _T0_GITL=$(date +%s)
  local _BIN_GITL
  _BIN_GITL="${VENV}/bin/gitleaks${_EXE}"
  if [ -x "${_BIN_GITL}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Lint Tool" "Gitleaks" "✅ Exists" "$(get_version "$_BIN_GITL")" "0"
    return 0
  fi
  log_info "── Installing gitleaks ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Gitleaks" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _TAR_TAG_GITL
  _TAR_TAG_GITL="${_OS_TAG}"
  local _TMP_GITL
  _TMP_GITL=$(mktemp -d)
  local _STAT_GITL="✅ Installed"

  if [ "${_OS_TAG}" = "windows" ]; then
    local _ARCH_W_GITL="x64"
    [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_W_GITL="arm64"
    local _TAR_GITL
    _TAR_GITL="gitleaks_${GITLEAKS_VERSION#v}_windows_${_ARCH_W_GITL}.zip"
    local _URL_GITL
    _URL_GITL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR_GITL}"

    if download_url "${_URL_GITL}" "${_TMP_GITL}/gitleaks.zip" "gitleaks"; then
      unzip -q "${_TMP_GITL}/gitleaks.zip" -d "${_TMP_GITL}" || _STAT_GITL="❌ Failed"
      if [ "$_STAT_GITL" = "✅ Installed" ]; then
        mv "${_TMP_GITL}/gitleaks.exe" "${_BIN_GITL}" || _STAT_GITL="❌ Failed"
      fi
    else
      _STAT_GITL="❌ Failed"
    fi
  else
    local _TAR_GITL
    _TAR_GITL="gitleaks_${GITLEAKS_VERSION#v}_${_TAR_TAG_GITL}_${_ARCH_N}"
    # Arm64 fix for linux if needed (gitleaks uses arm64 tag)
    case "${_ARCH_N}" in
    aarch64) _TAR_GITL="gitleaks_${GITLEAKS_VERSION#v}_${_TAR_TAG_GITL}_arm64" ;;
    esac
    _TAR_GITL="${_TAR_GITL}.tar.gz"

    local _URL_GITL
    _URL_GITL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR_GITL}"
    if download_url "${_URL_GITL}" "${_TMP_GITL}/gitleaks.tar.gz" "gitleaks"; then
      tar -xzf "${_TMP_GITL}/gitleaks.tar.gz" -C "${_TMP_GITL}" gitleaks || _STAT_GITL="❌ Failed"
      if [ "$_STAT_GITL" = "✅ Installed" ]; then
        mv "${_TMP_GITL}/gitleaks" "${_BIN_GITL}" || _STAT_GITL="❌ Failed"
      fi
    else
      _STAT_GITL="❌ Failed"
    fi
  fi
  if [ -x "${_BIN_GITL}" ]; then
    local _DUR_GITL
    _DUR_GITL=$(($(date +%s) - _T0_GITL))
    log_summary "Lint Tool" "Gitleaks" "$_STAT_GITL" "$(get_version "$_BIN_GITL")" "$_DUR_GITL"
  else
    log_summary "Lint Tool" "Gitleaks" "❌ Failed" "-" "0"
  fi
  rm -rf "${_TMP_GITL}"
}

# Purpose: Installs Hadolint for Dockerfile linting.
# Params:
#   None (uses global HADOLINT_VERSION)
# Examples:
#   install_hadolint
install_hadolint() {
  local _T0_HADO
  _T0_HADO=$(date +%s)
  local _BIN_HADO
  _BIN_HADO="${VENV}/bin/hadolint${_EXE}"
  if [ -x "${_BIN_HADO}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Lint Tool" "Hadolint" "✅ Exists" "$(get_version "$_BIN_HADO")" "0"
    return 0
  fi

  if ! has_lang_files "Dockerfile docker-compose.yml" "*.dockerfile *.Dockerfile"; then
    log_summary "Lint Tool" "Hadolint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing hadolint ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Hadolint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _ARCH_HADO="x86_64"
  [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_HADO="arm64"

  local _OS_HADO="Linux"
  [ "${OS}" = "darwin" ] && _OS_HADO="Darwin"
  [ "${_OS_TAG}" = "windows" ] && _OS_HADO="Windows"

  local _SUFFIX_HADO="${_OS_HADO}-${_ARCH_HADO}"
  [ "${_OS_TAG}" = "windows" ] && _SUFFIX_HADO="${_SUFFIX_HADO}.exe"

  local _URL_HADO
  _URL_HADO="${GITHUB_PROXY}https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${_SUFFIX_HADO}"
  local _STAT_HADO="✅ Installed"
  if download_url "${_URL_HADO}" "${_BIN_HADO}" "hadolint"; then
    chmod +x "${_BIN_HADO}" 2>/dev/null || true
  else
    _STAT_HADO="❌ Failed"
  fi
  local _DUR_HADO
  _DUR_HADO=$(($(date +%s) - _T0_HADO))
  log_summary "Lint Tool" "Hadolint" "$_STAT_HADO" "$(get_version "$_BIN_HADO")" "$_DUR_HADO"
}

# Purpose: Installs golangci-lint for Go project linting.
# Params:
#   None (uses global GOLANGCI_VERSION)
# Examples:
#   install_go_lint
install_go_lint() {
  local _T0_GO
  _T0_GO=$(date +%s)
  local _BIN_GO
  _BIN_GO="${VENV}/bin/golangci-lint"
  if [ -x "${_BIN_GO}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Lint Tool" "Go Lint" "✅ Exists" "$(get_version "$_BIN_GO")" "0"
    return 0
  fi

  if ! has_lang_files "go.mod go.sum" "*.go"; then
    log_summary "Lint Tool" "Go Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing golangci-lint ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Go Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _URL_GO
  _URL_GO="${GITHUB_PROXY}https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"
  local _TMP_GO
  _TMP_GO=$(mktemp -d)
  local _STAT_GO="✅ Installed"
  if download_url "${_URL_GO}" "${_TMP_GO}/install_go.sh" "golangci-lint-installer"; then
    export BINDIR="${VENV}/bin"
    run_quiet sh "${_TMP_GO}/install_go.sh" "${GOLANGCI_VERSION}"
  else
    _STAT_GO="❌ Failed"
  fi
  rm -rf "${_TMP_GO}"
  local _DUR_GO
  _DUR_GO=$(($(date +%s) - _T0_GO))
  log_summary "Lint Tool" "Go Lint" "$_STAT_GO" "$(get_version "$_BIN_GO")" "$_DUR_GO"
}

# Purpose: Installs checkmake for Makefile linting.
# Params:
#   None (uses global CHECKMAKE_VERSION)
# Examples:
#   install_checkmake
install_checkmake() {
  local _T0_CM
  _T0_CM=$(date +%s)
  if ! has_lang_files "Makefile" "*.make"; then
    log_summary "Lint Tool" "Checkmake" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _BIN_CM
  _BIN_CM="${VENV}/bin/checkmake${_EXE}"
  if [ -x "${_BIN_CM}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Lint Tool" "Checkmake" "✅ Exists" "$(get_version "$_BIN_CM")" "0"
    return 0
  fi

  log_info "── Installing checkmake ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Checkmake" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _OS_TAG_CM="${_OS_TAG}"
  local _ARCH_N_CM="amd64"
  [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _ARCH_N_CM="arm64"
  local _FILE_CM
  _FILE_CM="checkmake-${CHECKMAKE_VERSION}.${_OS_TAG_CM}.${_ARCH_N_CM}${_EXE}"
  local _URL_CM
  _URL_CM="${GITHUB_PROXY}https://github.com/checkmake/checkmake/releases/download/${CHECKMAKE_VERSION}/${_FILE_CM}"

  local _STAT_CM="✅ Installed"
  if download_url "${_URL_CM}" "${_BIN_CM}" "checkmake"; then
    chmod +x "${_BIN_CM}" 2>/dev/null || true
  else
    _STAT_CM="❌ Failed"
  fi
  local _DUR_CM
  _DUR_CM=$(($(date +%s) - _T0_CM))
  log_summary "Lint Tool" "Checkmake" "$_STAT_CM" "$(get_version "$_BIN_CM")" "$_DUR_CM"
}

# Purpose: Installs IaC linting tools (TFLint and Kube-Linter).
# Params:
#   None (uses global TFLINT_VERSION and KUBE_LINTER_VERSION)
# Examples:
#   install_iac_lint
install_iac_lint() {
  local _T0_IAC
  _T0_IAC=$(date +%s)
  if ! has_lang_files "" "*.tf *.tfvars *.yaml *.yml *.json"; then
    log_summary "Lint Tool" "IaC" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing IaC tools ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "TFLint" "⚖️ Previewed" "-" "0"
    log_summary "Lint Tool" "Kube-Linter" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # TFLint
  if [ ! -x "${VENV}/bin/tflint${_EXE}" ]; then
    local _TAR_OS_IAC="${_OS_TAG}"
    local _TAR_ARCH_IAC="amd64"
    [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _TAR_ARCH_IAC="arm64"
    local _TAR_IAC
    _TAR_IAC="tflint_${_TAR_OS_IAC}_${_TAR_ARCH_IAC}.zip"
    local _URL_IAC
    _URL_IAC="${GITHUB_PROXY}https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/${_TAR_IAC}"
    local _TMP_IAC
    _TMP_IAC=$(mktemp -d)
    local _T_STAT_IAC=""
    if download_url "${_URL_IAC}" "${_TMP_IAC}/tflint.zip" "tflint"; then
      unzip -q "${_TMP_IAC}/tflint.zip" -d "${_TMP_IAC}" || _T_STAT_IAC="failed"
      if [ "$_T_STAT_IAC" != "failed" ]; then
        mv "${_TMP_IAC}/tflint${_EXE}" "${VENV}/bin/tflint${_EXE}" || _T_STAT_IAC="failed"
        chmod +x "${VENV}/bin/tflint${_EXE}" 2>/dev/null || true
        log_summary "Lint Tool" "TFLint" "✅ Installed" "$(get_version "${VENV}/bin/tflint${_EXE}")" "$(($(date +%s) - _T0_IAC))"
      else
        log_summary "Lint Tool" "TFLint" "❌ Failed" "-" "0"
      fi
    else
      log_summary "Lint Tool" "TFLint" "❌ Failed" "-" "0"
    fi
    rm -rf "${_TMP_IAC}"
  else
    log_summary "Lint Tool" "TFLint" "✅ Exists" "$(get_version "${VENV}/bin/tflint${_EXE}")" "0"
  fi

  # Kube-Linter
  if [ ! -x "${VENV}/bin/kube-linter${_EXE}" ]; then
    local _K_OS_IAC="linux"
    [ "${OS}" = "darwin" ] && _K_OS_IAC="darwin"
    local _K_SUFFIX_IAC=""
    { [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ]; } && _K_SUFFIX_IAC="_arm64"
    local _FILE_IAC
    if [ "${_OS_TAG}" = "windows" ]; then
      _FILE_IAC="kube-linter${_K_SUFFIX_IAC}.exe"
    else
      _FILE_IAC="kube-linter-${_K_OS_IAC}${_K_SUFFIX_IAC}"
    fi
    local _URL_KUBE
    _URL_KUBE="${GITHUB_PROXY}https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/${_FILE_IAC}"
    if download_url "${_URL_KUBE}" "${VENV}/bin/kube-linter${_EXE}" "kube-linter"; then
      chmod +x "${VENV}/bin/kube-linter${_EXE}" 2>/dev/null || true
      log_summary "Lint Tool" "Kube-Linter" "✅ Installed" "$(get_version "${VENV}/bin/kube-linter${_EXE}" "version")" "$(($(date +%s) - _T0_IAC))"
    else
      log_summary "Lint Tool" "Kube-Linter" "❌ Failed" "-" "0"
    fi
  else
    log_summary "Lint Tool" "Kube-Linter" "✅ Exists" "$(get_version "${VENV}/bin/kube-linter${_EXE}" "version")" "0"
  fi
}

# Purpose: Activates git pre-commit hooks.
# Params:
#   None
# Examples:
#   setup_hooks
setup_hooks() {
  local _T0_HOOK
  _T0_HOOK=$(date +%s)
  log_info "── Setting up Pre-commit Hooks ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Other" "Hooks" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if [ -x "$VENV/bin/pre-commit" ]; then
    local _STAT_HOOK="✅ Activated"
    run_quiet "$VENV/bin/pre-commit" install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg || _STAT_HOOK="❌ Failed"
    local _V_HOOK
    _V_HOOK=$(get_version "$VENV/bin/pre-commit")
    local _D_HOOK
    _D_HOOK=$(($(date +%s) - _T0_HOOK))
    log_summary "Other" "Hooks" "$_STAT_HOOK" "$_V_HOOK" "$_D_HOOK"
  else
    log_summary "Other" "Hooks" "❌ Failed (missing pre-commit)" "-" "0"
  fi
}

# Purpose: Configures PSScriptAnalyzer for PowerShell linting.
# Params:
#   None
# Examples:
#   setup_powershell
setup_powershell() {
  local _T0_PS
  _T0_PS=$(date +%s)
  if ! has_lang_files "" "*.ps1 *.psm1 *.psd1"; then
    log_summary "Lint Tool" "PowerShell" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Setting up PowerShell Linter ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "PowerShell" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if command -v pwsh >/dev/null 2>&1; then
    local _STAT_PS="✅ Installed"
    run_quiet pwsh -NoProfile -Command "if (!(Get-Module -ListAvailable PSScriptAnalyzer)) { Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser }" || _STAT_PS="❌ Failed"
    # shellcheck disable=SC2016
    local _V_PS
    # shellcheck disable=SC2016
    _V_PS=$(pwsh -NoProfile -Command '(Get-Module PSScriptAnalyzer -ListAvailable).Version | Select-Object -First 1 | ForEach-Object { $_.ToString() }' 2>/dev/null || echo "installed")
    local _D_PS
    _D_PS=$(($(date +%s) - _T0_PS))
    log_summary "Lint Tool" "PowerShell" "$_STAT_PS" "$_V_PS" "$_D_PS"
  else
    log_summary "Lint Tool" "PowerShell" "⏭️ Skipped (pwsh missing)" "-" "0"
  fi
}

# Purpose: Installs google-java-format for Java project linting.
# Params:
#   None (uses global JAVA_FORMAT_VERSION)
# Examples:
#   install_java_lint
install_java_lint() {
  local _T0_JAVA
  _T0_JAVA=$(date +%s)
  local _JAR_JAVA
  _JAR_JAVA="${VENV}/bin/google-java-format.jar"
  local _BIN_JAVA
  _BIN_JAVA="${VENV}/bin/google-java-format"
  if [ -f "${_JAR_JAVA}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Lint Tool" "Java Lint" "✅ Exists" "$JAVA_FORMAT_VERSION" "0"
    return 0
  fi

  if ! has_lang_files "pom.xml build.gradle" "*.java"; then
    log_summary "Lint Tool" "Java Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing google-java-format ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Java Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _URL_JAVA
  _URL_JAVA="${GITHUB_PROXY}https://github.com/google/google-java-format/releases/download/v${JAVA_FORMAT_VERSION}/google-java-format-${JAVA_FORMAT_VERSION}-all-deps.jar"
  local _STAT_JAVA="✅ Installed"
  if download_url "${_URL_JAVA}" "${_JAR_JAVA}" "google-java-format"; then
    printf "#!/bin/sh\njava -jar \"%s\" \"\$@\"\n" "${_JAR_JAVA}" >"${_BIN_JAVA}" || _STAT_JAVA="❌ Failed"
    chmod +x "${_BIN_JAVA}" 2>/dev/null || true
  else
    _STAT_JAVA="❌ Failed"
  fi
  local _DUR_JAVA
  _DUR_JAVA=$(($(date +%s) - _T0_JAVA))
  log_summary "Lint Tool" "Java Lint" "$_STAT_JAVA" "$JAVA_FORMAT_VERSION" "$_DUR_JAVA"
}

# Purpose: Sets up Rubocop for Ruby project linting.
# Params:
#   None
# Examples:
#   install_ruby_lint
install_ruby_lint() {
  local _T0_RUBY
  _T0_RUBY=$(date +%s)
  if ! has_lang_files "Gemfile Gemfile.lock" "*.rb"; then
    log_summary "Lint Tool" "Rubocop" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Setting up Rubocop ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Rubocop" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Check in PATH and common user-gem locations to avoid redundant slow gem install
  local _RUBO_BIN_REF="rubocop"
  if ! command -v rubocop >/dev/null 2>&1; then
    local _GEM_BIN_RUBY
    _GEM_BIN_RUBY=$(gem environment 2>/dev/null | grep "EXECUTABLE DIRECTORY" | awk '{print $NF}')
    if [ -x "$_GEM_BIN_RUBY/rubocop" ]; then
      _RUBO_BIN_REF="$_GEM_BIN_RUBY/rubocop"
    fi
  fi

  if command -v "$_RUBO_BIN_REF" >/dev/null 2>&1 && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Lint Tool" "Rubocop" "✅ Exists" "$(get_version "$_RUBO_BIN_REF")" "0"
    return 0
  fi

  if command -v gem >/dev/null 2>&1; then
    local _STAT_RUBY="✅ Installed"
    run_quiet gem install rubocop --user-install --no-document --quiet || _STAT_RUBY="❌ Failed"
    local _VER_RUBY
    _VER_RUBY=$(get_version rubocop)
    local _DUR_RUBY
    _DUR_RUBY=$(($(date +%s) - _T0_RUBY))
    log_summary "Lint Tool" "Rubocop" "$_STAT_RUBY" "$_VER_RUBY" "$_DUR_RUBY"
  else
    log_summary "Lint Tool" "Rubocop" "⏭️ Skipped (gem missing)" "-" "0"
  fi
}

# Purpose: Installs php-cs-fixer for PHP project linting.
# Params:
#   None (uses global PHP_CS_FIXER_VERSION)
# Examples:
#   install_php_lint
install_php_lint() {
  local _T0_PHP
  _T0_PHP=$(date +%s)
  local _BIN_PHP
  _BIN_PHP="${VENV}/bin/php-cs-fixer"
  if [ -x "${_BIN_PHP}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Lint Tool" "PHP Lint" "✅ Exists" "$PHP_CS_FIXER_VERSION" "0"
    return 0
  fi

  if ! has_lang_files "composer.json composer.lock" "*.php"; then
    log_summary "Lint Tool" "PHP Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_info "── Installing php-cs-fixer ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "PHP Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _URL_PHP
  _URL_PHP="${GITHUB_PROXY}https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/releases/download/${PHP_CS_FIXER_VERSION}/php-cs-fixer.phar"
  local _STAT_PHP="✅ Installed"
  if download_url "${_URL_PHP}" "${_BIN_PHP}" "php-cs-fixer"; then
    chmod +x "${_BIN_PHP}" 2>/dev/null || true
  else
    _STAT_PHP="❌ Failed"
  fi
  local _DUR_PHP
  _DUR_PHP=$(($(date +%s) - _T0_PHP))
  log_summary "Lint Tool" "PHP Lint" "$_STAT_PHP" "$PHP_CS_FIXER_VERSION" "$_DUR_PHP"
}

# Purpose: Verifies Dart SDK availability.
# Params:
#   None
# Examples:
#   setup_dart
setup_dart() {
  log_info "── Checking Dart SDK ──"
  if command -v dart >/dev/null 2>&1; then
    log_summary "Runtime" "Dart" "✅ Available" "$(get_version dart)" "0"
  else
    log_summary "Runtime" "Dart" "⏭️ Missing" "-" "0"
  fi
}

# Purpose: Sets up Swift linting tools on macOS.
# Params:
#   None
# Examples:
#   setup_swift
setup_swift() {
  local _T0_SWIFT
  _T0_SWIFT=$(date +%s)
  if ! has_lang_files "Package.swift" "*.swift"; then
    log_summary "Lint Tool" "Swift" "⏭️ Skipped" "-" "0"
    return 0
  fi
  if [ "${OS}" = "darwin" ]; then
    log_info "── Setting up Swift Linters (macOS) ──"

    local _PKG_MGR_SWIFT
    _PKG_MGR_SWIFT=$(get_macos_pkg_mgr)
    local _STAT_SWIFT="✅ Installed"
    if [ "$_PKG_MGR_SWIFT" = "brew" ]; then
      brew list swiftformat >/dev/null 2>&1 || brew install swiftformat >/dev/null 2>&1 || _STAT_SWIFT="⚠️ Partial"
      brew list swiftlint >/dev/null 2>&1 || brew install swiftlint >/dev/null 2>&1 || _STAT_SWIFT="❌ Failed"
      local _DUR_SWIFT
      _DUR_SWIFT=$(($(date +%s) - _T0_SWIFT))
      log_summary "Lint Tool" "Swift" "$_STAT_SWIFT" "$(get_version swiftlint lint --version)" "$_DUR_SWIFT"
    elif [ "$_PKG_MGR_SWIFT" = "port" ]; then
      log_info "Installing Swift formatters via MacPorts (requires sudo)..."
      port installed swiftformat 2>/dev/null | grep -q active || sudo port install swiftformat || _STAT_SWIFT="⚠️ Partial"
      port installed swiftlint 2>/dev/null | grep -q active || sudo port install swiftlint || _STAT_SWIFT="❌ Failed"
      local _DUR_SWIFT
      _DUR_SWIFT=$(($(date +%s) - _T0_SWIFT))
      log_summary "Lint Tool" "Swift" "$_STAT_SWIFT" "$(get_version swiftlint lint --version)" "$_DUR_SWIFT"
    else
      log_summary "Lint Tool" "Swift" "⏭️ Skipped (brew/port missing)" "-" "0"
    fi
  else
    log_summary "Lint Tool" "Swift" "⏭️ Skipped" "-" "0"
  fi
}

# Purpose: Verifies .NET SDK availability.
# Params:
#   None
# Examples:
#   setup_dotnet
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

# Purpose: Installs osv-scanner for vulnerability scanning.
# Params:
#   None (uses global OSV_SCANNER_VERSION)
# Examples:
#   install_osv_scanner
install_osv_scanner() {
  local _T0_OSV
  _T0_OSV=$(date +%s)
  local _BIN_OSV
  _BIN_OSV="${VENV}/bin/osv-scanner${_EXE}"
  if [ -x "${_BIN_OSV}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Security Tool" "OSV-Scanner" "✅ Exists" "$(get_version "$_BIN_OSV")" "0"
    return 0
  fi

  log_info "── Installing osv-scanner ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "OSV-Scanner" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _O_OS="${_OS_TAG}"
  local _O_ARCH="amd64"
  [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] && _O_ARCH="arm64"
  # osv-scanner asset naming: osv-scanner_{os}_{arch}[.exe] (no version in filename)
  local _FILE_OSV
  _FILE_OSV="osv-scanner_${_O_OS}_${_O_ARCH}${_EXE}"
  local _URL_OSV
  _URL_OSV="${GITHUB_PROXY}https://github.com/google/osv-scanner/releases/download/${OSV_SCANNER_VERSION}/${_FILE_OSV}"

  local _STAT_OSV="✅ Installed"
  if download_url "${_URL_OSV}" "${_BIN_OSV}" "osv-scanner"; then
    chmod +x "${_BIN_OSV}" 2>/dev/null || true
  else
    _STAT_OSV="❌ Failed"
  fi
  local _DUR_OSV
  _DUR_OSV=$(($(date +%s) - _T0_OSV))
  log_summary "Security Tool" "OSV-Scanner" "$_STAT_OSV" "$(get_version "$_BIN_OSV")" "$_DUR_OSV"
}

# Purpose: Installs Trivy for security scanning.
# Params:
#   None (uses global TRIVY_VERSION)
# Examples:
#   install_trivy
install_trivy() {
  local _T0_TRIVY
  _T0_TRIVY=$(date +%s)
  local _BIN_TRIVY
  _BIN_TRIVY="${VENV}/bin/trivy${_EXE}"
  if [ -x "${_BIN_TRIVY}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Security Tool" "Trivy" "✅ Exists" "$(get_version "$_BIN_TRIVY")" "0"
    return 0
  fi

  log_info "── Installing trivy ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "Trivy" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _T_OS_TRIVY="Linux"
  [ "${OS}" = "darwin" ] && _T_OS_TRIVY="macOS"
  # trivy arch naming: ARM64 for arm64, 64bit for amd64
  local _T_ARCH_TRIVY="64bit"
  { [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ]; } && _T_ARCH_TRIVY="ARM64"

  local _TAR_TRIVY
  if [ "${_OS_TAG}" = "windows" ]; then
    _TAR_TRIVY="trivy_${TRIVY_VERSION#v}_windows-64bit.zip"
  else
    _TAR_TRIVY="trivy_${TRIVY_VERSION#v}_${_T_OS_TRIVY}-${_T_ARCH_TRIVY}.tar.gz"
  fi

  local _URL_TRIVY
  _URL_TRIVY="${GITHUB_PROXY}https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/${_TAR_TRIVY}"
  local _TMP_TRIVY
  _TMP_TRIVY=$(mktemp -d)
  local _STAT_TRIVY="✅ Installed"

  if download_url "${_URL_TRIVY}" "${_TMP_TRIVY}/trivy_pkg" "trivy"; then
    if [ "${_OS_TAG}" = "windows" ]; then
      unzip -q "${_TMP_TRIVY}/trivy_pkg" -d "${_TMP_TRIVY}" || _STAT_TRIVY="❌ Failed"
      mv "${_TMP_TRIVY}/trivy.exe" "${_BIN_TRIVY}" 2>/dev/null || _STAT_TRIVY="❌ Failed"
    else
      tar -xzf "${_TMP_TRIVY}/trivy_pkg" -C "${_TMP_TRIVY}" trivy || _STAT_TRIVY="❌ Failed"
      mv "${_TMP_TRIVY}/trivy" "${_BIN_TRIVY}" 2>/dev/null || _STAT_TRIVY="❌ Failed"
    fi
    chmod +x "${_BIN_TRIVY}" 2>/dev/null || true
  else
    _STAT_TRIVY="❌ Failed"
  fi
  rm -rf "${_TMP_TRIVY}"
  local _DUR_TRIVY
  _DUR_TRIVY=$(($(date +%s) - _T0_TRIVY))
  log_summary "Security Tool" "Trivy" "$_STAT_TRIVY" "$(get_version "$_BIN_TRIVY")" "$_DUR_TRIVY"
}

# Purpose: Installs editorconfig-checker for compliance validation.
# Params:
#   None (uses global EDITORCONFIG_CHECKER_VERSION)
# Examples:
#   install_editorconfig_checker
install_editorconfig_checker() {
  local _T0_EC
  _T0_EC=$(date +%s)
  local _BIN_EC
  _BIN_EC="${VENV}/bin/editorconfig-checker${_EXE}"
  if [ -x "${_BIN_EC}" ] && [ "${DRY_RUN:-0}" -eq 0 ]; then
    log_summary "Lint Tool" "EditorConfig" "✅ Exists" "$(get_version "$_BIN_EC")" "0"
    return 0
  fi

  log_info "── Installing editorconfig-checker ──"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "EditorConfig" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _TMP_EC
  _TMP_EC=$(mktemp -d)
  local _STAT_EC="✅ Installed"

  local _O_OS="${OS}" # Uses OS detection from previous steps
  [ "${OS}" = "darwin" ] && _O_OS="darwin"
  [ "${OS}" = "linux" ] && _O_OS="linux"

  local _O_ARCH="amd64"
  { [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ]; } && _O_ARCH="arm64"

  # Asset naming:
  # Darwin/Windows: ec-{os}-{arch}.tar.gz
  # Linux: editorconfig-checker-{os}-{arch}.tar.gz
  local _FILE_EC
  if [ "${OS}" = "linux" ]; then
    _FILE_EC="editorconfig-checker-${_O_OS}-${_O_ARCH}.tar.gz"
  else
    _FILE_EC="ec-${_O_OS}-${_O_ARCH}.tar.gz"
  fi

  local _URL_EC="${GITHUB_PROXY}https://github.com/editorconfig-checker/editorconfig-checker/releases/download/${EDITORCONFIG_CHECKER_VERSION}/${_FILE_EC}"

  if download_url "${_URL_EC}" "${_TMP_EC}/ec_pkg" "editorconfig-checker"; then
    tar -xzf "${_TMP_EC}/ec_pkg" -C "${_TMP_EC}" || _STAT_EC="❌ Failed"
    if [ "$_STAT_EC" = "✅ Installed" ]; then
      # Internal structure differs:
      # Darwin: bin/ec
      # Linux: bin/editorconfig-checker
      local _SRC_EC_BIN=""
      if [ -x "${_TMP_EC}/bin/editorconfig-checker${_EXE}" ]; then
        _SRC_EC_BIN="${_TMP_EC}/bin/editorconfig-checker${_EXE}"
      elif [ -x "${_TMP_EC}/bin/ec${_EXE}" ]; then
        _SRC_EC_BIN="${_TMP_EC}/bin/ec${_EXE}"
      fi

      if [ -n "$_SRC_EC_BIN" ]; then
        mv "$_SRC_EC_BIN" "${_BIN_EC}" || _STAT_EC="❌ Failed"
        chmod +x "${_BIN_EC}" 2>/dev/null || true
      else
        _STAT_EC="❌ Failed"
      fi
    fi
  else
    _STAT_EC="❌ Failed"
  fi

  rm -rf "${_TMP_EC}"
  local _DUR_EC
  _DUR_EC=$(($(date +%s) - _T0_EC))
  log_summary "Lint Tool" "EditorConfig" "$_STAT_EC" "$(get_version "$_BIN_EC")" "$_DUR_EC"
}

# Purpose: Sets up several security audit tools (OSV-Scanner, Trivy, Govulncheck, etc.).
# Params:
#   None
# Examples:
#   setup_security
setup_security() {
  log_info "── Setting up Security Audit Tools ──"
  install_osv_scanner
  install_trivy

  # Install govulncheck if go exists
  if command -v go >/dev/null 2>&1; then
    local _T0_VULN
    _T0_VULN=$(date +%s)
    if command -v govulncheck >/dev/null 2>&1; then
      log_summary "Security Tool" "Govulncheck" "✅ Exists" "$(get_version govulncheck)" "0"
    else
      log_info "Installing govulncheck..."
      if run_quiet go install golang.org/x/vuln/cmd/govulncheck@latest; then
        log_summary "Security Tool" "Govulncheck" "✅ Installed" "$(get_version govulncheck)" "$(($(date +%s) - _T0_VULN))"
      else
        log_summary "Security Tool" "Govulncheck" "❌ Failed" "-" "0"
      fi
    fi
  fi

  # Install cargo-audit if cargo exists
  if command -v cargo >/dev/null 2>&1; then
    local _T0_CRGO
    _T0_CRGO=$(date +%s)
    if command -v cargo-audit >/dev/null 2>&1; then
      log_summary "Security Tool" "Cargo-Audit" "✅ Exists" "$(get_version cargo-audit)" "0"
    else
      log_info "Installing cargo-audit..."
      if run_quiet cargo install cargo-audit; then
        log_summary "Security Tool" "Cargo-Audit" "✅ Installed" "$(get_version cargo-audit)" "$(($(date +%s) - _T0_CRGO))"
      else
        log_summary "Security Tool" "Cargo-Audit" "❌ Failed" "-" "0"
      fi
    fi
  fi
}

# Purpose: Main entry point for the setup engine.
#          Coordinates module selection and execution.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --verbose node security
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  # Re-extract raw args to avoid flags
  local _RAW_ARGS=""
  local _arg
  for _arg in "$@"; do
    case "$_arg" in
    -q | --quiet | -v | --verbose | --dry-run | -h | --help) ;;
    *) _RAW_ARGS="${_RAW_ARGS} ${_arg}" ;;
    esac
  done

  # ── Execution Timing & Summary Management ──
  local _START_TIME_MAIN
  _START_TIME_MAIN=$(date +%s)

  if [ -z "$SETUP_SUMMARY_FILE" ]; then
    SETUP_SUMMARY_FILE=$(mktemp)
    export SETUP_SUMMARY_FILE
    local _CREATED_SUMMARY_MAIN=true

    # Initialize Summary (Only once per CI Job or first call)
    if [ "$_SETUP_SUMMARY_INITIALIZED" != "true" ] && ! check_ci_summary "### Setup Execution Summary"; then
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
        log_summary "Environment" "System" "✅ Active" "$(uname -s)/$(uname -m)" "0"
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

    # Provide table header if not already present in the summary
    if [ "$_SUMMARY_TABLE_HEADER_SENTINEL" != "true" ] && ! check_ci_summary "| Category | Module | Status |"; then
      {
        printf "| Category | Module | Status | Version | Time |\n"
        printf "| :--- | :--- | :--- | :--- | :--- |\n"
      } >>"$SETUP_SUMMARY_FILE"
      [ -n "$GITHUB_ENV" ] && echo "_SUMMARY_TABLE_HEADER_SENTINEL=true" >>"$GITHUB_ENV"
      export _SUMMARY_TABLE_HEADER_SENTINEL=true
    fi
  fi

  # ── Module Selection ──
  local _MODULES_LIST
  if [ -z "$(echo "${_RAW_ARGS}" | tr -d ' ')" ] || [ "${_RAW_ARGS# *}" = "all" ]; then
    _MODULES_LIST="node python gitleaks hadolint go checkmake iac powershell java ruby php dart swift dotnet security editorconfig-checker hooks"
  else
    _MODULES_LIST="${_RAW_ARGS}"
  fi

  local _cur_module
  for _cur_module in $_MODULES_LIST; do
    case $_cur_module in
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
    editorconfig-checker) install_editorconfig_checker ;;
    hooks) setup_hooks ;;
    *) log_error "Unknown module: $_cur_module" ;;
    esac
  done

  # ── Final Output Management ──
  if [ "$_CREATED_SUMMARY_MAIN" = "true" ]; then
    local _TOTAL_DUR_MAIN
    _TOTAL_DUR_MAIN=$(($(date +%s) - _START_TIME_MAIN))
    printf "\n**Total Duration: %ss**\n" "$_TOTAL_DUR_MAIN" >>"$SETUP_SUMMARY_FILE"

    printf "\n"
    cat "$SETUP_SUMMARY_FILE"
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
      cat "$SETUP_SUMMARY_FILE" >>"$GITHUB_STEP_SUMMARY"
    fi
    rm -f "$SETUP_SUMMARY_FILE"
  fi

  if [ "$_IS_TOP_LEVEL" = "true" ]; then
    log_info "\n✨ Setup step complete!"

    # Next Actions
    if [ "${DRY_RUN:-0}" -eq 0 ]; then
      printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
      printf "  - Run %bmake install%b to install project dependencies.\n" "${GREEN}" "${NC}"
      printf "  - Run %bmake verify%b to ensure environment health.\n" "${GREEN}" "${NC}"
    fi
  fi
}

main "$@"
