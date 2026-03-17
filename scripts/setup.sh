#!/usr/bin/env sh
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
  stylua             Install stylua
  buf                Install buf
  tofu               Install opentofu
  just               Install Just
  task               Install Task
  nix                Check Nix
  zig                Install Zig
  cue                Install CUE/Jsonnet
  rego               Install OPA/Rego
  server             Check Server Configs
  edge               Check Edge Configs
  flutter            Install Flutter SDK
  react-native       Invite React Native CLI
  expo               Install Expo CLI
  ionic              Install Ionic CLI
  express            Install Express Generator
  fastify            Install Fastify CLI
  hono               Check Hono Configuration
  flask              Check Flask Configuration
  gin                Check Gin Configuration
  fiber              Check Fiber Configuration
  rails              Install Rails Gem
  typeorm            Install TypeORM CLI
  drizzle            Install Drizzle Kit
  rn                 Check React Native Config
  pulumi             Install Pulumi CLI
  crossplane         Check Crossplane Manifests
  playwright         Check Playwright Config
  cypress            Check Cypress Config
  vitest             Check Vitest Config
  docusaurus         Check Docusaurus Config
  mkdocs             Check MkDocs Config
  sphinx             Check Sphinx Config
  jupyter            Check Jupyter Notebooks
  dvc                Check DVC Config
  elixir             Install Elixir/Erlang
  haskell            Install Haskell/Stack
  scala              Install Scala/SBT
  php                Install PHP Runtime
  rust               Install Rust Runtime
  ruby               Setup Ruby & Rubocop
  java               Setup Java & Google-Java-Format
  dotnet             Setup .NET SDK
  deno               Setup Deno
  bun                Setup Bun
  kotlin             Setup Kotlin & Ktlint
  dart               Setup Dart
  zig                Setup Zig
  julia              Setup Julia
  r                  Setup R
  perl               Setup Perl
  lua                Setup Lua
  groovy             Setup Groovy
  swift              Setup Swift & SwiftLint
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

# Purpose: Internal helper to display a consistent setup header with version info.
# Params:
#   $1 - Human-readable description
#   $2 - Mise tool name (optional, for version lookup)
_log_setup() {
  local _TITLE="$1"
  local _LOOKUP="$2"
  local _VER=""
  [ -n "$_LOOKUP" ] && _VER=$(get_mise_tool_version "$_LOOKUP")

  if [ -n "$_VER" ]; then
    log_info "── Setting up $_TITLE ($_VER) ──"
  else
    log_info "── Setting up $_TITLE ──"
  fi
}

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

# language-specific modules are loaded dynamically via ${_G_LIB_DIR}/langs/*.sh

install_pipx() {
  local _T0_PIPX
  _T0_PIPX=$(date +%s)
  local _TITLE="Pipx"
  local _PROVIDER="pipx"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Toolchain Manager" "Pipx" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_PIPX="✅ mise"
  run_mise install pipx || _STAT_PIPX="❌ Failed"
  log_summary "Toolchain Manager" "Pipx" "$_STAT_PIPX" "$(get_version pipx)" "$(($(date +%s) - _T0_PIPX))"
}

# Purpose: Installs Gitleaks for secrets scanning.
# Delegate: Managed by mise (.mise.toml)
install_gitleaks() {
  local _T0_GITL
  _T0_GITL=$(date +%s)
  local _TITLE="Gitleaks"
  local _PROVIDER="gitleaks"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Gitleaks" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if [ ! -d ".git" ]; then
    log_summary "Lint Tool" "Gitleaks" "⏭️ Skipped (no .git)" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_GITL="✅ mise"
  run_mise install gitleaks || _STAT_GITL="❌ Failed"
  log_summary "Lint Tool" "Gitleaks" "$_STAT_GITL" "$(get_version gitleaks)" "$(($(date +%s) - _T0_GITL))"
}

# Purpose: Installs Hadolint for Dockerfile linting.
# Delegate: Managed by mise (.mise.toml)
install_hadolint() {
  local _T0_HADO
  _T0_HADO=$(date +%s)
  local _TITLE="Hadolint"
  local _PROVIDER="github:hadolint/hadolint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Hadolint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Dockerfile docker-compose.yml" "*.dockerfile *.Dockerfile"; then
    log_summary "Lint Tool" "Hadolint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_HADO="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_HADO="❌ Failed"
  log_summary "Lint Tool" "Hadolint" "$_STAT_HADO" "$(get_version hadolint)" "$(($(date +%s) - _T0_HADO))"
}

# Purpose: Installs golangci-lint for Go projects.
# Delegate: Managed by mise (.mise.toml)
install_go_lint() {
  local _T0_GO
  _T0_GO=$(date +%s)
  local _TITLE="Go Lint"
  local _PROVIDER="github:golangci/golangci-lint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Go Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "go.mod go.sum" "*.go"; then
    log_summary "Lint Tool" "Go Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_GO="✅ mise"
  run_mise install golangci-lint || _STAT_GO="❌ Failed"
  log_summary "Lint Tool" "Go Lint" "$_STAT_GO" "$(get_version golangci-lint)" "$(($(date +%s) - _T0_GO))"
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
  local _TITLE="Checkmake"
  local _PROVIDER="checkmake"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Checkmake" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Makefile" "*.make"; then
    log_summary "Lint Tool" "Checkmake" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_CM="✅ mise"
  run_mise install checkmake || _STAT_CM="❌ Failed"
  log_summary "Lint Tool" "Checkmake" "$_STAT_CM" "$(get_version checkmake)" "$(($(date +%s) - _T0_CM))"
}

# Additional language-specific modules are loaded dynamically via ${_G_LIB_DIR}/langs/*.sh

# Purpose: Activates git pre-commit hooks.
# Params:
#   None
# Examples:
#   setup_hooks
setup_hooks() {
  local _T0_HOOK
  _T0_HOOK=$(date +%s)
  _log_setup "Pre-commit Hooks" "pipx:pre-commit"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Other" "Hooks" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # 1. Dependency: pre-commit must be installed
  install_pre_commit

  # 2. Activation
  local _STAT_HOOK="✅ Activated"
  install_runtime_hooks || _STAT_HOOK="❌ Failed"

  local _DUR_HOOK
  _DUR_HOOK=$(($(date +%s) - _T0_HOOK))
  log_summary "Other" "Hooks" "$_STAT_HOOK" "$(get_version pre-commit --version)" "$_DUR_HOOK"
}

# Purpose: Installs TFLint.
# Delegate: Managed by mise (.mise.toml)
install_tflint() {
  local _T0_TF
  _T0_TF=$(date +%s)
  local _TITLE="TFLint"
  local _PROVIDER="github:terraform-linters/tflint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "TFLint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.tf"; then
    log_summary "Lint Tool" "TFLint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_TF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TF="❌ Failed"
  log_summary "Lint Tool" "TFLint" "$_STAT_TF" "$(get_version tflint)" "$(($(date +%s) - _T0_TF))"
}

