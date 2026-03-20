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
  node               Setup Node.js & Node.js Package Manager
  python             Setup Python Virtual Environment & dependencies
  gitleaks           Install Gitleaks (secrets scanning)
  hadolint           Install Hadolint (Docker linting)
  go                 Install golangci-lint
  checkmake          Install checkmake (Makefile linting)
  tflint             Install TFLint
  kube-linter        Install Kube-Linter
  java               Install google-java-format
  ruby               Setup Rubocop
  dart               Check Dart SDK
  swift              Install Swift linters (macOS)
  dotnet             Check .NET SDK
  security           Install security audit tools (osv-scanner, trivy, etc.)
  shfmt              Install shfmt
  shellcheck         Install shellcheck
  actionlint         Install actionlint
  taplo              Install taplo
  prettier           Install prettier
  buf                Install buf
  tofu               Install opentofu
  just               Install Just
  task               Install Task
  zig                Install Zig
  rego               Install OPA/Rego
  edge               Check Edge Configs
  pulumi             Install Pulumi CLI
  crossplane         Check Crossplane Manifests
  elixir             Install Elixir/Erlang
  haskell            Install Haskell/Stack
  scala              Install Scala/SBT
  php                Install PHP Runtime
  rust               Install Rust Runtime
  deno               Setup Deno
  bun                Setup Bun
  kotlin             Setup Kotlin & Ktlint
  julia              Setup Julia
  r                  Setup R
  perl               Setup Perl
  lua                Setup Lua
  groovy             Setup Groovy
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

# Optimization: Pre-cache mise state to avoid repeated invocations (accelerates no-op runs)
if command -v mise >/dev/null 2>&1; then
  log_info "Synchronizing mise state for fast-path detection..."
  _G_MISE_LS_JSON=$(mise ls --json --current 2>/dev/null)
  export _G_MISE_LS_JSON
fi

install_pipx() {
  local _T0_PIPX
  _T0_PIPX=$(date +%s)
  local _TITLE="Pipx"
  local _PROVIDER="pipx"
  if command -v pipx >/dev/null 2>&1; then
    log_summary "Base" "Pipx" "✅ Exists" "$(get_version pipx)" "$(($(date +%s) - _T0_PIPX))"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Pipx" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_PIPX="✅ mise"
  run_mise install pipx || _STAT_PIPX="❌ Failed"
  log_summary "Base" "Pipx" "$_STAT_PIPX" "$(get_version pipx)" "$(($(date +%s) - _T0_PIPX))"
}

# Purpose: Installs Gitleaks for secrets scanning.
# Delegate: Managed by mise (.mise.toml)
install_gitleaks() {
  local _T0_GITL
  _T0_GITL=$(date +%s)
  local _TITLE="Gitleaks"
  local _PROVIDER="gitleaks"

  if [ ! -d ".git" ]; then
    return 0
  fi

  # Fast-path: Check version-aware existence (Optimized via _G_MISE_LS_JSON)
  local _CUR_VER
  _CUR_VER=$(get_version gitleaks)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Gitleaks" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_GITL="✅ mise"
  run_mise install gitleaks || _STAT_GITL="❌ Failed"
  log_summary "Base" "Gitleaks" "$_STAT_GITL" "$(get_version gitleaks)" "$(($(date +%s) - _T0_GITL))"
}

# Purpose: Installs Hadolint for Dockerfile linting.
# Delegate: Managed by mise (.mise.toml)
install_hadolint() {
  local _T0_HADO
  _T0_HADO=$(date +%s)
  local _TITLE="Hadolint"
  local _PROVIDER="github:hadolint/hadolint"

  if ! has_lang_files "Dockerfile docker-compose.yml" "*.dockerfile *.Dockerfile"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version hadolint)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Docker" "Hadolint" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_HADO="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_HADO="❌ Failed"
  log_summary "Docker" "Hadolint" "$_STAT_HADO" "$(get_version hadolint)" "$(($(date +%s) - _T0_HADO))"
}


