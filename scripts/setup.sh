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
# Execution timing
_START_TIME=$(date +%s)

# Privacy-aware path sanitizer
sanitize_path() {
  echo "$1" | sed "s|$HOME|~|g"
}

log_summary() {
  _CAT="${1:-Other}"
  _MOD="${2:-Unknown}"
  _STAT="${3:-⏭️ Skipped}"
  _VER="${4:--}"
  _DUR="${5:--}"

  # Automatically demote to Warning if status is supposedly Active/Installed but version detection failed
  case "$_STAT" in
  ✅*)
    if [ "$_VER" = "-" ] || [ -z "$_VER" ]; then
      case "$_MOD" in
      System | Shell | React | Vue | Tailwind | VitePress | Vite) ;; # These don't always have a single version command
      *) _STAT="⚠️ Warning" ;;
      esac
    fi
    ;;
  esac

  printf "| %-12s | %-15s | %-20s | %-15s | %-6s |\n" "$_CAT" "$_MOD" "$_STAT" "$_VER" "${_DUR}s" >>"$SETUP_SUMMARY_FILE"
}

# Helper to get version safely
get_version() {
  _CMD="$1"
  _ARG="${2:---version}"
  if command -v "$_CMD" >/dev/null 2>&1; then
    # Improved version extraction: find the first sequence starting with a digit
    "$_CMD" "$_ARG" 2>&1 | head -n 1 | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15
  else
    echo "-"
  fi
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
    pnpm install
    _V=$(get_version node)
    _D=$(($(date +%s) - _T0))
    log_summary "Runtime" "Node.js" "✅ Installed" "$_V" "$_D"

    # Detect Frameworks from package.json
    if grep -q '"vitepress"' package.json; then
      log_summary "Framework" "VitePress" "✅ Detected" "$(get_version pnpm "exec vitepress --version")" "0"
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

  if [ ! -d "$VENV" ]; then
    "$PYTHON" -m venv "$VENV"
  fi
  "$VENV/bin/pip" install --upgrade pip >/dev/null 2>&1
  if [ -f requirements-dev.txt ]; then
    "$VENV/bin/pip" install -r requirements-dev.txt >/dev/null 2>&1
    _V=$(get_version "$VENV/bin/python")
    _D=$(($(date +%s) - _T0))
    log_summary "Runtime" "Python" "✅ Installed" "$_V" "$_D"
  else
    log_summary "Runtime" "Python" "⏭️ Skipped" "-" "0"
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
      unzip -q "${_TMP}/gitleaks.zip" -d "${_TMP}"
      mv "${_TMP}/gitleaks.exe" "${_BIN}"
    else
      _STAT="❌ Failed"
    fi
  else
    _TAR="gitleaks_${GITLEAKS_VERSION#v}_${_TAR_TAG}_${_ARCH_N}.tar.gz"
    _URL="${GITHUB_PROXY}https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/${_TAR}"
    if download_url "${_URL}" "${_TMP}/gitleaks.tar.gz" "gitleaks"; then
      tar -xzf "${_TMP}/gitleaks.tar.gz" -C "${_TMP}" gitleaks
      mv "${_TMP}/gitleaks" "${_BIN}"
    else
      _STAT="❌ Failed"
    fi
  fi
  chmod +x "${_BIN}" 2>/dev/null
  rm -rf "${_TMP}"
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "Gitleaks" "$_STAT" "$(get_version "$_BIN")" "$_D"
}

install_hadolint() {
  _T0=$(date +%s)
  _BIN="${VENV}/bin/hadolint${_EXE}"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "Hadolint" "✅ Exists" "$(get_version "$_BIN")" "0"
    return 0
  fi

  log_info "── Installing hadolint ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "Hadolint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _SUFFIX="Linux-x86_64"
  [ "${OS}" = "darwin" ] && _SUFFIX="Darwin-x86_64"
  [ "${_OS_TAG}" = "windows" ] && _SUFFIX="Windows-x86_64.exe"

  _URL="${GITHUB_PROXY}https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${_SUFFIX}"
  _STAT="✅ Installed"
  if download_url "${_URL}" "${_BIN}" "hadolint"; then
    chmod +x "${_BIN}"
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

  log_info "── Installing golangci-lint ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "Go Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _URL="${GITHUB_PROXY}https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"
  _TMP=$(mktemp -d)
  _STAT="✅ Installed"
  if download_url "${_URL}" "${_TMP}/install_go.sh" "golangci-lint-installer"; then
    export BINDIR="${VENV}/bin"
    sh "${_TMP}/install_go.sh" "${GOLANGCI_VERSION}" >/dev/null 2>&1
  else
    _STAT="❌ Failed"
  fi
  rm -rf "${_TMP}"
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "Go Lint" "$_STAT" "$(get_version "$_BIN")" "$_D"
}