# Purpose: Installs Kube-Linter.
# Delegate: Managed by mise (.mise.toml)
install_kube_linter() {
  local _T0_KL
  _T0_KL=$(date +%s)
  local _TITLE="Kube-Linter"
  local _PROVIDER="github:stackrox/kube-linter"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Kube-Linter" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Enhanced guard: Detect K8s manifests or Helm charts ONLY
  if ! has_lang_files "" "CHARTS K8S"; then
    log_summary "Lint Tool" "Kube-Linter" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_KL="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_KL="❌ Failed"
  log_summary "Lint Tool" "Kube-Linter" "$_STAT_KL" "$(get_version kube-linter)" "$(($(date +%s) - _T0_KL))"
}

# Purpose: Installs google-java-format for Java project linting.
# Delegate: Managed by mise (.mise.toml)
# WARNING: google-java-format has no prebuilt binary for linux/arm64.
#          On ARM64 Linux, this step is skipped. Use: java -jar google-java-format.jar
install_java_lint() {
  local _T0_JAVA
  _T0_JAVA=$(date +%s)
  local _TITLE="Java Lint"
  local _PROVIDER="google-java-format"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Java Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "pom.xml build.gradle" "*.java"; then
    log_summary "Lint Tool" "Java Lint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # ARM64 Linux: no prebuilt binary available for google-java-format
  if [ "$OS" = "linux" ] && [ "$ARCH" = "aarch64" ]; then
    log_warn "google-java-format has no prebuilt binary for linux/arm64. Skipping."
    log_summary "Lint Tool" "Java Lint" "⚠️ ARM64 N/A" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_JAVA="✅ mise"
  run_mise install "github:google/google-java-format" || _STAT_JAVA="❌ Failed"
  log_summary "Lint Tool" "Java Lint" "$_STAT_JAVA" "$(get_version google-java-format)" "$(($(date +%s) - _T0_JAVA))"
}

# Purpose: Sets up Rubocop for Ruby project linting.
# Params:
#   None
# Examples:
#   install_ruby_lint
install_ruby_lint() {
  local _T0_RUBY
  _T0_RUBY=$(date +%s)
  local _TITLE="Rubocop"
  local _PROVIDER="rubocop"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Rubocop" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Gemfile Gemfile.lock" "*.rb"; then
    log_summary "Lint Tool" "Rubocop" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if ! command -v gem >/dev/null 2>&1; then
    log_summary "Lint Tool" "Rubocop" "⏭️ Skipped (gem missing)" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  # Check in PATH and common user-gem locations to avoid redundant slow gem install
  local _RUBO_BIN_REF="rubocop"
  if ! command -v rubocop >/dev/null 2>&1; then
    local _GEM_BIN_RUBY
    _GEM_BIN_RUBY=$(gem environment 2>/dev/null | grep "EXECUTABLE DIRECTORY" | awk '{print $NF}')
    if [ -x "$_GEM_BIN_RUBY/rubocop" ]; then
      _RUBO_BIN_REF="$_GEM_BIN_RUBY/rubocop"
    fi
  fi

  if command -v "$_RUBO_BIN_REF" >/dev/null 2>&1; then
    log_summary "Lint Tool" "Rubocop" "✅ Exists" "$(get_version "$_RUBO_BIN_REF")" "0"
    return 0
  fi

  local _STAT_RUBY="✅ Installed"
  run_quiet gem install rubocop --user-install --no-document --quiet || _STAT_RUBY="❌ Failed"
  log_summary "Lint Tool" "Rubocop" "$_STAT_RUBY" "$(get_version rubocop)" "$(($(date +%s) - _T0_RUBY))"
}

# Purpose: Verifies Dart SDK availability.
# Params:
#   None
# Examples:
#   setup_dart
setup_dart() {
  _log_setup "Dart SDK" "dart"
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

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Swift" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Package.swift" "*.swift"; then
    log_summary "Lint Tool" "Swift" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Transition: Prefer cross-platform installer (pipx-based in mise) over brew/port
  install_swiftformat
  install_swiftlint

  log_summary "Lint Tool" "Swift" "✅ Sync" "$(get_version swiftlint lint --version)" "$(($(date +%s) - _T0_SWIFT))"
}

# Purpose: Verifies .NET SDK availability.
# Params:
#   None
# Examples:
#   setup_dotnet
setup_dotnet() {
  local _T0_DOT
  _T0_DOT=$(date +%s)

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" ".NET" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "global.json" "*.csproj *.sln *.cs"; then
    log_summary "Runtime" ".NET" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup ".NET SDK Check" "dotnet"

  local _STAT_DOTNET="✅ Installed"
  install_runtime_dotnet || _STAT_DOTNET="❌ Failed"

  local _DUR_DOTNET
  _DUR_DOTNET=$(($(date +%s) - _T0_DOT))
  log_summary "Runtime" ".NET" "$_STAT_DOTNET" "$(get_version dotnet)" "$_DUR_DOTNET"

  # Install .NET specific tools (managed via mise)
  install_dotnet_format
}

# Purpose: Installs osv-scanner for vulnerability scanning.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — heavy and slow. Skipped on local environments.
install_osv_scanner() {
  local _T0_OSV
  _T0_OSV=$(date +%s)
  local _TITLE="OSV-Scanner"
  local _PROVIDER="github:google/osv-scanner"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "OSV-Scanner" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! is_ci_env; then
    log_summary "Security Tool" "OSV-Scanner" "⏭️ Local skip" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_OSV="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_OSV="❌ Failed"
  log_summary "Security Tool" "OSV-Scanner" "$_STAT_OSV" "$(get_version osv-scanner)" "$(($(date +%s) - _T0_OSV))"
}

# Purpose: Installs lychee for broken link checking.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — network intensive. Skipped on local environments.
install_lychee() {
  local _T0_LYCHEE
  _T0_LYCHEE=$(date +%s)
  local _TITLE="Lychee"
  local _PROVIDER="github:lycheeverse/lychee"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "Lychee" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! is_ci_env; then
    log_summary "Security Tool" "Lychee" "⏭️ Local skip" "-" "0"
    return 0
  fi

  if ! has_lang_files "README.md docs" "*.md *.html"; then
    log_summary "Security Tool" "Lychee" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_LYCHEE="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_LYCHEE="❌ Failed"
  log_summary "Security Tool" "Lychee" "$_STAT_LYCHEE" "$(get_version lychee)" "$(($(date +%s) - _T0_LYCHEE))"
}

# Purpose: Installs Trivy for security scanning.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — heavy and slow. Skipped on local environments.
install_trivy() {
  local _T0_TRVY
  _T0_TRVY=$(date +%s)
  local _TITLE="Trivy"
  local _PROVIDER="github:aquasecurity/trivy"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "Trivy" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! is_ci_env; then
    log_summary "Security Tool" "Trivy" "⏭️ Local skip" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_TRVY="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TRVY="❌ Failed"
  log_summary "Security Tool" "Trivy" "$_STAT_TRVY" "$(get_version trivy)" "$(($(date +%s) - _T0_TRVY))"
}

