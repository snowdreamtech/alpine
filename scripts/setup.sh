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

  if command -v mise >/dev/null 2>&1; then
    log_debug "Using mise for Node.js..."
    run_mise install
    eval "$(mise activate bash --shims)"
  elif command -v corepack >/dev/null 2>&1; then
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

  if command -v mise >/dev/null 2>&1; then
    log_debug "Using mise for Python..."
    run_mise install python uv
    eval "$(mise activate bash --shims)"
  fi

  local _STAT_PY="✅ Installed"
  if [ ! -d "$VENV" ]; then
    if command -v uv >/dev/null 2>&1; then
      log_info "Creating virtual environment using uv..."
      uv venv "$VENV" || _STAT_PY="❌ Failed"
    else
      "$PYTHON" -m venv "$VENV" || _STAT_PY="❌ Failed"
    fi
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

# Purpose: Installs Gitleaks for secrets scanning.
# Delegate: Managed by mise (.mise.toml)
install_gitleaks() {
  local _T0_GITL
  _T0_GITL=$(date +%s)
  log_info "── Setting up Gitleaks ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Gitleaks" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_GITL="✅ mise"
  run_mise install gitleaks || _STAT_GITL="❌ Failed"

  local _DUR_GITL=$(($(date +%s) - _T0_GITL))
  log_summary "Lint Tool" "Gitleaks" "$_STAT_GITL" "$(get_version gitleaks)" "$_DUR_GITL"
}

# Purpose: Installs Hadolint for Dockerfile linting.
# Delegate: Managed by mise (.mise.toml)
install_hadolint() {
  local _T0_HADO
  _T0_HADO=$(date +%s)
  log_info "── Setting up Hadolint ──"

  if ! has_lang_files "Dockerfile docker-compose.yml" "*.dockerfile *.Dockerfile"; then
    log_summary "Lint Tool" "Hadolint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Hadolint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_HADO="✅ mise"
  run_mise install hadolint || _STAT_HADO="❌ Failed"

  local _DUR_HADO=$(($(date +%s) - _T0_HADO))
  log_summary "Lint Tool" "Hadolint" "$_STAT_HADO" "$(get_version hadolint)" "$_DUR_HADO"
}

# Purpose: Installs golangci-lint for Go projects.
# Delegate: Managed by mise (.mise.toml)
install_go_lint() {
  local _T0_GO
  _T0_GO=$(date +%s)
  log_info "── Setting up Go Lint ──"

  if ! has_lang_files "go.mod go.sum" "*.go"; then
    log_summary "Lint Tool" "Go Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Go Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_GO="✅ mise"
  run_mise install golangci-lint || _STAT_GO="❌ Failed"

  local _DUR_GO=$(($(date +%s) - _T0_GO))
  log_summary "Lint Tool" "Go Lint" "$_STAT_GO" "$(get_version golangci-lint)" "$_DUR_GO"
}

# Purpose: Installs checkmake for Makefile linting.
# Params:
#   None (uses global CHECKMAKE_VERSION)
# Examples:
# Purpose: Installs checkmake for Makefile linting.
# Delegate: Managed by mise (.mise.toml)
install_checkmake() {
  local _T0_CM
  _T0_CM=$(date +%s)
  log_info "── Setting up Checkmake ──"

  if ! has_lang_files "Makefile" "*.make"; then
    log_summary "Lint Tool" "Checkmake" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Checkmake" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_CM="✅ mise"
  run_mise install checkmake || _STAT_CM="❌ Failed"

  local _DUR_CM=$(($(date +%s) - _T0_CM))
  log_summary "Lint Tool" "Checkmake" "$_STAT_CM" "$(get_version checkmake)" "$_DUR_CM"
}