# Purpose: Installs checkmake for Makefile linting.
# Delegate: Managed by mise (.mise.toml)
install_checkmake() {
  local _T0_CM
  _T0_CM=$(date +%s)
  local _TITLE="Checkmake"
  local _PROVIDER="checkmake"

  if ! has_lang_files "Makefile" "*.make"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version checkmake)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Checkmake" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_CM="✅ mise"
  run_mise install checkmake || _STAT_CM="❌ Failed"
  log_summary "Base" "Checkmake" "$_STAT_CM" "$(get_version checkmake)" "$(($(date +%s) - _T0_CM))"
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
  # 2. Fast-path: Check if hooks already exist
  if [ -f ".git/hooks/pre-commit" ]; then
    log_summary "Base" "Hooks" "✅ Activated" "4.5.1" "0"
    return 0
  fi

  # 3. Action Required (Real or Preview)
  _log_setup "Pre-commit Hooks" "pipx:pre-commit"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Hooks" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_HOOK="✅ Activated"
  install_runtime_hooks || _STAT_HOOK="❌ Failed"

  local _DUR_HOOK
  _DUR_HOOK=$(($(date +%s) - _T0_HOOK))
  log_summary "Base" "Hooks" "$_STAT_HOOK" "$(get_version pre-commit --version)" "$_DUR_HOOK"
}



# Purpose: Installs google-java-format for Java project linting.
# Delegate: Managed by mise (.mise.toml)
# WARNING: google-java-format has no prebuilt binary for linux/arm64.
#          On ARM64 Linux, this step is skipped. Use: java -jar google-java-format.jar



# Purpose: Installs osv-scanner for vulnerability scanning.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — heavy and slow. Skipped on local environments.
install_osv_scanner() {
  local _T0_OSV
  _T0_OSV=$(date +%s)
  local _TITLE="osv-scanner"
  local _PROVIDER="github:google/osv-scanner"
  if ! is_ci_env; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version osv-scanner)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Security" "osv-scanner" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "osv-scanner" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_OSV="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_OSV="❌ Failed"
  log_summary "Security" "osv-scanner" "$_STAT_OSV" "$(get_version osv-scanner)" "$(($(date +%s) - _T0_OSV))"
}

# Purpose: Installs lychee for broken link checking.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — network intensive. Skipped on local environments.
install_lychee() {
  local _T0_LYCH
  _T0_LYCH=$(date +%s)
  local _TITLE="lychee"
  local _PROVIDER="github:lycheeverse/lychee"
  if ! is_ci_env; then
    log_summary "Docs" "lychee" "⏭️ Local skip" "-" "0"
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version lychee)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Docs" "lychee" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Docs" "lychee" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_LYCH="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_LYCH="❌ Failed"
  log_summary "Docs" "lychee" "$_STAT_LYCH" "$(get_version lychee)" "$(($(date +%s) - _T0_LYCH))"
}

# Purpose: Installs Trivy for security scanning.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — heavy and slow. Skipped on local environments.
install_trivy() {
  local _T0_TRIV
  _T0_TRIV=$(date +%s)
  local _TITLE="Trivy"
  local _PROVIDER="github:aquasecurity/trivy"
  if ! is_ci_env; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version trivy)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Security" "Trivy" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "Trivy" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_TRIV="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TRIV="❌ Failed"
  log_summary "Security" "Trivy" "$_STAT_TRIV" "$(get_version trivy)" "$(($(date +%s) - _T0_TRIV))"
}




# Purpose: Installs zizmor for GitHub Actions auditing.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — security audit. Skipped on local environments.
install_zizmor() {
  local _T0_ZIZ
  _T0_ZIZ=$(date +%s)
  local _TITLE="Zizmor"
  local _PROVIDER="pipx:zizmor"
  if ! is_ci_env; then
    return 0
  fi

  if ! has_lang_files ".github/workflows" "*.yml *.yaml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version zizmor)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Security" "Zizmor" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Security" "Zizmor" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_ZIZ="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ZIZ="❌ Failed"
  log_summary "Security" "Zizmor" "$_STAT_ZIZ" "$(get_version zizmor)" "$(($(date +%s) - _T0_ZIZ))"
}