# Purpose: Installs swiftformat for Swift linting.
# Delegate: Managed by mise (.mise.toml)
install_swiftformat() {
  local _T0_SF
  _T0_SF=$(date +%s)
  local _TITLE="SwiftFormat"
  local _PROVIDER="github:nicklockwood/SwiftFormat"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Swift" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Package.swift" "*.swift"; then
    log_summary "Lint Tool" "Swift" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SF="❌ Failed"
  log_summary "Lint Tool" "Swift" "$_STAT_SF" "$(get_version swiftformat)" "$(($(date +%s) - _T0_SF))"
}

# Purpose: Installs swiftlint for Swift linting.
# Delegate: Managed by mise (.mise.toml)
install_swiftlint() {
  local _T0_SL
  _T0_SL=$(date +%s)
  local _TITLE="SwiftLint"
  local _PROVIDER="github:realm/SwiftLint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Swift" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Package.swift" "*.swift"; then
    log_summary "Lint Tool" "Swift" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SL="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SL="❌ Failed"
  log_summary "Lint Tool" "Swift" "$_STAT_SL" "$(get_version swiftlint)" "$(($(date +%s) - _T0_SL))"
}

# Purpose: Installs dotnet-format for .NET linting.
# Delegate: Managed by mise (.mise.toml)
install_dotnet_format() {
  local _T0_DNF
  _T0_DNF=$(date +%s)
  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_DNF="✅ Available"
  # dotnet-format is now built-in as 'dotnet format'
  if ! dotnet format --version >/dev/null 2>&1; then
    _STAT_DNF="❌ Missing"
  fi
  log_summary "Lint Tool" ".NET" "$_STAT_DNF" "$(dotnet format --version 2>/dev/null || echo "-")" "$(($(date +%s) - _T0_DNF))"
}

# Purpose: Installs zizmor for GitHub Actions auditing.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — security audit. Skipped on local environments.
install_zizmor() {
  local _T0_ZIZ
  _T0_ZIZ=$(date +%s)
  local _TITLE="Zizmor"
  local _PROVIDER="pipx:zizmor"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "Zizmor" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! is_ci_env; then
    log_summary "Security Tool" "Zizmor" "⏭️ Local skip" "-" "0"
    return 0
  fi

  if ! has_lang_files ".github/workflows" "*.yml *.yaml"; then
    log_summary "Security Tool" "Zizmor" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_ZIZ="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ZIZ="❌ Failed"
  log_summary "Security Tool" "Zizmor" "$_STAT_ZIZ" "$(get_version zizmor)" "$(($(date +%s) - _T0_ZIZ))"
}

# Purpose: Installs cargo-audit for Rust projects.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — security audit. Skipped on local environments.
install_cargo_audit() {
  local _T0_CRGO
  _T0_CRGO=$(date +%s)
  local _TITLE="Cargo-Audit"
  local _PROVIDER="cargo:cargo-audit"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "Cargo-Audit" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! is_ci_env; then
    log_summary "Security Tool" "Cargo-Audit" "⏭️ Local skip" "-" "0"
    return 0
  fi

  if ! has_lang_files "Cargo.toml Cargo.lock" "*.rs"; then
    log_summary "Security Tool" "Cargo-Audit" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    log_summary "Security Tool" "Cargo-Audit" "⚠️ cargo missing" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_CRGO="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_CRGO="❌ Failed"
  log_summary "Security Tool" "Cargo-Audit" "$_STAT_CRGO" "$(get_version cargo-audit)" "$(($(date +%s) - _T0_CRGO))"
}

# Purpose: Installs govulncheck for Go projects.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — vulnerability scanner. Skipped on local environments.
install_govulncheck() {
  local _T0_GOVC
  _T0_GOVC=$(date +%s)
  local _TITLE="Govulncheck"
  local _PROVIDER="go:golang.org/x/vuln/cmd/govulncheck"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "Govulncheck" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! is_ci_env; then
    log_summary "Security Tool" "Govulncheck" "⏭️ Local skip" "-" "0"
    return 0
  fi

  if ! has_lang_files "go.mod go.sum" "*.go"; then
    log_summary "Security Tool" "Govulncheck" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if ! command -v go >/dev/null 2>&1; then
    log_summary "Security Tool" "Govulncheck" "⚠️ go missing" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_GOVC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_GOVC="❌ Failed"
  log_summary "Security Tool" "Govulncheck" "$_STAT_GOVC" "$(get_version govulncheck)" "$(($(date +%s) - _T0_GOVC))"
}

install_shfmt() {
  local _T0_SHF
  _T0_SHF=$(date +%s)
  local _TITLE="Shfmt"
  local _PROVIDER="pipx:shfmt-py"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Shfmt" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    log_summary "Lint Tool" "Shfmt" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SHF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SHF="❌ Failed"
  log_summary "Lint Tool" "Shfmt" "$_STAT_SHF" "$(get_version shfmt)" "$(($(date +%s) - _T0_SHF))"
}

install_shellcheck() {
  local _T0_SHC
  _T0_SHC=$(date +%s)
  local _TITLE="Shellcheck"
  local _PROVIDER="pipx:shellcheck-py"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Shellcheck" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    log_summary "Lint Tool" "Shellcheck" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SHC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SHC="❌ Failed"
  log_summary "Lint Tool" "Shellcheck" "$_STAT_SHC" "$(get_version shellcheck)" "$(($(date +%s) - _T0_SHC))"
}

install_actionlint() {
  local _T0_ACT
  _T0_ACT=$(date +%s)
  local _TITLE="Actionlint"
  local _PROVIDER="pipx:actionlint-py"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Actionlint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Guard: Detect GHA workflows folder only
  if ! has_lang_files ".github/workflows" "*.yml *.yaml"; then
    log_summary "Lint Tool" "Actionlint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_ACT="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ACT="❌ Failed"
  log_summary "Lint Tool" "Actionlint" "$_STAT_ACT" "$(get_version actionlint)" "$(($(date +%s) - _T0_ACT))"
}

install_taplo() {
  local _T0_TAP
  _T0_TAP=$(date +%s)
  local _TITLE="Taplo"
  local _PROVIDER="npm:@taplo/cli"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Taplo" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.toml"; then
    log_summary "Lint Tool" "Taplo" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_TAP="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TAP="❌ Failed"
  log_summary "Lint Tool" "Taplo" "$_STAT_TAP" "$(get_version taplo)" "$(($(date +%s) - _T0_TAP))"
}