install_checkmake() {
  _T0=$(date +%s)
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
    chmod +x "${_BIN}"
  else
    _STAT="❌ Failed"
  fi
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "Checkmake" "$_STAT" "$(get_version "$_BIN")" "$_D"
}

install_iac_lint() {
  _T0=$(date +%s)
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
      unzip -q "${_TMP}/tflint.zip" -d "${_TMP}"
      mv "${_TMP}/tflint${_EXE}" "${VENV}/bin/tflint${_EXE}"
      chmod +x "${VENV}/bin/tflint${_EXE}"
      log_summary "Lint Tool" "TFLint" "✅ Installed" "$(get_version "${VENV}/bin/tflint${_EXE}")" "$(($(date +%s) - _T0))"
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
      chmod +x "${VENV}/bin/kube-linter${_EXE}"
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
    "$VENV/bin/pre-commit" install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg >/dev/null 2>&1
    _V=$(get_version "$VENV/bin/pre-commit")
    _D=$(($(date +%s) - _T0))
    log_summary "Other" "Hooks" "✅ Activated" "$_V" "$_D"
  else
    log_summary "Other" "Hooks" "❌ Failed" "-" "0"
  fi
}

setup_powershell() {
  _T0=$(date +%s)
  log_info "── Setting up PowerShell Linter ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "PowerShell" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -Command "if (!(Get-Module -ListAvailable PSScriptAnalyzer)) { Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser }" >/dev/null 2>&1
    # shellcheck disable=SC2016
    _V=$(pwsh -NoProfile -Command '(Get-Module PSScriptAnalyzer -ListAvailable).Version | Select-Object -First 1 | ForEach-Object { $_.ToString() }' 2>/dev/null || echo "installed")
    _D=$(($(date +%s) - _T0))
    log_summary "Lint Tool" "PowerShell" "✅ Installed" "$_V" "$_D"
  else
    log_summary "Lint Tool" "PowerShell" "⏭️ Skipped" "-" "0"
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

  log_info "── Installing google-java-format ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "Java Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _URL="${GITHUB_PROXY}https://github.com/google/google-java-format/releases/download/v${JAVA_FORMAT_VERSION}/google-java-format-${JAVA_FORMAT_VERSION}-all-deps.jar"
  _STAT="✅ Installed"
  if download_url "${_URL}" "${_JAR}" "google-java-format"; then
    printf "#!/bin/sh\njava -jar \"%s\" \"\$@\"\n" "${_JAR}" >"${_BIN}"
    chmod +x "${_BIN}"
  else
    _STAT="❌ Failed"
  fi
  _D=$(($(date +%s) - _T0))
  log_summary "Lint Tool" "Java Lint" "$_STAT" "$JAVA_FORMAT_VERSION" "$_D"
}

install_ruby_lint() {
  _T0=$(date +%s)
  log_info "── Setting up Rubocop ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "Rubocop" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if command -v gem >/dev/null 2>&1; then
    gem install rubocop --user-install --no-document --quiet >/dev/null 2>&1 || true
    _V=$(get_version rubocop)
    _D=$(($(date +%s) - _T0))
    log_summary "Lint Tool" "Rubocop" "✅ Installed" "$_V" "$_D"
  else
    log_summary "Lint Tool" "Rubocop" "⏭️ Skipped" "-" "0"
  fi
}