# Purpose: Installs cargo-audit for Rust projects.
# Delegate: Managed by mise (.mise.toml)
# NOTE: CI-only tool — security audit. Skipped on local environments.
install_cargo_audit() {
  local _T0_CRGO
  _T0_CRGO=$(date +%s)
  local _TITLE="Cargo-Audit"
  local _PROVIDER="cargo:cargo-audit"
  if ! is_ci_env; then
    return 0
  fi

  if ! has_lang_files "Cargo.toml Cargo.lock" "*.rs"; then
    return 0
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version cargo-audit)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Rust" "Cargo-Audit" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Rust" "Cargo-Audit" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_CRGO="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_CRGO="❌ Failed"
  log_summary "Rust" "Cargo-Audit" "$_STAT_CRGO" "$(get_version cargo-audit)" "$(($(date +%s) - _T0_CRGO))"
}


# Purpose: Installs Shfmt.
# Delegate: Managed by mise (.mise.toml)
install_shfmt() {
  local _T0_SHF
  _T0_SHF=$(date +%s)
  local _TITLE="Shfmt"
  local _PROVIDER="pipx:shfmt-py"

  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version shfmt "" "shfmt-py")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "pipx:shfmt-py")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Shfmt" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SHF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SHF="❌ Failed"
  log_summary "Base" "Shfmt" "$_STAT_SHF" "$(get_version shfmt)" "$(($(date +%s) - _T0_SHF))"
}

# Purpose: Installs Shellcheck.
# Delegate: Managed by mise (.mise.toml)
install_shellcheck() {
  local _T0_SHC
  _T0_SHC=$(date +%s)
  local _TITLE="Shellcheck"
  local _PROVIDER="pipx:shellcheck-py"

  if ! has_lang_files "" "*.sh *.bash *.bats"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version shellcheck "" "shellcheck-py")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "pipx:shellcheck-py")

  # Special Case: Shellcheck version check can be 'latest'
  if [ "$_CUR_VER" != "-" ]; then
    if [ "$_CUR_VER" = "$_REQ_VER" ] || [ "$_REQ_VER" = "latest" ]; then
      log_summary "Base" "Shellcheck" "✅ Exists" "$_CUR_VER" "0"
      return 0
    fi
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_SHC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SHC="❌ Failed"
  log_summary "Base" "Shellcheck" "$_STAT_SHC" "$(get_version shellcheck)" "$(($(date +%s) - _T0_SHC))"
}

# Purpose: Installs Actionlint.
# Delegate: Managed by mise (.mise.toml)
install_actionlint() {
  local _T0_ACT
  _T0_ACT=$(date +%s)
  local _TITLE="Actionlint"
  local _PROVIDER="pipx:actionlint-py"
  if ! has_lang_files ".github/workflows" "*.yml *.yaml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version actionlint "" "actionlint-py")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Actionlint" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Actionlint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_ACT="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ACT="❌ Failed"
  log_summary "Base" "Actionlint" "$_STAT_ACT" "$(get_version actionlint)" "$(($(date +%s) - _T0_ACT))"
}

# Purpose: Installs Taplo.
# Delegate: Managed by mise (.mise.toml)
install_taplo() {
  local _T0_TAP
  _T0_TAP=$(date +%s)
  local _TITLE="Taplo"
  local _PROVIDER="npm:@taplo/cli"
  if ! has_lang_files "" "*.toml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version taplo "" "@taplo/cli")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Taplo" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Taplo" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_TAP="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TAP="❌ Failed"
  log_summary "Base" "Taplo" "$_STAT_TAP" "$(get_version taplo)" "$(($(date +%s) - _T0_TAP))"
}

# Purpose: Installs Prettier.
# Delegate: Managed by mise (.mise.toml)
install_prettier() {
  local _T0_PRE
  _T0_PRE=$(date +%s)
  local _TITLE="Prettier"
  local _PROVIDER="npm:prettier"
  if ! has_lang_files "" "*.json *.yaml *.yml *.vue *.js *.ts *.jsx *.tsx"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version prettier)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Prettier" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Prettier" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_PRE="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_PRE="❌ Failed"
  log_summary "Base" "Prettier" "$_STAT_PRE" "$(get_version prettier)" "$(($(date +%s) - _T0_PRE))"
}