install_prettier() {
  local _T0_PRE
  _T0_PRE=$(date +%s)
  local _TITLE="Prettier"
  local _PROVIDER="npm:prettier"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Prettier" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.json *.yaml *.yml *.vue *.js *.ts *.jsx *.tsx"; then
    log_summary "Lint Tool" "Prettier" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_PRE="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_PRE="❌ Failed"
  log_summary "Lint Tool" "Prettier" "$_STAT_PRE" "$(get_version prettier)" "$(($(date +%s) - _T0_PRE))"
}

install_sort_package_json() {
  local _T0_SPJ
  _T0_SPJ=$(date +%s)
  local _TITLE="sort-package-json"
  local _PROVIDER="npm:sort-package-json"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Other" "sort-package-json" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if [ ! -f "package.json" ]; then
    log_summary "Other" "sort-package-json" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SPJ="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SPJ="❌ Failed"
  log_summary "Other" "sort-package-json" "$_STAT_SPJ" "$(get_version sort-package-json)" "$(($(date +%s) - _T0_SPJ))"
}

install_goreleaser() {
  local _T0_GR
  _T0_GR=$(date +%s)
  local _TITLE="GoReleaser"
  local _PROVIDER="github:goreleaser/goreleaser"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Other" "GoReleaser" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files ".goreleaser.yaml .goreleaser.yml" ""; then
    log_summary "Other" "GoReleaser" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_GR="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_GR="❌ Failed"
  log_summary "Other" "GoReleaser" "$_STAT_GR" "$(get_version goreleaser)" "$(($(date +%s) - _T0_GR))"
}

# Purpose: Installs spectral for API linting.
# Delegate: Managed by mise (.mise.toml)
install_spectral() {
  local _T0_SPEC
  _T0_SPEC=$(date +%s)
  local _TITLE="Spectral"
  local _PROVIDER="npm:@stoplight/spectral-cli"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Spectral" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*openapi* *swagger* *asyncapi*"; then
    log_summary "Lint Tool" "Spectral" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SPEC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SPEC="❌ Failed"
  log_summary "Lint Tool" "Spectral" "$_STAT_SPEC" "$(get_version spectral)" "$(($(date +%s) - _T0_SPEC))"
}

# Purpose: Installs commitlint.
# Delegate: Managed by mise (.mise.toml)
install_commitlint() {
  local _T0_CL
  _T0_CL=$(date +%s)
  local _TITLE="Commitlint"
  # SSoT: Install both CLI and conventional config via mise npm provider
  local _PROVIDER="npm:@commitlint/cli"
  local _CONFIG_PROVIDER="npm:@commitlint/config-conventional"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Other" "Commitlint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if [ ! -d ".git" ]; then
    log_summary "Other" "Commitlint" "⏭️ Skipped (no .git)" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  log_info "Installing commitlint + convention config via mise..."
  run_mise install "$_PROVIDER" "$_CONFIG_PROVIDER" || _STAT_CL="❌ Failed"

  log_summary "Other" "Commitlint" "$_STAT_CL" "$(get_version commitlint)" "$(($(date +%s) - _T0_CL))"
}

install_dockerfile_utils() {
  local _T0_DU
  _T0_DU=$(date +%s)
  local _TITLE="dockerfile-utils"
  local _PROVIDER="npm:dockerfile-utils"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "dockerfile-utils" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Dockerfile" "*.dockerfile *.Dockerfile"; then
    log_summary "Lint Tool" "dockerfile-utils" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_DU="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_DU="❌ Failed"
  log_summary "Lint Tool" "dockerfile-utils" "$_STAT_DU" "$(get_version dockerfile-utils)" "$(($(date +%s) - _T0_DU))"
}

install_clang_format() {
  local _T0_CF
  _T0_CF=$(date +%s)
  local _TITLE="clang-format"
  local _PROVIDER="pipx:clang-format"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "clang-format" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.c *.cpp *.h *.hpp *.cc *.m *.mm"; then
    log_summary "Lint Tool" "clang-format" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_CF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_CF="❌ Failed"
  log_summary "Lint Tool" "clang-format" "$_STAT_CF" "$(get_version clang-format)" "$(($(date +%s) - _T0_CF))"
}

install_ktlint() {
  local _T0_KT
  _T0_KT=$(date +%s)
  local _TITLE="ktlint"
  local _PROVIDER="npm:@naturalcycles/ktlint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "ktlint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.kt *.kts"; then
    log_summary "Lint Tool" "ktlint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_KT="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_KT="❌ Failed"
  log_summary "Lint Tool" "ktlint" "$_STAT_KT" "$(get_version ktlint --version)" "$(($(date +%s) - _T0_KT))"
}

install_ruff() {
  local _T0_RUF
  _T0_RUF=$(date +%s)
  local _TITLE="Ruff"
  local _PROVIDER="pipx:ruff"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Ruff" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "requirements.txt pyproject.toml" "*.py"; then
    log_summary "Lint Tool" "Ruff" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_RUF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_RUF="❌ Failed"
  log_summary "Lint Tool" "Ruff" "$_STAT_RUF" "$(get_version ruff)" "$(($(date +%s) - _T0_RUF))"
}

install_yamllint() {
  local _T0_YL
  _T0_YL=$(date +%s)
  local _TITLE="Yamllint"
  local _PROVIDER="pipx:yamllint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Yamllint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files ".yamllint .yamllint.yml" "*.yaml *.yml"; then
    log_summary "Lint Tool" "Yamllint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_YL="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_YL="❌ Failed"
  log_summary "Lint Tool" "Yamllint" "$_STAT_YL" "$(get_version yamllint)" "$(($(date +%s) - _T0_YL))"
}

install_sqlfluff() {
  local _T0_SQL
  _T0_SQL=$(date +%s)
  local _TITLE="Sqlfluff"
  local _PROVIDER="sqlfluff"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Sqlfluff" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files ".sqlfluff" "*.sql"; then
    log_summary "Lint Tool" "Sqlfluff" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SQL="✅ mise"
  run_mise install sqlfluff || _STAT_SQL="❌ Failed"
  log_summary "Lint Tool" "Sqlfluff" "$_STAT_SQL" "$(get_version sqlfluff)" "$(($(date +%s) - _T0_SQL))"
}

install_markdownlint() {
  local _T0_MD
  _T0_MD=$(date +%s)
  local _TITLE="Markdownlint"
  local _PROVIDER="npm:markdownlint-cli2"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Markdownlint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.md"; then
    log_summary "Lint Tool" "Markdownlint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_MD="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_MD="❌ Failed"
  log_summary "Lint Tool" "Markdownlint" "$_STAT_MD" "$(get_version markdownlint-cli2)" "$(($(date +%s) - _T0_MD))"
}

install_dotenv_linter() {
  local _T0_DOT
  _T0_DOT=$(date +%s)
  local _TITLE="dotenv-linter"
  local _PROVIDER="pipx:dotenv-linter"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "dotenv-linter" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files ".env .env.example" "*.env"; then
    log_summary "Lint Tool" "dotenv-linter" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_DOT="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_DOT="❌ Failed"
  log_summary "Lint Tool" "dotenv-linter" "$_STAT_DOT" "$(get_version dotenv-linter)" "$(($(date +%s) - _T0_DOT))"
}