install_php_lint() {
  _T0=$(date +%s)
  _BIN="${VENV}/bin/php-cs-fixer"
  if [ -x "${_BIN}" ] && [ "$DRY_RUN" -eq 0 ]; then
    log_summary "Lint Tool" "PHP Lint" "✅ Exists" "$PHP_CS_FIXER_VERSION" "0"
    return 0
  fi

  log_info "── Installing php-cs-fixer ──"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_summary "Lint Tool" "PHP Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _URL="${GITHUB_PROXY}https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/releases/download/${PHP_CS_FIXER_VERSION}/php-cs-fixer.phar"
  _STAT="✅ Installed"
  if download_url "${_URL}" "${_BIN}" "php-cs-fixer"; then
    chmod +x "${_BIN}"
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
  if [ "${OS}" = "darwin" ]; then
    log_info "── Setting up Swift Linters (macOS) ──"
    if [ "$DRY_RUN" -eq 1 ]; then
      log_summary "Lint Tool" "Swift" "⚖️ Previewed" "-" "0"
      return 0
    fi

    if command -v brew >/dev/null 2>&1; then
      brew list swiftformat >/dev/null 2>&1 || brew install swiftformat >/dev/null 2>&1
      brew list swiftlint >/dev/null 2>&1 || brew install swiftlint >/dev/null 2>&1
      _D=$(($(date +%s) - _T0))
      log_summary "Lint Tool" "Swift" "✅ Installed" "$(get_version swiftlint lint --version)" "$_D"
    else
      log_summary "Lint Tool" "Swift" "❌ Failed" "-" "0"
    fi
  else
    log_summary "Lint Tool" "Swift" "⏭️ Skipped" "-" "0"
  fi
}

setup_dotnet() {
  log_info "── Checking .NET SDK ──"
  if command -v dotnet >/dev/null 2>&1; then
    log_summary "Runtime" ".NET" "✅ Available" "$(get_version dotnet)" "0"
  else
    log_summary "Runtime" ".NET" "⏭️ Missing" "-" "0"
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

# ── Execution Timing & Summary Management ──
_START_TIME=$(date +%s)
_IS_TOP_LEVEL=false

# Helper to check if header should be printed
should_print_header() {
  if [ -n "$GITHUB_STEP_SUMMARY" ] && [ -f "$GITHUB_STEP_SUMMARY" ]; then
    if grep -q "### Setup Execution Summary" "$GITHUB_STEP_SUMMARY"; then
      return 1 # Already exists in CI summary
    fi
  fi
  return 0
}

if [ -z "$SETUP_SUMMARY_FILE" ]; then
  SETUP_SUMMARY_FILE=$(mktemp)
  export SETUP_SUMMARY_FILE
  _IS_TOP_LEVEL=true

  if should_print_header; then
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
    } >"$SETUP_SUMMARY_FILE"
  else
    # Ensure file exists even if header is skipped
    touch "$SETUP_SUMMARY_FILE"
  fi
  {
    printf "| Category | Module | Status | Version | Time |\n"
    printf "| :--- | :--- | :--- | :--- | :--- |\n"
  } >>"$SETUP_SUMMARY_FILE"
fi

# ── Module Selection ──
if [ -z "$(echo "${RAW_ARGS}" | tr -d ' ')" ] || [ "${RAW_ARGS# *}" = "all" ]; then
  modules="node python gitleaks hadolint go checkmake iac powershell java ruby php dart swift dotnet hooks"
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
  hooks) setup_hooks ;;
  *) error "Unknown module: $module" ;;
  esac
done

# ── Global Detections (Environment & Other Runtimes) ──
# Only run global detections at the top-level or if specifically not in a sub-setup
if [ "$_IS_TOP_LEVEL" = "true" ]; then
  _TOTAL_DUR=$(($(date +%s) - _START_TIME))
  log_summary "Environment" "System" "✅ Active" "${OS}/${ARCH}" "0"
  log_summary "Environment" "Shell" "✅ Active" "$(basename "$SHELL")" "0"

  # Detect Go/Rust even if not explicitly setup
  if command -v go >/dev/null 2>&1; then
    log_summary "Runtime" "Go" "✅ Detected" "$(get_version go)" "0"
  fi
  if command -v cargo >/dev/null 2>&1; then
    log_summary "Runtime" "Rust" "✅ Detected" "$(get_version cargo)" "0"
  fi

  printf "\n**Total Duration: %ss**\n" "$_TOTAL_DUR" >>"$SETUP_SUMMARY_FILE"

  # Final Output
  if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    cat "$SETUP_SUMMARY_FILE" >>"$GITHUB_STEP_SUMMARY"
  else
    printf "\n"
    cat "$SETUP_SUMMARY_FILE"
  fi
  rm -f "$SETUP_SUMMARY_FILE"
  info "\n✨ Setup step $modules complete!"
fi