# Purpose: Installs spectral for API linting.
# Delegate: Managed by mise (.mise.toml)
install_spectral() {
  local _T0_SPEC
  _T0_SPEC=$(date +%s)
  local _TITLE="Spectral"
  local _PROVIDER="npm:@stoplight/spectral-cli"
  if ! has_lang_files "" "openapi.yaml openapi.json *.openapi.yaml *.openapi.json"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version spectral)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Spectral" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "API" "Spectral" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_SPEC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_SPEC="❌ Failed"
  log_summary "Base" "Spectral" "$_STAT_SPEC" "$(get_version spectral)" "$(($(date +%s) - _T0_SPEC))"
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
  if [ ! -d ".git" ]; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version commitlint "" "@commitlint/cli")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  # Robust matching: Exact or contains (to handle @commitlint/cli@ prefix if cleanup fails)
  if [ "$_CUR_VER" != "-" ] && ([ "$_CUR_VER" = "$_REQ_VER" ] || echo "$_CUR_VER" | grep -q "$_REQ_VER"); then
    log_summary "Base" "Commitlint" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Commitlint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_CL="✅ mise"
  run_mise install "$_PROVIDER" "$_CONFIG_PROVIDER" || _STAT_CL="❌ Failed"

  log_summary "Base" "Commitlint" "$_STAT_CL" "$(get_version commitlint)" "$(($(date +%s) - _T0_CL))"
}

install_dockerfile_utils() {
  local _T0_DU
  _T0_DU=$(date +%s)
  local _TITLE="dockerfile-utils"
  local _PROVIDER="npm:dockerfile-utils"
  if ! has_lang_files "Dockerfile" "*.dockerfile *.Dockerfile"; then
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Docker" "dockerfile-utils" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_DU="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_DU="❌ Failed"
  log_summary "Docker" "dockerfile-utils" "$_STAT_DU" "$(get_version dockerfile-utils)" "$(($(date +%s) - _T0_DU))"
}




install_yamllint() {
  local _T0_YL
  _T0_YL=$(date +%s)
  local _TITLE="Yamllint"
  local _PROVIDER="pipx:yamllint"
  if ! has_lang_files ".yamllint .yamllint.yml" "*.yaml *.yml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version "yamllint" "")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "pipx:yamllint")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Yamllint" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Yamllint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_YL="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_YL="❌ Failed"
  log_summary "Base" "Yamllint" "$_STAT_YL" "$(get_version yamllint)" "$(($(date +%s) - _T0_YL))"
}

install_sqlfluff() {
  local _T0_SQL
  _T0_SQL=$(date +%s)
  local _TITLE="Sqlfluff"
  local _PROVIDER="sqlfluff"
  if ! has_lang_files ".sqlfluff" "*.sql"; then
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "SQL" "Sqlfluff" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_SQL="✅ mise"
  run_mise install sqlfluff || _STAT_SQL="❌ Failed"
  log_summary "SQL" "Sqlfluff" "$_STAT_SQL" "$(get_version sqlfluff)" "$(($(date +%s) - _T0_SQL))"
}

install_markdownlint() {
  local _T0_MD
  _T0_MD=$(date +%s)
  local _TITLE="Markdownlint"
  local _PROVIDER="npm:markdownlint-cli2"
  if ! has_lang_files "" "*.md"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version "markdownlint-cli2" "", "markdownlint-cli2")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "npm:markdownlint-cli2")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Markdownlint" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Markdownlint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_MD="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_MD="❌ Failed"
  log_summary "Base" "Markdownlint" "$_STAT_MD" "$(get_version markdownlint-cli2)" "$(($(date +%s) - _T0_MD))"
}

install_dotenv_linter() {
  local _T0_DOT
  _T0_DOT=$(date +%s)
  local _TITLE="dotenv-linter"
  local _PROVIDER="pipx:dotenv-linter"
  if ! has_lang_files ".env .env.example" "*.env"; then
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "dotenv-linter" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_DOT="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_DOT="❌ Failed"
  log_summary "Base" "dotenv-linter" "$_STAT_DOT" "$(get_version dotenv-linter)" "$(($(date +%s) - _T0_DOT))"
}

