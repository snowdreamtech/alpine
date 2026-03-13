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
#   - Modularized toolchain installation.
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
  tflint             Install TFLint
  kube-linter        Install Kube-Linter
  powershell         Setup PSScriptAnalyzer
  java               Install google-java-format
  ruby               Setup Rubocop
  dart               Check Dart SDK
  swift              Install Swift linters (macOS)
  dotnet             Check .NET SDK
  security           Install security audit tools (osv-scanner, trivy, etc.)
  editorconfig-checker Install editorconfig-checker
  shfmt              Install shfmt
  shellcheck         Install shellcheck
  actionlint         Install actionlint
  taplo              Install taplo
  prettier           Install prettier
  sort-package-json  Install sort-package-json
  goreleaser         Install goreleaser
  spectral           Install spectral
  commitlint         Install commitlint
  dockerfile-utils   Install dockerfile-utils
  clang-format       Install clang-format
  ktlint             Install ktlint
  ruff               Install ruff
  yamllint           Install yamllint
  sqlfluff           Install sqlfluff
  markdownlint       Install markdownlint
  ansible-lint       Install ansible-lint
  dotenv-linter      Install dotenv-linter
  bats               Install bats
  bats-libs          Vendor bats libraries
  eslint             Install eslint
  stylelint          Install stylelint
  vitepress          Install vitepress
  commitizen         Install commitizen
  pip-audit          Install pip-audit
  pre-commit         Install pre-commit
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

  # 1. Smart Installation via mise (SSoT: .mise.toml)
  run_mise install node pnpm yarn bun

  # 2. Activate environment for subsequent steps
  eval "$(mise activate bash --shims)"

  # 3. Project dependencies
  if [ -f package.json ]; then
    local _STAT_NODE="✅ Installed"
    # shellcheck disable=SC2154
    run_quiet "$NPM" install || _STAT_NODE="❌ Failed"

    local _DUR_NODE
    _DUR_NODE=$(($(date +%s) - _T0_NODE))
    log_summary "Runtime" "Node.js" "$_STAT_NODE" "$(get_version node)" "$_DUR_NODE"

    if [ "$_STAT_NODE" = "✅ Installed" ]; then
      # Detect Frameworks from package.json for summary
      if grep -q '"vitepress"' package.json; then log_summary "Framework" "VitePress" "✅ Detected" "$(get_version node "exec vitepress --version")" "0"; fi
      if grep -q '"vue"' package.json; then log_summary "Framework" "Vue" "✅ Detected" "-" "0"; fi
      if grep -q '"react"' package.json; then log_summary "Framework" "React" "✅ Detected" "-" "0"; fi
      if grep -q '"tailwindcss"' package.json; then log_summary "Framework" "Tailwind" "✅ Detected" "-" "0"; fi
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

  # 1. Smart Installation via mise (SSoT: .mise.toml)
  run_mise install python uv
  eval "$(mise activate bash --shims)"

  # 2. Venv check
  local _STAT_PY="✅ Installed"
  if [ ! -d "$VENV" ]; then
    log_info "Creating virtual environment using uv..."
    # shellcheck disable=SC2154
    run_quiet uv venv "$VENV" || _STAT_PY="❌ Failed"
  fi

  # 3. Dependencies
  if [ "$_STAT_PY" = "✅ Installed" ] && [ -d "$VENV" ]; then
    if [ -f requirements-dev.txt ]; then
      run_quiet "$VENV/bin/pip" install -r requirements-dev.txt || _STAT_PY="⚠️ Warning"
    fi
  fi

  local _DUR_PY=$(($(date +%s) - _T0_PY))
  log_summary "Runtime" "Python" "$_STAT_PY" "$(get_version "$VENV/bin/python")" "$_DUR_PY"
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

# Purpose: Installs TFLint.
install_tflint() {
  local _T0_TF
  _T0_TF=$(date +%s)
  log_info "── Setting up TFLint ──"
  if ! has_lang_files "" "*.tf"; then
    log_summary "Lint Tool" "TFLint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_TF="✅ mise"
  run_mise install tflint || _STAT_TF="❌ Failed"
  log_summary "Lint Tool" "TFLint" "$_STAT_TF" "$(get_version tflint)" "$(($(date +%s) - _T0_TF))"
}