install_ansible_lint() {
  local _T0_ANS
  _T0_ANS=$(date +%s)
  local _TITLE="Ansible-lint"
  local _PROVIDER="pipx:ansible-lint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Ansible-lint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "ansible.cfg playbook.yml roles/ tasks/"; then
    log_summary "Lint Tool" "Ansible-lint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_ANS="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ANS="❌ Failed"
  log_summary "Lint Tool" "Ansible-lint" "$_STAT_ANS" "$(get_version ansible-lint)" "$(($(date +%s) - _T0_ANS))"
}

install_bats() {
  local _T0_BATS
  _T0_BATS=$(date +%s)
  local _TITLE="Bats"
  local _PROVIDER="npm:bats"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Test Tool" "Bats" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.bats"; then
    log_summary "Test Tool" "Bats" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_BATS="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_BATS="❌ Failed"
  log_summary "Test Tool" "Bats" "$_STAT_BATS" "$(get_version bats --version)" "$(($(date +%s) - _T0_BATS))"
}

# Purpose: Vendors bats-support and bats-assert for tests.
install_bats_libs() {
  local _T0_BL
  _T0_BL=$(date +%s)
  local _TITLE="Bats Libraries"
  local _PROVIDER="github:bats-core"

  if ! has_lang_files "" "*.bats"; then
    log_summary "Test Tool" "Bats-Libs" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Test Tool" "Bats-Libs" "⚖️ Previewed" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  local _VENDOR_DIR="vendor"
  mkdir -p "$_VENDOR_DIR"

  # SSoT: Download from GitHub via GITHUB_PROXY
  # bats-support
  if [ ! -d "$_VENDOR_DIR/bats-support" ]; then
    log_info "Cloning bats-support..."
    run_quiet git clone --depth 1 -b v0.3.0 "https://github.com/bats-core/bats-support.git" "$_VENDOR_DIR/bats-support"
  fi

  # bats-assert
  if [ ! -d "$_VENDOR_DIR/bats-assert" ]; then
    log_info "Cloning bats-assert..."
    run_quiet git clone --depth 1 -b v2.1.0 "https://github.com/bats-core/bats-assert.git" "$_VENDOR_DIR/bats-assert"
  fi

  log_summary "Test Tool" "Bats-Libs" "✅ Vendored" "v0.3.0/v2.1.0" "$(($(date +%s) - _T0_BL))"
}

# Purpose: Installs eslint.
# Delegate: Managed by mise (.mise.toml)
install_eslint() {
  local _T0_ES
  _T0_ES=$(date +%s)
  local _TITLE="ESLint"
  local _PROVIDER="npm:eslint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "ESLint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "package.json" "*.js *.ts *.vue *.jsx *.tsx"; then
    log_summary "Lint Tool" "ESLint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_ES="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ES="❌ Failed"
  log_summary "Lint Tool" "ESLint" "$_STAT_ES" "$(get_version eslint)" "$(($(date +%s) - _T0_ES))"
}

# Purpose: Installs stylelint.
# Delegate: Managed by mise (.mise.toml)
install_stylelint() {
  local _T0_SL
  _T0_SL=$(date +%s)
  local _TITLE="Stylelint"
  local _PROVIDER="npm:stylelint"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Stylelint" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.css *.scss *.less *.vue"; then
    log_summary "Lint Tool" "Stylelint" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SL="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SL="❌ Failed"
  log_summary "Lint Tool" "Stylelint" "$_STAT_SL" "$(get_version stylelint)" "$(($(date +%s) - _T0_SL))"
}

# Purpose: Installs vitepress.
# Delegate: Managed by mise (.mise.toml)
install_vitepress() {
  local _T0_VP
  _T0_VP=$(date +%s)
  local _TITLE="VitePress"
  local _PROVIDER="npm:vitepress"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Doc Tool" "VitePress" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if [ ! -d docs ]; then
    log_summary "Doc Tool" "VitePress" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_VP="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_VP="❌ Failed"
  log_summary "Doc Tool" "VitePress" "$_STAT_VP" "$(get_version vitepress)" "$(($(date +%s) - _T0_VP))"
}

# Purpose: Installs commitizen.
# Delegate: Managed by mise (.mise.toml)
install_commitizen() {
  local _T0_CZ
  _T0_CZ=$(date +%s)
  local _TITLE="Commitizen"
  local _PROVIDER="npm:commitizen"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Other" "Commitizen" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if [ ! -f "package.json" ]; then
    log_summary "Other" "Commitizen" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_CZ="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_CZ="❌ Failed"
  log_summary "Other" "Commitizen" "$_STAT_CZ" "$(get_version commitizen)" "$(($(date +%s) - _T0_CZ))"
}

# Purpose: Installs pip-audit for Python dependency vulnerability scanning.
# NOTE: CI-only tool — security audit. Skipped on local environments.
install_pip_audit() {
  local _T0_PA
  _T0_PA=$(date +%s)
  local _TITLE="pip-audit"
  local _PROVIDER="pipx:pip-audit"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "pip-audit" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! is_ci_env; then
    log_summary "Security Tool" "pip-audit" "⏭️ Local skip" "-" "0"
    return 0
  fi

  if ! has_lang_files "requirements.txt pyproject.toml" "*.py"; then
    log_summary "Security Tool" "pip-audit" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_PA="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_PA="❌ Failed"
  log_summary "Security Tool" "pip-audit" "$_STAT_PA" "$(get_version pip-audit --version)" "$(($(date +%s) - _T0_PA))"
}

# Purpose: Installs pre-commit.
# Delegate: Managed by mise (.mise.toml)
install_pre_commit() {
  local _T0_PC
  _T0_PC=$(date +%s)
  local _TITLE="Pre-commit"
  local _PROVIDER="pipx:pre-commit"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Other" "Pre-commit" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if [ ! -f ".pre-commit-config.yaml" ]; then
    log_summary "Other" "Pre-commit" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_PC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_PC="❌ Failed"
  log_summary "Other" "Pre-commit" "$_STAT_PC" "$(get_version pre-commit --version)" "$(($(date +%s) - _T0_PC))"
}

setup_security() {
  log_info "── Setting up Security Audit Tools ──"
  install_osv_scanner
  install_trivy
  install_zizmor
  install_govulncheck
  install_cargo_audit
  install_lychee
}