install_bats() {
  local _T0_BATS
  _T0_BATS=$(date +%s)
  local _TITLE="Bats"
  local _PROVIDER="npm:bats"
  if ! has_lang_files "" "*.bats"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version "bats" "")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Shell" "Bats" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Shell" "Bats" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_BATS="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_BATS="❌ Failed"
  log_summary "Shell" "Bats" "$_STAT_BATS" "$(get_version bats --version)" "$(($(date +%s) - _T0_BATS))"
}

# Purpose: Vendors bats-support and bats-assert for tests.
install_bats_libs() {
  local _T0_BL
  _T0_BL=$(date +%s)
  local _TITLE="Bats Libraries"
  local _PROVIDER="github:bats-core"

  if ! has_lang_files "" "*.bats"; then
    return 0
  fi
  # Fast-path: Check if libraries already exist in vendor
  if [ -d "vendor/bats-support" ] && [ -d "vendor/bats-assert" ]; then
    log_summary "Shell" "Bats-Libs" "✅ Vendored" "v0.3.0/v2.1.0" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Shell" "Bats-Libs" '⚖️ Previewed' "-" '0'
    return 0
  fi

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

  log_summary "Shell" "Bats-Libs" "✅ Vendored" "v0.3.0/v2.1.0" "$(($(date +%s) - _T0_BL))"
}






# Purpose: Installs pre-commit.
# Delegate: Managed by mise (.mise.toml)
install_pre_commit() {
  local _T0_PC
  _T0_PC=$(date +%s)
  local _TITLE="Pre-commit"
  local _PROVIDER="pipx:pre-commit"

  if [ "${_PRE_COMMIT_INSTALLED:-false}" = "true" ]; then
    return 0
  fi
  _PRE_COMMIT_INSTALLED="true"
  if [ ! -f ".pre-commit-config.yaml" ]; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version "pre-commit" "")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "Pre-commit" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Pre-commit" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_PC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_PC="❌ Failed"
  log_summary "Base" "Pre-commit" "$_STAT_PC" "$(get_version pre-commit --version)" "$(($(date +%s) - _T0_PC))"
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
  if ! has_lang_files ".editorconfig" ""; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version editorconfig-checker)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Base" "editorconfig-checker" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "editorconfig-checker" '⚖️ Previewed' "-" '0'
    return 0
  fi
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
  log_summary "Base" "editorconfig-checker" "$_STAT_ECC" "$(get_version editorconfig-checker)" "$(($(date +%s) - _T0_ECC))"
}


# Purpose: Installs buf for Protobuf linting/management.
# Delegate: Managed by mise (.mise.toml)
install_buf() {
  local _T0_BUF
  _T0_BUF=$(date +%s)
  local _TITLE="Buf"
  local _PROVIDER="github:bufbuild/buf"
  if ! has_lang_files "" "PROTOC"; then
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Protobuf" "Buf" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_BUF="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_BUF="❌ Failed"
  log_summary "Protobuf" "Buf" "$_STAT_BUF" "$(get_version buf --version)" "$(($(date +%s) - _T0_BUF))"
}

# Purpose: Installs Just (modern runner).
# Delegate: Managed by mise (.mise.toml)
install_just() {
  local _T0_JUST
  _T0_JUST=$(date +%s)
  local _TITLE="Just"
  local _PROVIDER="github:casey/just"
  if ! has_lang_files "" "JUST"; then
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Just" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_JUST="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_JUST="❌ Failed"
  log_summary "Base" "Just" "$_STAT_JUST" "$(get_version just --version)" "$(($(date +%s) - _T0_JUST))"
}