# Purpose: Installs IaC linting tools (TFLint and Kube-Linter).
# Params:
#   None (uses global TFLINT_VERSION and KUBE_LINTER_VERSION)
# Examples:
# Purpose: Installs IaC linting tools (TFLint and Kube-Linter).
# Delegate: Managed by mise (.mise.toml)
install_iac_lint() {
  local _T0_IAC
  _T0_IAC=$(date +%s)
  log_info "── Setting up IaC Linters ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "IaC Linters" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # TFLint
  if has_lang_files "" "*.tf"; then
    local _STAT_TF="✅ mise"
    run_mise install tflint || _STAT_TF="❌ Failed"
    log_summary "Lint Tool" "TFLint" "$_STAT_TF" "$(get_version tflint)" "0"
  else
    log_summary "Lint Tool" "TFLint" "⏭️ Skipped" "-" "0"
  fi

  # Kube-Linter
  if has_lang_files "" "*.yaml *.yml"; then
    local _STAT_KL="✅ mise"
    run_mise install kube-linter || _STAT_KL="❌ Failed"
    log_summary "Lint Tool" "Kube-Linter" "$_STAT_KL" "$(get_version kube-linter)" "0"
  else
    log_summary "Lint Tool" "Kube-Linter" "⏭️ Skipped" "-" "0"
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
# Delegate: Managed by mise (.mise.toml)
install_osv_scanner() {
  local _T0_OSV
  _T0_OSV=$(date +%s)
  log_info "── Setting up OSV-Scanner ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "OSV-Scanner" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_OSV="✅ mise"
  run_mise install "github:google/osv-scanner" || _STAT_OSV="❌ Failed"

  local _DUR_OSV=$(($(date +%s) - _T0_OSV))
  log_summary "Security Tool" "OSV-Scanner" "$_STAT_OSV" "$(get_version osv-scanner)" "$_DUR_OSV"
}

# Purpose: Installs Trivy for security scanning.
# Delegate: Managed by mise (.mise.toml)
install_trivy() {
  local _T0_TRIVY
  _T0_TRIVY=$(date +%s)
  log_info "── Setting up Trivy ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "Trivy" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_TRIVY="✅ mise"
  run_mise install "github:aquasecurity/trivy" || _STAT_TRIVY="❌ Failed"

  local _DUR_TRIVY=$(($(date +%s) - _T0_TRIVY))
  log_summary "Security Tool" "Trivy" "$_STAT_TRIVY" "$(get_version trivy)" "$_DUR_TRIVY"
}

# Purpose: Installs editorconfig-checker for compliance validation.
# Delegate: Managed by mise (.mise.toml)
install_editorconfig_checker() {
  local _T0_EC
  _T0_EC=$(date +%s)
  log_info "── Setting up EditorConfig Checker ──"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "EditorConfig" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_EC="✅ mise"
  run_mise install editorconfig-checker || _STAT_EC="❌ Failed"

  local _DUR_EC=$(($(date +%s) - _T0_EC))
  log_summary "Lint Tool" "EditorConfig" "$_STAT_EC" "$(get_version editorconfig-checker)" "$_DUR_EC"
}

# Purpose: Installs zizmor for GitHub Actions auditing.
# Delegate: Managed by mise (.mise.toml)
install_zizmor() {
  local _T0_ZIZ
  _T0_ZIZ=$(date +%s)
  log_info "── Setting up Zizmor ──"
  local _STAT_ZIZ="✅ mise"
  run_mise install zizmor || _STAT_ZIZ="❌ Failed"
  log_summary "Security Tool" "Zizmor" "$_STAT_ZIZ" "$(get_version zizmor)" "$(($(date +%s) - _T0_ZIZ))"
}

# Purpose: Installs shfmt for shell script formatting.
# Delegate: Managed by mise (.mise.toml)
install_shfmt() {
  local _T0_SHF
  _T0_SHF=$(date +%s)
  log_info "── Setting up Shfmt ──"
  local _STAT_SHF="✅ mise"
  run_mise install shfmt || _STAT_SHF="❌ Failed"
  log_summary "Lint Tool" "Shfmt" "$_STAT_SHF" "$(get_version shfmt)" "$(($(date +%s) - _T0_SHF))"
}

# Purpose: Installs shellcheck for shell script linting.
# Delegate: Managed by mise (.mise.toml)
install_shellcheck() {
  local _T0_SHC
  _T0_SHC=$(date +%s)
  log_info "── Setting up Shellcheck ──"
  local _STAT_SHC="✅ mise"
  run_mise install shellcheck || _STAT_SHC="❌ Failed"
  log_summary "Lint Tool" "Shellcheck" "$_STAT_SHC" "$(get_version shellcheck)" "$(($(date +%s) - _T0_SHC))"
}

# Purpose: Installs actionlint for GitHub Actions linting.
# Delegate: Managed by mise (.mise.toml)
install_actionlint() {
  local _T0_ACT
  _T0_ACT=$(date +%s)
  log_info "── Setting up Actionlint ──"
  local _STAT_ACT="✅ mise"
  run_mise install "github:rhysd/actionlint" || _STAT_ACT="❌ Failed"
  log_summary "Lint Tool" "Actionlint" "$_STAT_ACT" "$(get_version actionlint)" "$(($(date +%s) - _T0_ACT))"
}

# Purpose: Sets up several security audit tools (OSV-Scanner, Trivy, Zizmor, etc.).
# Params:
#   None
# Examples:
#   setup_security
setup_security() {
  log_info "── Setting up Security Audit Tools ──"
  install_osv_scanner
  install_trivy
  install_zizmor

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

  # 3. Network Optimization
  optimize_network

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
    _MODULES_LIST="node python gitleaks hadolint go checkmake iac powershell java ruby php dart swift dotnet security editorconfig-checker shfmt shellcheck actionlint hooks"
  else
    _MODULES_LIST="${_RAW_ARGS}"
  fi

  # 5. Bootstrap Toolchain Manager
  bootstrap_mise || log_warn "Warning: mise bootstrap failed. Falling back to local tool installation."

  # 6. Execution
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
    shfmt) install_shfmt ;;
    shellcheck) install_shellcheck ;;
    actionlint) install_actionlint ;;
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