# Purpose: Installs editorconfig-checker.
# Delegate: Managed by mise (.mise.toml)
install_editorconfig_checker() {
  local _T0_ECC
  _T0_ECC=$(date +%s)
  local _TITLE="editorconfig-checker"
  local _PROVIDER="github:editorconfig-checker/editorconfig-checker"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "editorconfig-checker" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files ".editorconfig" ""; then
    log_summary "Lint Tool" "editorconfig-checker" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_ECC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ECC="❌ Failed"
  # Symlink Fix: Ensure editorconfig-checker binary is available if only ec exists
  local _ECC_INSTALL_DIR
  _ECC_INSTALL_DIR=$(mise ls --json | jq -r '."editorconfig-checker"[0].install_path' 2>/dev/null)
  if [ -d "$_ECC_INSTALL_DIR/bin" ]; then
    if [ -f "$_ECC_INSTALL_DIR/bin/ec" ] && [ ! -f "$_ECC_INSTALL_DIR/bin/editorconfig-checker" ]; then
      ln -sf "ec" "$_ECC_INSTALL_DIR/bin/editorconfig-checker"
      mise reshim >/dev/null 2>&1 || true
    fi
  fi
  log_summary "Lint Tool" "editorconfig-checker" "$_STAT_ECC" "$(get_version editorconfig-checker)" "$(($(date +%s) - _T0_ECC))"
}

# Purpose: Installs stylua for Lua linting.
# Delegate: Managed by mise (.mise.toml)
install_stylua() {
  local _T0_SL
  _T0_SL=$(date +%s)
  local _TITLE="StyLua"
  local _PROVIDER="github:JohnnyMorganz/StyLua"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "StyLua" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "LUA"; then
    log_summary "Lint Tool" "StyLua" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SL="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SL="❌ Failed"
  log_summary "Lint Tool" "StyLua" "$_STAT_SL" "$(get_version stylua)" "$(($(date +%s) - _T0_SL))"
}

# Purpose: Installs buf for Protobuf linting/management.
# Delegate: Managed by mise (.mise.toml)
install_buf() {
  local _T0_BUF
  _T0_BUF=$(date +%s)
  local _TITLE="Buf"
  local _PROVIDER="github:bufbuild/buf"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "Buf" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "PROTOC"; then
    log_summary "Lint Tool" "Buf" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_BUF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_BUF="❌ Failed"
  log_summary "Lint Tool" "Buf" "$_STAT_BUF" "$(get_version buf --version)" "$(($(date +%s) - _T0_BUF))"
}

# Purpose: Installs Just (modern runner).
# Delegate: Managed by mise (.mise.toml)
install_just() {
  local _T0_JUST
  _T0_JUST=$(date +%s)
  local _TITLE="Just"
  local _PROVIDER="github:casey/just"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Toolchain" "Just" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "JUST"; then
    log_summary "Toolchain" "Just" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_JUST="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_JUST="❌ Failed"
  log_summary "Toolchain" "Just" "$_STAT_JUST" "$(get_version just --version)" "$(($(date +%s) - _T0_JUST))"
}

# Purpose: Installs Task (modern runner).
# Delegate: Managed by mise (.mise.toml)
install_task() {
  local _T0_TASK
  _T0_TASK=$(date +%s)
  local _TITLE="Task"
  local _PROVIDER="github:go-task/task"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Toolchain" "Task" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "TASK"; then
    log_summary "Toolchain" "Task" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_TASK="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TASK="❌ Failed"
  log_summary "Toolchain" "Task" "$_STAT_TASK" "$(get_version task --version)" "$(($(date +%s) - _T0_TASK))"
}

# Purpose: Installs CUE and Jsonnet.
# Delegate: Managed by mise (.mise.toml)
install_cue() {
  local _T0_CUE
  _T0_CUE=$(date +%s)
  local _TITLE="CUE/Jsonnet"
  local _PROVIDER="github:cue-lang/cue"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "CUE" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "CUES"; then
    log_summary "Lint Tool" "CUE" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "cue/jsonnet"
  local _STAT_CUE="✅ mise"
  run_mise install "$_PROVIDER" "github:google/go-jsonnet" || _STAT_CUE="❌ Failed"
  log_summary "Lint Tool" "CUE/Jsonnet" "$_STAT_CUE" "$(get_version cue version | head -n 1)" "$(($(date +%s) - _T0_CUE))"
}

# Purpose: Installs OPA/Rego.
# Delegate: Managed by mise (.mise.toml)
install_rego() {
  local _T0_REGO
  _T0_REGO=$(date +%s)
  local _TITLE="Rego (OPA)"
  local _PROVIDER="github:open-policy-agent/opa"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security Tool" "Rego" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "REGO"; then
    log_summary "Security Tool" "Rego" "⏭️ Skipped" "-" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_REGO="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_REGO="❌ Failed"
  log_summary "Security Tool" "Rego" "$_STAT_REGO" "$(get_version opa version | grep Version | awk '{print $NF}')" "$(($(date +%s) - _T0_REGO))"
}

# Purpose: Checks for Server configurations.
install_server() {
  if ! has_lang_files "" "SERVER"; then
    log_summary "Config" "Server" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Config" "Server" "✅ Detected" "-" "0"
}

# Purpose: Checks for Edge deployment configurations.
install_edge() {
  if ! has_lang_files "" "EDGE"; then
    log_summary "Config" "Edge" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Config" "Edge" "✅ Detected" "-" "0"
}

install_rn() {
  if ! has_lang_files "" "RN"; then
    log_summary "Mobile" "React Native" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Mobile" "React Native" "✅ Detected" "-" "0"
}

install_crossplane() {
  if ! has_lang_files "" "CROSSPLANE"; then
    log_summary "IaC" "Crossplane" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "IaC" "Crossplane" "✅ Detected" "-" "0"
}

install_playwright() {
  if ! has_lang_files "" "PLAYWRIGHT"; then
    log_summary "Testing" "Playwright" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Testing" "Playwright" "✅ Detected" "-" "0"
}

install_cypress() {
  if ! has_lang_files "" "CYPRESS"; then
    log_summary "Testing" "Cypress" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Testing" "Cypress" "✅ Detected" "-" "0"
}

install_vitest() {
  if ! has_lang_files "" "VITEST"; then
    log_summary "Testing" "Vitest" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Testing" "Vitest" "✅ Detected" "-" "0"
}

install_docusaurus() {
  if ! has_lang_files "" "DOCUSAURUS"; then
    log_summary "Docs" "Docusaurus" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Docs" "Docusaurus" "✅ Detected" "-" "0"
}

install_mkdocs() {
  if ! has_lang_files "" "MKDOCS"; then
    log_summary "Docs" "MkDocs" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Docs" "MkDocs" "✅ Detected" "-" "0"
}

install_sphinx() {
  if ! has_lang_files "" "SPHINX"; then
    log_summary "Docs" "Sphinx" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "Docs" "Sphinx" "✅ Detected" "-" "0"
}

install_jupyter() {
  if ! has_lang_files "" "JUPYTER"; then
    log_summary "AI/Data" "Jupyter" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "AI/Data" "Jupyter" "✅ Detected" "-" "0"
}