# Purpose: Installs Task (modern runner).
# Delegate: Managed by mise (.mise.toml)
install_task() {
  local _T0_TASK
  _T0_TASK=$(date +%s)
  local _TITLE="Task"
  local _PROVIDER="github:go-task/task"
  if ! has_lang_files "" "TASK"; then
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Task" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_TASK="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TASK="❌ Failed"
  log_summary "Base" "Task" "$_STAT_TASK" "$(get_version task --version)" "$(($(date +%s) - _T0_TASK))"
}

# Purpose: Installs CUE and Jsonnet.
# Delegate: Managed by mise (.mise.toml)
install_cue() {
  local _T0_CUE
  _T0_CUE=$(date +%s)
  local _TITLE="CUE/Jsonnet"
  local _PROVIDER="github:cue-lang/cue"
  if ! has_lang_files "" "CUES"; then
    return 0
  fi

  _log_setup "$_TITLE" "cue/jsonnet"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "CUE" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_CUE="✅ mise"
  run_mise install "$_PROVIDER" "github:google/go-jsonnet" || _STAT_CUE="❌ Failed"
  log_summary "Base" "CUE/Jsonnet" "$_STAT_CUE" "$(get_version cue version | head -n 1)" "$(($(date +%s) - _T0_CUE))"
}


# Purpose: Checks for Edge deployment configurations.
install_edge() {
  if ! has_lang_files "" "EDGE"; then
    return 0
  fi
  log_summary "Config" "Edge" "✅ Detected" "-" "0"
}

install_rn() {
  if ! has_lang_files "" "RN"; then
    return 0
  fi
  log_summary "Mobile" "React Native" "✅ Detected" "-" "0"
}

install_crossplane() {
  if ! has_lang_files "" "CROSSPLANE"; then
    return 0
  fi
  log_summary "IaC" "Crossplane" "✅ Detected" "-" "0"
}

install_playwright() {
  if ! has_lang_files "" "PLAYWRIGHT"; then
    return 0
  fi
  log_summary "Testing" "Playwright" "✅ Detected" "-" "0"
}

install_cypress() {
  if ! has_lang_files "" "CYPRESS"; then
    return 0
  fi
  log_summary "Testing" "Cypress" "✅ Detected" "-" "0"
}

install_vitest() {
  if ! has_lang_files "" "VITEST"; then
    return 0
  fi
  log_summary "Testing" "Vitest" "✅ Detected" "-" "0"
}

install_docusaurus() {
  if ! has_lang_files "" "DOCUSAURUS"; then
    return 0
  fi
  log_summary "Docs" "Docusaurus" "✅ Detected" "-" "0"
}

install_mkdocs() {
  if ! has_lang_files "" "MKDOCS"; then
    return 0
  fi
  log_summary "Docs" "MkDocs" "✅ Detected" "-" "0"
}

install_sphinx() {
  if ! has_lang_files "" "SPHINX"; then
    return 0
  fi
  log_summary "Docs" "Sphinx" "✅ Detected" "-" "0"
}

install_jupyter() {
  if ! has_lang_files "" "JUPYTER"; then
    return 0
  fi
  log_summary "AI/Data" "Jupyter" "✅ Detected" "-" "0"
}