# Purpose: Installs Kube-Linter.
install_kube_linter() {
  local _T0_KL
  _T0_KL=$(date +%s)
  log_info "── Setting up Kube-Linter ──"
  if ! has_lang_files "" "*.yaml *.yml"; then
    log_summary "Lint Tool" "Kube-Linter" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_KL="✅ mise"
  run_mise install kube-linter || _STAT_KL="❌ Failed"
  log_summary "Lint Tool" "Kube-Linter" "$_STAT_KL" "$(get_version kube-linter)" "$(($(date +%s) - _T0_KL))"
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
# Delegate: Managed by mise (.mise.toml)
install_java_lint() {
  local _T0_JAVA
  _T0_JAVA=$(date +%s)
  log_info "── Setting up Java Linter (google-java-format) ──"

  if ! has_lang_files "pom.xml build.gradle" "*.java"; then
    log_summary "Lint Tool" "Java Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Java Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_JAVA="✅ mise"
  run_mise install "github:google/google-java-format" || _STAT_JAVA="❌ Failed"

  local _DUR_JAVA=$(($(date +%s) - _T0_JAVA))
  log_summary "Lint Tool" "Java Lint" "$_STAT_JAVA" "$(get_version google-java-format)" "$_DUR_JAVA"
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
  log_summary "Security Tool" "OSV-Scanner" "$_STAT_OSV" "$(get_version osv-scanner)" "$(($(date +%s) - _T0_OSV))"
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
  log_summary "Security Tool" "Trivy" "$_STAT_TRIVY" "$(get_version trivy)" "$(($(date +%s) - _T0_TRIVY))"
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
  if ! has_lang_files "" ".github/workflows/*.yml .github/workflows/*.yaml"; then
    log_summary "Security Tool" "Zizmor" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_ZIZ="✅ mise"
  run_mise install zizmor || _STAT_ZIZ="❌ Failed"
  log_summary "Security Tool" "Zizmor" "$_STAT_ZIZ" "$(get_version zizmor)" "$(($(date +%s) - _T0_ZIZ))"
}

# Purpose: Installs cargo-audit for Rust projects.
# Delegate: Managed by mise (.mise.toml)
install_cargo_audit() {
  local _T0_CRGO
  _T0_CRGO=$(date +%s)
  log_info "── Setting up Cargo-Audit ──"

  if ! has_lang_files "Cargo.toml Cargo.lock" "*.rs"; then
    log_summary "Security Tool" "Cargo-Audit" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Explicit manager check (SSoT: cargo: prefix requires cargo)
  ensure_manager cargo

  local _STAT_CRGO="✅ mise"
  run_mise install "cargo:cargo-audit" || _STAT_CRGO="❌ Failed"
  log_summary "Security Tool" "Cargo-Audit" "$_STAT_CRGO" "$(get_version cargo-audit)" "$(($(date +%s) - _T0_CRGO))"
}

# Purpose: Installs govulncheck for Go projects.
# Delegate: Managed by mise (.mise.toml)
install_govulncheck() {
  local _T0_VULN
  _T0_VULN=$(date +%s)
  log_info "── Setting up Govulncheck ──"

  if ! has_lang_files "go.mod go.sum" "*.go"; then
    log_summary "Security Tool" "Govulncheck" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Explicit manager check (SSoT: go: prefix requires go)
  ensure_manager go

  local _STAT_VULN="✅ mise"
  run_mise install "go:golang.org/x/vuln/cmd/govulncheck" || _STAT_VULN="❌ Failed"
  log_summary "Security Tool" "Govulncheck" "$_STAT_VULN" "$(get_version govulncheck)" "$(($(date +%s) - _T0_VULN))"
}

# Purpose: Installs shfmt for shell script formatting.
# Delegate: Managed by mise (.mise.toml)
install_shfmt() {
  local _T0_SHF
  _T0_SHF=$(date +%s)
  log_info "── Setting up Shfmt ──"
  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    log_summary "Lint Tool" "Shfmt" "⏭️ Skipped" "-" "0"
    return 0
  fi
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
  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    log_summary "Lint Tool" "Shellcheck" "⏭️ Skipped" "-" "0"
    return 0
  fi
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
  if ! has_lang_files "" ".github/workflows/*.yml .github/workflows/*.yaml"; then
    log_summary "Lint Tool" "Actionlint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_ACT="✅ mise"
  run_mise install "github:rhysd/actionlint" || _STAT_ACT="❌ Failed"
  log_summary "Lint Tool" "Actionlint" "$_STAT_ACT" "$(get_version actionlint)" "$(($(date +%s) - _T0_ACT))"
}

# Purpose: Installs taplo for TOML formatting.
install_taplo() {
  local _T0_TAP
  _T0_TAP=$(date +%s)
  log_info "── Setting up Taplo ──"
  if ! has_lang_files "" "*.toml"; then
    log_summary "Lint Tool" "Taplo" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_TAP="✅ mise"
  run_mise install taplo || _STAT_TAP="❌ Failed"
  log_summary "Lint Tool" "Taplo" "$_STAT_TAP" "$(get_version taplo)" "$(($(date +%s) - _T0_TAP))"
}

# Purpose: Installs prettier for web formatting.
install_prettier() {
  local _T0_PRE
  _T0_PRE=$(date +%s)
  log_info "── Setting up Prettier ──"
  if ! has_lang_files "" "*.json *.yaml *.yml *.vue *.js *.ts *.jsx *.tsx"; then
    log_summary "Lint Tool" "Prettier" "⏭️ Skipped" "-" "0"
    return 0
  fi
  ensure_manager npm
  local _STAT_PRE="✅ mise"
  run_mise install "npm:prettier" || _STAT_PRE="❌ Failed"
  log_summary "Lint Tool" "Prettier" "$_STAT_PRE" "$(get_version prettier)" "$(($(date +%s) - _T0_PRE))"
}

# Purpose: Installs sort-package-json.
install_sort_package_json() {
  local _T0_SPJ
  _T0_SPJ=$(date +%s)
  log_info "── Setting up sort-package-json ──"
  if [ ! -f "package.json" ]; then
    log_summary "Other" "sort-package-json" "⏭️ Skipped" "-" "0"
    return 0
  fi
  ensure_manager npm
  local _STAT_SPJ="✅ mise"
  run_mise install "npm:sort-package-json" || _STAT_SPJ="❌ Failed"
  log_summary "Other" "sort-package-json" "$_STAT_SPJ" "$(get_version sort-package-json)" "$(($(date +%s) - _T0_SPJ))"
}

# Purpose: Installs goreleaser.
install_goreleaser() {
  local _T0_GR
  _T0_GR=$(date +%s)
  log_info "── Setting up GoReleaser ──"
  if ! has_lang_files ".goreleaser.yaml .goreleaser.yml" ""; then
    log_summary "Other" "GoReleaser" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_GR="✅ mise"
  run_mise install "github:goreleaser/goreleaser" || _STAT_GR="❌ Failed"
  log_summary "Other" "GoReleaser" "$_STAT_GR" "$(get_version goreleaser)" "$(($(date +%s) - _T0_GR))"
}

# Purpose: Installs spectral for API linting.
install_spectral() {
  local _T0_SPEC
  _T0_SPEC=$(date +%s)
  log_info "── Setting up Spectral ──"
  if ! has_lang_files "" "*openapi* *swagger* *asyncapi*"; then
    log_summary "Lint Tool" "Spectral" "⏭️ Skipped" "-" "0"
    return 0
  fi

  ensure_manager npm

  local _STAT_SPEC="✅ mise"
  run_mise install "npm:@stoplight/spectral-cli" || _STAT_SPEC="❌ Failed"
  log_summary "Lint Tool" "Spectral" "$_STAT_SPEC" "$(get_version spectral --version)" "$(($(date +%s) - _T0_SPEC))"
}

# Purpose: Installs commitlint.
install_commitlint() {
  local _T0_CL
  _T0_CL=$(date +%s)
  log_info "── Setting up Commitlint ──"

  ensure_manager npm

  local _STAT_CL="✅ mise"
  run_mise install "npm:@commitlint/cli" || _STAT_CL="❌ Failed"
  log_summary "Other" "Commitlint" "$_STAT_CL" "$(get_version commitlint --version)" "$(($(date +%s) - _T0_CL))"
}

# Purpose: Installs dockerfile-utils.
install_dockerfile_utils() {
  local _T0_DU
  _T0_DU=$(date +%s)
  log_info "── Setting up dockerfile-utils ──"
  if ! has_lang_files "Dockerfile" "*.dockerfile *.Dockerfile"; then
    log_summary "Lint Tool" "dockerfile-utils" "⏭️ Skipped" "-" "0"
    return 0
  fi

  ensure_manager npm

  local _STAT_DU="✅ mise"
  run_mise install "npm:dockerfile-utils" || _STAT_DU="❌ Failed"
  log_summary "Lint Tool" "dockerfile-utils" "$_STAT_DU" "$(get_version dockerfile-utils)" "$(($(date +%s) - _T0_DU))"
}

# Purpose: Installs clang-format.
install_clang_format() {
  local _T0_CF
  _T0_CF=$(date +%s)
  log_info "── Setting up clang-format ──"
  if ! has_lang_files "" "*.c *.cpp *.h *.hpp *.cc *.m *.mm"; then
    log_summary "Lint Tool" "clang-format" "⏭️ Skipped" "-" "0"
    return 0
  fi

  ensure_manager npm

  local _STAT_CF="✅ mise"
  run_mise install "npm:clang-format" || _STAT_CF="❌ Failed"
  log_summary "Lint Tool" "clang-format" "$_STAT_CF" "$(get_version clang-format)" "$(($(date +%s) - _T0_CF))"
}

# Purpose: Installs ktlint.
install_ktlint() {
  local _T0_KT
  _T0_KT=$(date +%s)
  log_info "── Setting up ktlint ──"
  if ! has_lang_files "" "*.kt *.kts"; then
    log_summary "Lint Tool" "ktlint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_KT="✅ mise"
  run_mise install "github:pinterest/ktlint" || _STAT_KT="❌ Failed"
  log_summary "Lint Tool" "ktlint" "$_STAT_KT" "$(get_version ktlint --version)" "$(($(date +%s) - _T0_KT))"
}

# Purpose: Installs ruff.
install_ruff() {
  local _T0_RUF
  _T0_RUF=$(date +%s)
  log_info "── Setting up Ruff ──"
  if ! has_lang_files "requirements.txt pyproject.toml" "*.py"; then
    log_summary "Lint Tool" "Ruff" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_RUF="✅ mise"
  run_mise install ruff || _STAT_RUF="❌ Failed"
  log_summary "Lint Tool" "Ruff" "$_STAT_RUF" "$(get_version ruff)" "$(($(date +%s) - _T0_RUF))"
}

# Purpose: Installs yamllint.
install_yamllint() {
  local _T0_YL
  _T0_YL=$(date +%s)
  log_info "── Setting up Yamllint ──"
  if ! has_lang_files ".yamllint .yamllint.yml" "*.yaml *.yml"; then
    log_summary "Lint Tool" "Yamllint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_YL="✅ mise"
  run_mise install yamllint || _STAT_YL="❌ Failed"
  log_summary "Lint Tool" "Yamllint" "$_STAT_YL" "$(get_version yamllint)" "$(($(date +%s) - _T0_YL))"
}

# Purpose: Installs sqlfluff.
install_sqlfluff() {
  local _T0_SQL
  _T0_SQL=$(date +%s)
  log_info "── Setting up Sqlfluff ──"
  if ! has_lang_files ".sqlfluff" "*.sql"; then
    log_summary "Lint Tool" "Sqlfluff" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_SQL="✅ mise"
  run_mise install sqlfluff || _STAT_SQL="❌ Failed"
  log_summary "Lint Tool" "Sqlfluff" "$_STAT_SQL" "$(get_version sqlfluff)" "$(($(date +%s) - _T0_SQL))"
}

# Purpose: Installs markdownlint-cli2.
install_markdownlint() {
  local _T0_MD
  _T0_MD=$(date +%s)
  log_info "── Setting up Markdownlint ──"
  if ! has_lang_files "" "*.md"; then
    log_summary "Lint Tool" "Markdownlint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  ensure_manager npm

  local _STAT_MD="✅ mise"
  run_mise install "npm:markdownlint-cli2" || _STAT_MD="❌ Failed"
  log_summary "Lint Tool" "Markdownlint" "$_STAT_MD" "$(get_version markdownlint-cli2)" "$(($(date +%s) - _T0_MD))"
}

# Purpose: Installs dotenv-linter.
install_dotenv_linter() {
  local _T0_DOT
  _T0_DOT=$(date +%s)
  log_info "── Setting up dotenv-linter ──"
  if ! has_lang_files ".env .env.example" "*.env"; then
    log_summary "Lint Tool" "dotenv-linter" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_DOT="✅ mise"
  run_mise install "github:dotenv-linter/dotenv-linter" || _STAT_DOT="❌ Failed"
  log_summary "Lint Tool" "dotenv-linter" "$_STAT_DOT" "$(get_version dotenv-linter)" "$(($(date +%s) - _T0_DOT))"
}

# Purpose: Installs ansible-lint.
install_ansible_lint() {
  local _T0_ANS
  _T0_ANS=$(date +%s)
  log_info "── Setting up Ansible-lint ──"
  if ! has_lang_files "" "ansible.cfg playbook.yml roles/ tasks/"; then
    log_summary "Lint Tool" "Ansible-lint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  # Ansible-lint is often installed via pip/python
  ensure_manager python3
  local _STAT_ANS="✅ mise"
  run_mise install ansible-lint || _STAT_ANS="❌ Failed"
  log_summary "Lint Tool" "Ansible-lint" "$_STAT_ANS" "$(get_version ansible-lint)" "$(($(date +%s) - _T0_ANS))"
}

# Purpose: Installs bats.
install_bats() {
  local _T0_BATS
  _T0_BATS=$(date +%s)
  log_info "── Setting up Bats ──"
  if ! has_lang_files "" "*.bats"; then
    log_summary "Test Tool" "Bats" "⏭️ Skipped" "-" "0"
    return 0
  fi
  local _STAT_BATS="✅ mise"
  run_mise install bats || _STAT_BATS="❌ Failed"
  log_summary "Test Tool" "Bats" "$_STAT_BATS" "$(get_version bats --version)" "$(($(date +%s) - _T0_BATS))"
}

# Purpose: Vendors bats-support and bats-assert for tests.
install_bats_libs() {
  local _T0_BL
  _T0_BL=$(date +%s)
  log_info "── Vendoring Bats Libraries ──"

  if ! has_lang_files "" "*.bats"; then
    log_summary "Test Tool" "Bats-Libs" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _VENDOR_DIR="vendor"
  mkdir -p "$_VENDOR_DIR"

  # SSoT: Download from GitHub via GITHUB_PROXY
  # bats-support
  if [ ! -d "$_VENDOR_DIR/bats-support" ]; then
    log_info "Downloading bats-support..."
    download_file "${GITHUB_PROXY}https://github.com/bats-core/bats-support/archive/refs/tags/v0.3.0.tar.gz" "$_VENDOR_DIR/bats-support.tar.gz"
    mkdir -p "$_VENDOR_DIR/bats-support"
    tar -xzf "$_VENDOR_DIR/bats-support.tar.gz" -C "$_VENDOR_DIR/bats-support" --strip-components=1
    rm "$_VENDOR_DIR/bats-support.tar.gz"
  fi

  # bats-assert
  if [ ! -d "$_VENDOR_DIR/bats-assert" ]; then
    log_info "Downloading bats-assert..."
    download_file "${GITHUB_PROXY}https://github.com/bats-core/bats-assert/archive/refs/tags/v2.1.0.tar.gz" "$_VENDOR_DIR/bats-assert.tar.gz"
    mkdir -p "$_VENDOR_DIR/bats-assert"
    tar -xzf "$_VENDOR_DIR/bats-assert.tar.gz" -C "$_VENDOR_DIR/bats-assert" --strip-components=1
    rm "$_VENDOR_DIR/bats-assert.tar.gz"
  fi

  log_summary "Test Tool" "Bats-Libs" "✅ Vendored" "v0.3.0/v2.1.0" "$(($(date +%s) - _T0_BL))"
}

# Purpose: Installs eslint.
install_eslint() {
  local _T0_ES
  _T0_ES=$(date +%s)
  log_info "── Setting up ESLint ──"
  if ! has_lang_files "package.json" "*.js *.ts *.vue *.jsx *.tsx"; then
    log_summary "Lint Tool" "ESLint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  ensure_manager npm
  local _STAT_ES="✅ mise"
  run_mise install "npm:eslint" || _STAT_ES="❌ Failed"
  log_summary "Lint Tool" "ESLint" "$_STAT_ES" "$(get_version eslint --version)" "$(($(date +%s) - _T0_ES))"
}

# Purpose: Installs stylelint.
install_stylelint() {
  local _T0_SL
  _T0_SL=$(date +%s)
  log_info "── Setting up Stylelint ──"
  if ! has_lang_files "" "*.css *.scss *.less *.vue"; then
    log_summary "Lint Tool" "Stylelint" "⏭️ Skipped" "-" "0"
    return 0
  fi
  ensure_manager npm
  local _STAT_SL="✅ mise"
  run_mise install "npm:stylelint" || _STAT_SL="❌ Failed"
  log_summary "Lint Tool" "Stylelint" "$_STAT_SL" "$(get_version stylelint --version)" "$(($(date +%s) - _T0_SL))"
}

# Purpose: Installs vitepress.
install_vitepress() {
  local _T0_VP
  _T0_VP=$(date +%s)
  log_info "── Setting up VitePress ──"
  if [ ! -d docs ]; then
    log_summary "Doc Tool" "VitePress" "⏭️ Skipped" "-" "0"
    return 0
  fi
  ensure_manager npm
  local _STAT_VP="✅ mise"
  run_mise install "npm:vitepress" || _STAT_VP="❌ Failed"
  log_summary "Doc Tool" "VitePress" "$_STAT_VP" "$(get_version vitepress --version)" "$(($(date +%s) - _T0_VP))"
}

# Purpose: Installs commitizen.
install_commitizen() {
  local _T0_CZ
  _T0_CZ=$(date +%s)
  log_info "── Setting up Commitizen ──"
  ensure_manager npm
  local _STAT_CZ="✅ mise"
  run_mise install "npm:commitizen" || _STAT_CZ="❌ Failed"
  log_summary "Other" "Commitizen" "$_STAT_CZ" "$(get_version git-cz --version)" "$(($(date +%s) - _T0_CZ))"
}

# Purpose: Installs pip-audit.
install_pip_audit() {
  local _T0_PA
  _T0_PA=$(date +%s)
  log_info "── Setting up pip-audit ──"
  if ! has_lang_files "requirements.txt pyproject.toml" "*.py"; then
    log_summary "Security Tool" "pip-audit" "⏭️ Skipped" "-" "0"
    return 0
  fi
  # Explicit manager check
  ensure_manager python3
  ensure_manager pipx
  local _STAT_PA="✅ mise"
  run_mise install "pipx:pip-audit" || _STAT_PA="❌ Failed"
  log_summary "Security Tool" "pip-audit" "$_STAT_PA" "$(get_version pip-audit --version)" "$(($(date +%s) - _T0_PA))"
}

# Purpose: Installs pre-commit.
install_pre_commit() {
  local _T0_PC
  _T0_PC=$(date +%s)
  log_info "── Setting up Pre-commit ──"
  local _STAT_PC="✅ mise"
  run_mise install pre-commit || _STAT_PC="❌ Failed"
  log_summary "Other" "Pre-commit" "$_STAT_PC" "$(get_version pre-commit --version)" "$(($(date +%s) - _T0_PC))"
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
  install_govulncheck
  install_cargo_audit
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

  # ── Mode & Module Selection ──
  local _IS_ALL_MODULES=false
  if echo " ${_RAW_ARGS} " | grep -q " all "; then
    _IS_ALL_MODULES=true
  fi

  local _MODULES_LIST
  if [ -z "$(echo "${_RAW_ARGS}" | tr -d ' ')" ] || [ "$_IS_ALL_MODULES" = "true" ]; then
    # Full list for "On-demand" (default) or "All" (explicit)
    _MODULES_LIST="node python gitleaks hadolint go checkmake tflint kube-linter powershell java ruby dart swift dotnet security editorconfig-checker shfmt shellcheck actionlint taplo prettier sort-package-json goreleaser spectral commitlint dockerfile-utils clang-format ktlint ruff yamllint sqlfluff markdownlint ansible-lint dotenv-linter bats bats-libs eslint stylelint vitepress commitizen pip-audit pre-commit hooks"
  else
    # Specific modules requested (e.g., ./setup.sh node)
    _MODULES_LIST="${_RAW_ARGS}"
  fi

  # 5. Bootstrap Toolchain Manager
  bootstrap_mise || log_warn "Warning: mise bootstrap failed. Falling back to local tool installation."

  # 6. Toolchain Manager Strategy
  if [ "${DRY_RUN:-0}" -eq 0 ]; then
    # ── Git Protocol Stabilization ──
    export GIT_PROTOCOL=version=2
    export MISE_GIT_ALWAYS_USE_GIX=0

    if [ "$_IS_ALL_MODULES" = "true" ]; then
      log_info "Performing full toolchain synchronization via mise..."
      run_mise install
    else
      log_info "Performing on-demand module installation..."
    fi
  fi

  # 7. Execution
  local _cur_module
  for _cur_module in $_MODULES_LIST; do
    case $_cur_module in
    node) setup_node ;;
    python) setup_python ;;
    gitleaks) install_gitleaks ;;
    checkmake) install_checkmake ;;
    hadolint) install_hadolint ;;
    go) install_go_lint ;;
    tflint) install_tflint ;;
    kube-linter) install_kube_linter ;;
    powershell) setup_powershell ;;
    java) install_java_lint ;;
    ruby) install_ruby_lint ;;
    dart) setup_dart ;;
    swift) setup_swift ;;
    dotnet) setup_dotnet ;;
    security) setup_security ;;
    editorconfig-checker) install_editorconfig_checker ;;
    shfmt) install_shfmt ;;
    shellcheck) install_shellcheck ;;
    actionlint) install_actionlint ;;
    taplo) install_taplo ;;
    prettier) install_prettier ;;
    sort-package-json) install_sort_package_json ;;
    goreleaser) install_goreleaser ;;
    spectral) install_spectral ;;
    commitlint) install_commitlint ;;
    dockerfile-utils) install_dockerfile_utils ;;
    clang-format) install_clang_format ;;
    ktlint) install_ktlint ;;
    ruff) install_ruff ;;
    yamllint) install_yamllint ;;
    sqlfluff) install_sqlfluff ;;
    markdownlint) install_markdownlint ;;
    ansible-lint) install_ansible_lint ;;
    dotenv-linter) install_dotenv_linter ;;
    bats) install_bats ;;
    bats-libs) install_bats_libs ;;
    eslint) install_eslint ;;
    stylelint) install_stylelint ;;
    vitepress) install_vitepress ;;
    commitizen) install_commitizen ;;
    pip-audit) install_pip_audit ;;
    pre-commit) install_pre_commit ;;
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