install_dvc() {
  if ! has_lang_files "" "DVC"; then
    log_summary "AI/Data" "DVC" "⏭️ Skipped" "-" "0"
    return 0
  fi
  log_summary "AI/Data" "DVC" "✅ Detected" "-" "0"
}

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

  init_summary_table "Setup Execution Summary"

  # Initialize Summary Legend (Only once per CI Job or first call)
  if [ "$_SETUP_SUMMARY_INITIALIZED" != "true" ] && ! check_ci_summary "Status Legend:"; then
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
        log_summary "Runtime" "Go" "✅ Detected" "$(go version | awk '{print $3}')" "0"
      fi
      if command -v cargo >/dev/null 2>&1; then
        log_summary "Runtime" "Rust" "✅ Detected" "$(cargo --version | awk '{print $2}')" "0"
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

  # ── Mode & Module Selection ──
  local _IS_ALL_MODULES=false
  if echo " ${_RAW_ARGS} " | grep -q " all "; then
    _IS_ALL_MODULES=true
  fi

  local _MODULES_LIST
  if [ -z "$(echo "${_RAW_ARGS}" | tr -d ' ')" ] || [ "$_IS_ALL_MODULES" = "true" ]; then
    # Full list for "On-demand" (default) or "All" (explicit)
    _MODULES_LIST="node python deno bun pipx php rust fastapi django springboot laravel nestjs tailwind redis mongodb postgresql vite gitleaks hadolint go checkmake tflint kube-linter powershell java ruby kotlin dart swift lua perl julia r groovy dotnet osv-scanner trivy zizmor govulncheck cargo-audit editorconfig-checker shfmt shellcheck actionlint taplo prettier sort-package-json goreleaser spectral commitlint dockerfile-utils clang-format cpp terraform solidity odin nim clojure gleam mojo objc ocaml fsharp erlang vlang crystal dlang haxe assemblyscript ballerina kcl pkl move elm rescript ada luau raku vala fpc lean lisp racket prolog fortran wat wasmtime ray mlflow airflow prefect dapr abap prql lit capacitor awk sed gnuplot graphviz plantuml capnproto wasmer nextjs nuxt remix dagger temporal langchain pytorch dbt otel clickhouse moonbit grain jsonnet starlark tcl duckdb vcpkg gherkin terragrunt spark helm graphql typst verilog vhdl octave matlab plsql tsql cobol stylus postcss k6 openapi promql latex proto cuda bicep cloudformation arkts shader qml apex applescript vba vue svelte astro assembly gdscript liquid avro thrift kustomize solid qwik tauri electron prisma edgedb surrealdb systemverilog flatbuffers asyncapi sass less pug handlebars ejs htmx alpine ktlint ruff stylelint yamllint sqlfluff markdownlint ansible-lint dotenv-linter bats bats-libs eslint vitepress commitizen pip-audit stylua buf tofu just task nix zig cue rego server edge flutter rn pulumi crossplane playwright cypress vitest docusaurus mkdocs sphinx jupyter dvc elixir haskell scala pre-commit hooks"
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
      if [ "$_G_OS" = "windows" ]; then
        log_info "Skipping bulk toolchain installation on Windows..."
      else
        log_info "Performing full toolchain synchronization via mise..."
        run_mise install
      fi
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
    fastapi) setup_fastapi ;;
    django) setup_django ;;
    springboot) setup_springboot ;;
    laravel) setup_laravel ;;
    nestjs) setup_nestjs ;;
    tailwind) setup_tailwind ;;
    redis) setup_redis ;;
    mongodb) setup_mongodb ;;
    postgresql) setup_postgresql ;;
    vite) setup_vite ;;
    deno) setup_deno ;;
    bun) setup_bun ;;
    pipx) install_pipx ;;
    gitleaks) install_gitleaks ;;
    checkmake) install_checkmake ;;
    hadolint) install_hadolint ;;
    go)
      setup_go
      install_go_lint
      ;;
    tflint) install_tflint ;;
    kube-linter) install_kube_linter ;;
    powershell) setup_powershell ;;
    php) setup_php ;;
    rust) setup_rust ;;
    java) setup_java ;;
    ruby) setup_ruby ;;
    kotlin) setup_kotlin ;;
    dart) setup_dart ;;
    swift) setup_swift ;;
    lua) setup_lua ;;
    cpp) setup_cpp ;;
    terraform) setup_terraform ;;
    solidity) setup_solidity ;;
    perl) setup_perl ;;
    julia) setup_julia ;;
    r) setup_r ;;
    groovy) setup_groovy ;;
    dotnet) setup_dotnet ;;
    osv-scanner) install_osv_scanner ;;
    trivy) install_trivy ;;
    zizmor) install_zizmor ;;
    govulncheck) install_govulncheck ;;
    cargo-audit) install_cargo_audit ;;
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
    stylua) install_stylua ;;
    buf) install_buf ;;
    tofu) setup_tofu ;;
    just) install_just ;;
    task) install_task ;;
    nix) setup_nix ;;
    zig) setup_zig ;;
    cue) install_cue ;;
    rego) install_rego ;;
    server) install_server ;;
    edge) install_edge ;;
    flutter) setup_flutter ;;
    react-native) setup_react_native ;;
    expo) setup_expo ;;
    ionic) setup_ionic ;;
    express) setup_express ;;
    fastify) setup_fastify ;;
    hono) setup_hono ;;
    flask) setup_flask ;;
    gin) setup_gin ;;
    fiber) setup_fiber ;;
    rails) setup_rails ;;
    typeorm) setup_typeorm ;;
    drizzle) setup_drizzle ;;
    rn) install_rn ;;
    pulumi) setup_pulumi ;;
    crossplane) install_crossplane ;;
    odin) setup_odin ;;
    nim) setup_nim ;;
    clojure) setup_clojure ;;
    gleam) setup_gleam ;;
    mojo) setup_mojo ;;
    objc) setup_objc ;;
    ocaml) setup_ocaml ;;
    fsharp) setup_fsharp ;;
    erlang) setup_erlang ;;
    vlang) setup_vlang ;;
    crystal) setup_crystal ;;
    dlang) setup_dlang ;;
    haxe) setup_haxe ;;
    assemblyscript) setup_assemblyscript ;;
    ballerina) setup_ballerina ;;
    kcl) setup_kcl ;;
    pkl) setup_pkl ;;
    move) setup_move ;;
    elm) setup_elm ;;
    rescript) setup_rescript ;;
    ada) setup_ada ;;
    luau) setup_luau ;;
    raku) setup_raku ;;
    vala) setup_vala ;;
    fpc) setup_fpc ;;
    lean) setup_lean ;;
    lisp) setup_lisp ;;
    racket) setup_racket ;;
    prolog) setup_prolog ;;
    fortran) setup_fortran ;;
    wat) setup_wat ;;
    wasmtime) setup_wasmtime ;;
    ray) setup_ray ;;
    mlflow) setup_mlflow ;;
    airflow) setup_airflow ;;
    prefect) setup_prefect ;;
    dapr) setup_dapr ;;
    abap) setup_abap ;;
    prql) setup_prql ;;
    lit) setup_lit ;;
    capacitor) setup_capacitor ;;
    awk) setup_awk ;;
    sed) setup_sed ;;
    gnuplot) setup_gnuplot ;;
    graphviz) setup_graphviz ;;
    plantuml) setup_plantuml ;;
    capnproto) setup_capnproto ;;
    wasmer) setup_wasmer ;;
    nextjs) setup_nextjs ;;
    nuxt) setup_nuxt ;;
    remix) setup_remix ;;
    dagger) setup_dagger ;;
    temporal) setup_temporal ;;
    langchain) setup_langchain ;;
    pytorch) setup_pytorch ;;
    dbt) setup_dbt ;;
    otel) setup_otel ;;
    clickhouse) setup_clickhouse ;;
    moonbit) setup_moonbit ;;
    grain) setup_grain ;;
    jsonnet) setup_jsonnet ;;
    starlark) setup_starlark ;;
    tcl) setup_tcl ;;
    duckdb) setup_duckdb ;;
    vcpkg) setup_vcpkg ;;
    gherkin) setup_gherkin ;;
    terragrunt) setup_terragrunt ;;
    spark) setup_spark ;;
    helm) setup_helm ;;
    graphql) setup_graphql ;;
    typst) setup_typst ;;
    verilog) setup_verilog ;;
    vhdl) setup_vhdl ;;
    octave) setup_octave ;;
    matlab) setup_matlab ;;
    plsql) setup_plsql ;;
    tsql) setup_tsql ;;
    cobol) setup_cobol ;;
    openapi) setup_openapi ;;
    promql) setup_promql ;;
    latex) setup_latex ;;
    proto) setup_proto ;;
    cuda) setup_cuda ;;
    bicep) setup_bicep ;;
    cloudformation) setup_cloudformation ;;
    arkts) setup_arkts ;;
    shader) setup_shader ;;
    qml) setup_qml ;;
    apex) setup_apex ;;
    applescript) setup_applescript ;;
    vba) setup_vba ;;
    vue) setup_vue ;;
    svelte) setup_svelte ;;
    astro) setup_astro ;;
    assembly) setup_assembly ;;
    gdscript) setup_gdscript ;;
    liquid) setup_liquid ;;
    avro) setup_avro ;;
    thrift) setup_thrift ;;
    kustomize) setup_kustomize ;;
    solid) setup_solid ;;
    stylus) setup_stylus ;;
    postcss) setup_postcss ;;
    k6) setup_k6 ;;
    sass) setup_sass ;;
    less) setup_less ;;
    pug) setup_pug ;;
    handlebars) setup_handlebars ;;
    ejs) setup_ejs ;;
    htmx) setup_htmx ;;
    alpine) setup_alpine ;;
    qwik) setup_qwik ;;
    tauri) setup_tauri ;;
    electron) setup_electron ;;
    prisma) setup_prisma ;;
    edgedb) setup_edgedb ;;
    surrealdb) setup_surrealdb ;;
    systemverilog) setup_systemverilog ;;
    flatbuffers) setup_flatbuffers ;;
    asyncapi) setup_asyncapi ;;
    playwright) install_playwright ;;
    cypress) install_cypress ;;
    vitest) install_vitest ;;
    docusaurus) install_docusaurus ;;
    mkdocs) install_mkdocs ;;
    sphinx) install_sphinx ;;
    jupyter) install_jupyter ;;
    dvc) install_dvc ;;
    elixir) setup_elixir ;;
    haskell) setup_haskell ;;
    scala) setup_scala ;;
    pre-commit) install_pre_commit ;;
    hooks) setup_hooks ;;
    *) log_error "Unknown module: $_cur_module" ;;
    esac
  done

  # ── Final Output Management ──
  if [ "$_IS_TOP_LEVEL" = "true" ] && [ -n "$SETUP_SUMMARY_FILE" ] && [ -f "$SETUP_SUMMARY_FILE" ]; then
    local _TOTAL_DUR_MAIN=$(($(date +%s) - _START_TIME_MAIN))
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
      # Pathing Diagnostic
      if ! command -v mise >/dev/null 2>&1; then
        log_warn "Warning: mise binary not found on PATH. You may need to restart your shell."
      fi
      case ":$PATH:" in
      *":$_G_MISE_SHIMS_BASE:"*) ;;
      *) log_warn "Warning: mise shims are not on your PATH. Run 'eval \"\$(mise activate bash)\"' to fix." ;;
      esac

      printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
      printf "  - Run %bmake install%b to install project dependencies.\n" "${GREEN}" "${NC}"
      printf "  - Run %bmake verify%b to ensure environment health.\n" "${GREEN}" "${NC}"
    fi
  fi
}