install_dvc() {
  if ! has_lang_files "" "DVC"; then
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

      # Detect Go/Rust even if not explicitly setup (Safe version check)
      local _V_GO_DET
      _V_GO_DET=$(get_version go)
      if [ "$_V_GO_DET" != "-" ]; then
        log_summary "Runtime" "Go" "✅ Detected" "$_V_GO_DET" "0"
      fi

      local _V_RS_DET
      _V_RS_DET=$(get_version cargo)
      if [ "$_V_RS_DET" != "-" ]; then
        log_summary "Runtime" "Rust" "✅ Detected" "$_V_RS_DET" "0"
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
    # Grouped list for "On-demand" (default) or "All" (explicit)
    # 1. Base Tools (Universal Lint/Format/Task)
    local _BASE_LIST="pipx gitleaks checkmake editorconfig-checker shfmt shellcheck actionlint taplo prettier commitlint commitizen pre-commit hooks cue yamllint markdownlint dotenv-linter just task sort-package-json stylua clang-format"
    # 2. Language Runtimes & Specific Toolsets
    local _LANG_LIST="node python go rust java kotlin php ruby dart swift lua perl julia r groovy dotnet zig elixir haskell scala"
    # 3. Domain Tools (Security, IaC, Platforms, Testing, Docs, AI, etc.)
    local _DOMAIN_LIST="osv-scanner trivy zizmor govulncheck cargo-audit pip-audit rego hadolint tflint kube-linter tofu pulumi crossplane spectral buf goreleaser playwright cypress vitest bats bats-libs vitepress docusaurus mkdocs sphinx jupyter dvc rn ruff eslint stylelint sqlfluff ktlint dockerfile-utils"

    _MODULES_LIST="${_BASE_LIST} ${_LANG_LIST} ${_DOMAIN_LIST}"
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
  # ── Execution Loop ──
  local _cur_grp=""
  for _cur_module in $_MODULES_LIST; do
    # Visual Grouping Headers for 'All' mode
    # Visual Grouping Headers for 'All' mode (prints before the first active module in each category)
    if [ "$_IS_ALL_MODULES" = "true" ]; then
      case " ${_BASE_LIST} " in *" ${_cur_module} "*)
        [ "$_cur_grp" != "base" ] && log_info "── Base Toolset ──" && _cur_grp="base"
        ;;
      esac
      case " ${_LANG_LIST} " in *" ${_cur_module} "*)
        [ "$_cur_grp" != "lang" ] && log_info "── Language Toolsets ──" && _cur_grp="lang"
        ;;
      esac
      case " ${_DOMAIN_LIST} " in *" ${_cur_module} "*)
        [ "$_cur_grp" != "domain" ] && log_info "── Domain Toolsets ──" && _cur_grp="domain"
        ;;
      esac
    fi

    case $_cur_module in
    node) setup_node ;;
    python) setup_python ;;
    go) setup_go ;;
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
    govulncheck) setup_go ;;
    cargo-audit) install_cargo_audit ;;
    security) setup_security ;;
    shfmt) install_shfmt ;;
    shellcheck) install_shellcheck ;;
    actionlint) install_actionlint ;;
    taplo) install_taplo ;;
    prettier) install_prettier ;;
    buf) install_buf ;;
    tofu) setup_tofu ;;
    just) install_just ;;
    task) install_task ;;
    zig) setup_zig ;;
    rego) setup_rego ;;
    edge) install_edge ;;
    pulumi) setup_pulumi ;;
    crossplane) install_crossplane ;;
    elixir) setup_elixir ;;
    haskell) setup_haskell ;;
    scala) setup_scala ;;
    pre-commit) install_pre_commit ;;
    hooks) setup_hooks ;;
    pipx) install_pipx ;;
    gitleaks) install_gitleaks ;;
    checkmake) install_checkmake ;;
    hadolint) install_hadolint ;;
    tflint) setup_terraform ;;
    kube-linter) setup_helm ;;
    editorconfig-checker) install_editorconfig_checker ;;
    sort-package-json) setup_node ;;
    goreleaser) setup_go ;;
    spectral) install_spectral ;;
    commitlint) install_commitlint ;;
    dockerfile-utils) install_dockerfile_utils ;;
    clang-format) setup_cpp ;;
    ktlint) setup_kotlin ;;
    ruff) setup_python ;;
    stylelint) setup_node ;;
    yamllint) install_yamllint ;;
    sqlfluff) install_sqlfluff ;;
    markdownlint) install_markdownlint ;;
    dotenv-linter) install_dotenv_linter ;;
    bats) install_bats ;;
    bats-libs) install_bats_libs ;;
    eslint) setup_node ;;
    vitepress) setup_node ;;
    commitizen) setup_node ;;
    pip-audit) setup_python ;;
    stylua) setup_lua ;;
    cue) install_cue ;;
    rn) install_rn ;;
    playwright) install_playwright ;;
    cypress) install_cypress ;;
    vitest) install_vitest ;;
    docusaurus) install_docusaurus ;;
    mkdocs) install_mkdocs ;;
    sphinx) install_sphinx ;;
    jupyter) install_jupyter ;;
    dvc) install_dvc ;;
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

main "$@"