# Purpose: Wrapper for React Native setup.
setup_react_native() {
  . "$SCRIPT_DIR/lib/langs/react-native.sh"
  install_react_native
}

# Purpose: Wrapper for Expo setup.
setup_expo() {
  . "$SCRIPT_DIR/lib/langs/expo.sh"
  install_expo
}

# Purpose: Wrapper for Ionic setup.
setup_ionic() {
  . "$SCRIPT_DIR/lib/langs/ionic.sh"
  install_ionic
}

# Purpose: Wrapper for Express setup.
setup_express() {
  . "$SCRIPT_DIR/lib/langs/express.sh"
  install_express
}

# Purpose: Wrapper for Fastify setup.
setup_fastify() {
  . "$SCRIPT_DIR/lib/langs/fastify.sh"
  install_fastify
}

# Purpose: Wrapper for Hono setup.
setup_hono() {
  . "$SCRIPT_DIR/lib/langs/hono.sh"
  install_hono
}

# Purpose: Wrapper for Flask setup.
setup_flask() {
  . "$SCRIPT_DIR/lib/langs/flask.sh"
  install_flask
}

# Purpose: Wrapper for Gin setup.
setup_gin() {
  . "$SCRIPT_DIR/lib/langs/gin.sh"
  install_gin
}

# Purpose: Wrapper for Fiber setup.
setup_fiber() {
  . "$SCRIPT_DIR/lib/langs/fiber.sh"
  install_fiber
}

# Purpose: Wrapper for Rails setup.
setup_rails() {
  . "$SCRIPT_DIR/lib/langs/rails.sh"
  install_rails
}

# Purpose: Wrapper for TypeORM setup.
setup_typeorm() {
  . "$SCRIPT_DIR/lib/langs/typeorm.sh"
  install_typeorm
}

# Purpose: Wrapper for Drizzle setup.
setup_drizzle() {
  . "$SCRIPT_DIR/lib/langs/drizzle.sh"
  install_drizzle
}

main "$@"
