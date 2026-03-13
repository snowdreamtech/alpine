#!/bin/sh
# scripts/lib/common.sh - Shared utility library for automation scripts.
#
# Purpose:
#   Provides centralized configuration, logging, and helper functions
#   used across the project's orchestration layer.
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General, Network), Rule 03 (Architecture), Rule 09 (Interaction).
#
# Features:
#   - Standardized colored logging (info, success, warn, error).
#   - Robust downloading with retry and proxy logic.
#   - Operation throttling (24h cooldown for heavy tasks).
#   - Build-then-Swap atomic file operations.
#   - Dual-Sentinel (双重哨兵) pattern for CI reporting.
#
# shellcheck disable=SC2034

# ── 🎨 Visual Assets ─────────────────────────────────────────────────────────

# Colors (using printf to generate literal ESC characters for maximum compatibility)
BLUE=$(printf '\033[0;34m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
RED=$(printf '\033[0;31m')
NC=$(printf '\033[0m')

# ── ⚙️ Global Configuration ──────────────────────────────────────────────────

# Default verbosity
# shellcheck disable=SC2034
VERBOSE=${VERBOSE:-1} # 0: quiet, 1: normal, 2: verbose
DRY_RUN=${DRY_RUN:-0}

# Enforce Non-Interactive Mode (For CI/CD and Headless Setup)
# These prevent 'mise' and 'uv' from asking for user confirmation or trust prompts.
# Ref: Rule 01 (General), Rule 08 (Dev Env)
export MISE_YES=true
export MISE_NON_INTERACTIVE=true
export UV_NON_INTERACTIVE=true

# Orchestration tracking (detect if we are running as a sub-script)
if [ -z "$_SNOWDREAM_TOP_LEVEL_SCRIPT" ]; then
  _SCRIPT_NAME=$(basename "$0")
  export _SNOWDREAM_TOP_LEVEL_SCRIPT="$_SCRIPT_NAME"
  _IS_TOP_LEVEL=true
else
  _IS_TOP_LEVEL=false
fi

# ── 📄 SSoT Constants (Paths and Files) ──────────────────────────────────────

CHANGELOG="CHANGELOG.md"
PACKAGE_JSON="package.json"
CARGO_TOML="Cargo.toml"
PYPROJECT_TOML="pyproject.toml"
VERSION_FILE="VERSION"
REQUIREMENTS_TXT="requirements-dev.txt"
VENV="${VENV:-.venv}"
PYTHON="${PYTHON:-python3}"
NPM="${NPM:-pnpm}"
GORELEASER="${GORELEASER:-goreleaser}"
LOCK_DIR=".archival_lock"
DOCS_DIR="docs"
# shellcheck disable=SC2034
ARCHIVE_DIR="${ARCHIVE_DIR:-.}"
GITHUB_PROXY="${GITHUB_PROXY:-https://gh-proxy.sn0wdr1am.com/}"

# Network Optimization & Mirror Configuration
_TEMP_GIT_CONFIG="/tmp/.git_config_$(id -u)"
ENABLE_MIRROR="${ENABLE_MIRROR:-${MIRROR:-${USE_MIRROR:-0}}}"
MIRROR_NODEJS="${MIRROR_NODEJS:-https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/}"
MIRROR_PYTHON="${MIRROR_PYTHON:-https://mirrors.tuna.tsinghua.edu.cn/python/}"
MIRROR_NPM="${MIRROR_NPM:-https://registry.npmmirror.com}"
MIRROR_PNPM="${MIRROR_PNPM:-https://registry.npmmirror.com/pnpm/}" # pnpm binary mirror
MIRROR_GO="${MIRROR_GO:-https://goproxy.cn,direct}"
MIRROR_RUST_DIST="${MIRROR_RUST_DIST:-https://mirrors.ustc.edu.cn/rust-static}"
MIRROR_RUST_UPDATE="${MIRROR_RUST_UPDATE:-https://mirrors.ustc.edu.cn/rust-static/rustup}"

# ── 🔨 SSoT Tool Versions ────────────────────────────────────────────────────

PYTHON_VERSION="${PYTHON_VERSION:-3.12.9}"
NODE_VERSION="${NODE_VERSION:-20.18.3}"
NPM_VERSION="${NPM_VERSION:-10.5.2}"
# Tool chain management
MISE_VERSION="${MISE_VERSION:-2026.3.8}"
UV_VERSION="${UV_VERSION:-0.10.9}"
GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.30.0}"
HADOLINT_VERSION="${HADOLINT_VERSION:-2.14.0}"
GOLANGCI_VERSION="${GOLANGCI_VERSION:-1.64.5}"
CHECKMAKE_VERSION="${CHECKMAKE_VERSION:-0.3.2}"
TFLINT_VERSION="${TFLINT_VERSION:-0.61.0}"
KUBE_LINTER_VERSION="${KUBE_LINTER_VERSION:-0.8.1}"
SHFMT_VERSION="${SHFMT_VERSION:-3.12.0}"
SHELLCHECK_VERSION="${SHELLCHECK_VERSION:-0.10.0}"
ZIZMOR_VERSION="${ZIZMOR_VERSION:-1.3.1}"
ACTIONLINT_VERSION="${ACTIONLINT_VERSION:-1.7.11}"
JAVA_FORMAT_VERSION="${JAVA_FORMAT_VERSION:-1.34.1}"
PHP_CS_FIXER_VERSION="${PHP_CS_FIXER_VERSION:-3.94.2}"
OSV_SCANNER_VERSION="${OSV_SCANNER_VERSION:-2.3.2}"
TRIVY_VERSION="${TRIVY_VERSION:-0.69.3}"
EDITORCONFIG_CHECKER_VERSION="${EDITORCONFIG_CHECKER_VERSION:-3.6.1}"
GHT_VERSION="${GHT_VERSION:-1.2.0}"

# Export versions for sub-shells
export GITLEAKS_VERSION HADOLINT_VERSION GOLANGCI_VERSION CHECKMAKE_VERSION
export TFLINT_VERSION KUBE_LINTER_VERSION SHFMT_VERSION SHELLCHECK_VERSION
export ZIZMOR_VERSION ACTIONLINT_VERSION JAVA_FORMAT_VERSION PHP_CS_FIXER_VERSION
export OSV_SCANNER_VERSION TRIVY_VERSION EDITORCONFIG_CHECKER_VERSION

# ── 🛣️ PATH Augmentation ──────────────────────────────────────────────────────

# Automatically add local bin directories to PATH to ensure orchestrated tools
# are prioritized over system globals without requiring manual activation.
_LOCAL_BIN_VENV=$(pwd)/${VENV}/bin
_LOCAL_BIN_NODE=$(pwd)/node_modules/.bin
_LOCAL_MISE_BIN="$HOME/.local/bin"

if [ -d "$_LOCAL_MISE_BIN" ]; then
  case ":$PATH:" in
  *":$_LOCAL_MISE_BIN:"*) ;;
  *) export PATH="$_LOCAL_MISE_BIN:$PATH" ;;
  esac
fi

if [ -d "$_LOCAL_BIN_VENV" ]; then
  case ":$PATH:" in
  *":$_LOCAL_BIN_VENV:"*) ;;
  *) export PATH="$_LOCAL_BIN_VENV:$PATH" ;;
  esac
fi

if [ -d "$_LOCAL_BIN_NODE" ]; then
  case ":$PATH:" in
  *":$_LOCAL_BIN_NODE:"*) ;;
  *) export PATH="$_LOCAL_BIN_NODE:$PATH" ;;
  esac
fi

# ── 🪄 Mise Bootstrap ────────────────────────────────────────────────────────

# Purpose: Ensures mise is installed and available in the environment.
#          Downloads the standalone binary if missing (cross-platform).
# Examples:
#   bootstrap_mise
# Internal helper to detect the current user shell.
_mise_detect_shell() {
  local _M_SHELL="bash"
  local _PARENT_SHELL
  _PARENT_SHELL=$(ps -p "$PPID" -o comm= 2>/dev/null | awk -F/ '{print $NF}' | tr -d '-')

  case "$_PARENT_SHELL" in
  zsh | bash | fish) _M_SHELL="$_PARENT_SHELL" ;;
  *)
    case "$SHELL" in
    *zsh*) _M_SHELL="zsh" ;;
    *bash*) _M_SHELL="bash" ;;
    *fish*) _M_SHELL="fish" ;;
    *) _M_SHELL="bash" ;;
    esac
    ;;
  esac
  echo "$_M_SHELL"
}

# Internal helper to detect the CPU architecture.
_mise_detect_arch() {
  local _OS="$1"
  local _ARCH
  _ARCH=$(uname -m)
  case "$_ARCH" in
  x86_64 | amd64) _ARCH="x64" ;;
  arm64 | aarch64) _ARCH="arm64" ;;
  armv7*) _ARCH="armv7" ;;
  *) _ARCH="x64" ;;
  esac

  if [ "$_OS" = "linux" ]; then
    # Detect musl libc (common in Alpine and minimal Docker images)
    if (ldd "$(command -v ls)" 2>&1 | grep -q "musl") || [ -f /lib/ld-musl-x86_64.so.1 ] || [ -f /lib/ld-musl-aarch64.so.1 ] || [ -f /lib/ld-musl-armhf.so.1 ]; then
      _ARCH="${_ARCH}-musl"
    fi
  fi
  echo "$_ARCH"
}

# Internal helper to detect the OS type.
_mise_detect_os() {
  case "$(uname -s)" in
  Darwin) echo "macos" ;;
  Linux) echo "linux" ;;
  MINGW* | MSYS* | CYGWIN*) echo "windows" ;;
  *) echo "linux" ;;
  esac
}

# Tier 1: Shell-specific streamers (mise.run) - Includes auto-activation.
_mise_install_tier1() {
  local _SHELL="$1"
  log_info "Tier 1: Trying official shell-specific streamer for ${_SHELL}..."
  if curl -sS -L "https://mise.run/${_SHELL}" | sh; then
    return 0
  fi
  return 1
}

# Tier 2: System Package Managers.
_mise_install_tier2() {
  log_info "Tier 2: Searching for system package managers..."
  if command -v brew >/dev/null 2>&1; then
    log_info "Detected Homebrew. Installing mise..."
    brew install mise && return 0
  elif command -v port >/dev/null 2>&1; then
    log_info "Detected MacPorts. Installing mise..."
    sudo port install mise && return 0
  elif command -v apk >/dev/null 2>&1; then
    log_info "Detected apk. Installing mise..."
    sudo apk add mise && return 0
  elif command -v apt-get >/dev/null 2>&1; then
    log_info "Detected apt. Installing mise..."
    sudo apt-get update && sudo apt-get install -y mise && return 0
  elif command -v dnf >/dev/null 2>&1; then
    log_info "Detected dnf. Installing mise..."
    sudo dnf install -y mise && return 0
  elif command -v pacman >/dev/null 2>&1; then
    log_info "Detected pacman. Installing mise..."
    sudo pacman -S --noconfirm mise && return 0
  elif command -v nix-env >/dev/null 2>&1; then
    log_info "Detected nix. Installing mise..."
    nix-env -iA mise && return 0
  elif command -v yum >/dev/null 2>&1; then
    log_info "Detected yum. Installing mise..."
    sudo yum install -y mise && return 0
  elif command -v zypper >/dev/null 2>&1; then
    log_info "Detected zypper. Installing mise..."
    sudo zypper install -y mise && return 0
  fi
  return 1
}

# Tier 3: Language-specific tools.
_mise_install_tier3() {
  log_info "Tier 3: Searching for language-specific tools..."
  if command -v cargo >/dev/null 2>&1; then
    log_info "Detected Cargo. Installing mise..."
    cargo install mise && return 0
  elif command -v npm >/dev/null 2>&1; then
    log_info "Detected npm. Installing mise..."
    # npm install -g might fail due to permissions, but we try.
    npm install -g @jdxcode/mise && return 0
  fi
  return 1
}

# Tier 4: Manual Binary Download (GitHub Releases).
_mise_install_tier4() {
  local _OS="$1"
  local _ARCH="$2"
  local _VER="$3"
  log_info "Tier 4: Performing manual binary download for ${_OS}-${_ARCH} (v${_VER})..."

  local _M_BIN_NAME="mise-v${_VER}-${_OS}-${_ARCH}"
  local _EXT=""
  [ "$_OS" = "windows" ] && _EXT=".zip"
  local _M_URL="https://github.com/jdx/mise/releases/download/v${_VER}/${_M_BIN_NAME}${_EXT}"
  local _DEST="$HOME/.local/bin/mise"
  [ "$_OS" = "windows" ] && _DEST="${_DEST}.exe"

  mkdir -p "$(dirname "$_DEST")"

  if [ "$_OS" = "windows" ]; then
    local _TMP_ZIP="/tmp/mise_win.zip"
    local _TMP_DIR="/tmp/mise_win_extract"
    if download_url "$_M_URL" "$_TMP_ZIP"; then
      rm -rf "$_TMP_DIR" && mkdir -p "$_TMP_DIR"
      if unzip -q "$_TMP_ZIP" -d "$_TMP_DIR"; then
        mv "$_TMP_DIR/mise/bin/mise.exe" "$_DEST"
        mv "$_TMP_DIR/mise/bin/mise-shim.exe" "$(dirname "$_DEST")/mise-shim.exe" 2>/dev/null || true
        rm -rf "$_TMP_DIR" "$_TMP_ZIP"
        return 0
      fi
    fi
  else
    if download_url "$_M_URL" "$_DEST"; then
      chmod +x "$_DEST"
      return 0
    fi
  fi
  return 1
}

# Setup shell completions.
_mise_setup_completions() {
  local _SHELL="$1"
  log_info "Setting up mise completions for ${_SHELL}..."

  case "$_SHELL" in
  zsh)
    local _DIR="${ZDOTDIR-$HOME}/.zsh/completions"
    mkdir -p "$_DIR"
    mise completion zsh >"$_DIR/_mise" 2>/dev/null || true
    ;;
  bash)
    local _DIR="$HOME/.local/share/bash-completion/completions"
    mkdir -p "$_DIR"
    mise completion bash >"$_DIR/mise" 2>/dev/null || true
    ;;
  fish)
    local _DIR="$HOME/.config/fish/completions"
    mkdir -p "$_DIR"
    mise completion fish >"$_DIR/mise.fish" 2>/dev/null || true
    ;;
  esac
}

# Run mise doctor to verify health.
_mise_verify_health() {
  log_info "Verifying mise health..."
  if ! run_quiet mise doctor; then
    log_warn "mise doctor reported some issues. Please check 'mise doctor' manually."
  else
    log_success "mise health check passed."
  fi
}

# ── 🐚 Shell-Specific Activation Helpers ─────────────────────────────────────

_mise_activate_bash() {
  local _RC="$HOME/.bashrc"
  [ -f "$_RC" ] || return 0
  # shellcheck disable=SC2016
  grep -q "mise activate bash" "$_RC" || echo 'eval "$(mise activate bash)"' >>"$_RC"
}

_mise_activate_zsh() {
  local _RC="${ZDOTDIR-$HOME}/.zshrc"
  [ -f "$_RC" ] || return 0
  # shellcheck disable=SC2016
  grep -q "mise activate zsh" "$_RC" || echo 'eval "$(mise activate zsh)"' >>"$_RC"
}

_mise_activate_fish() {
  local _RC="$HOME/.config/fish/config.fish"
  mkdir -p "$(dirname "$_RC")"
  grep -q "mise activate fish" "$_RC" || echo 'mise activate fish | source' >>"$_RC"
}

_mise_activate_pwsh() {
  # Powershell profile path varies, we use a common heuristic.
  local _RC="$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
  [ -d "$(dirname "$_RC")" ] || mkdir -p "$(dirname "$_RC")"
  grep -q "mise activate pwsh" "$_RC" 2>/dev/null || echo '(&mise activate pwsh) | Out-String | Invoke-Expression' >>"$_RC"
}

_mise_activate_nu() {
  # Nushell requires env.nu and config.nu updates.
  local _NU_DIR="$HOME/.config/nushell"
  [ -d "$_NU_DIR" ] || return 0
  local _ENV="${_NU_DIR}/env.nu"
  local _CONF="${_NU_DIR}/config.nu"
  local _MISE_NU="${_NU_DIR}/mise.nu"

  if [ ! -f "$_MISE_NU" ]; then
    mise activate nu >"$_MISE_NU" 2>/dev/null || true
  fi

  # shellcheck disable=SC2016
  grep -q "mise.nu" "$_ENV" 2>/dev/null || printf "let mise_path = \$nu.default-config-dir | path join mise.nu\n^mise activate nu | save \$mise_path --force\n" >>"$_ENV"
  # shellcheck disable=SC2016
  grep -q "mise.nu" "$_CONF" 2>/dev/null || printf "use (\$nu.default-config-dir | path join mise.nu)\n" >>"$_CONF"
}

_mise_activate_xonsh() {
  local _RC="$HOME/.config/xonsh/rc.xsh"
  [ -d "$(dirname "$_RC")" ] || mkdir -p "$(dirname "$_RC")"
  # shellcheck disable=SC2016
  grep -q "mise activate xonsh" "$_RC" 2>/dev/null || echo 'execx($(mise activate xonsh))' >>"$_RC"
}

_mise_activate_elvish() {
  local _RC="$HOME/.config/elvish/rc.elv"
  [ -d "$(dirname "$_RC")" ] || mkdir -p "$(dirname "$_RC")"
  # shellcheck disable=SC2016
  grep -q "mise activate elvish" "$_RC" 2>/dev/null || echo 'eval (mise activate elvish | slurp)' >>"$_RC"
}

# Helper to ensure mise is activated in the current session and RC files.
_mise_apply_activation() {
  local _SHELL="$1"
  log_info "Synchronizing mise activation for ${_SHELL}..."

  # 1. Permanent RC File Injection
  case "$_SHELL" in
  zsh) _mise_activate_zsh ;;
  bash) _mise_activate_bash ;;
  fish) _mise_activate_fish ;;
  pwsh | powershell) _mise_activate_pwsh ;;
  nu | nushell) _mise_activate_nu ;;
  xonsh) _mise_activate_xonsh ;;
  elvish) _mise_activate_elvish ;;
  *) _mise_activate_bash ;;
  esac

  # 2. Ephemeral Session Activation
  local _M_BIN
  _M_BIN=$(command -v mise || echo "$HOME/.local/bin/mise")
  if [ -x "$_M_BIN" ]; then
    # PowerShell and Nushell activation in POSIX sh is complex/limited to shims.
    # We focus on the most impactful session update: shims.
    case "$_SHELL" in
    pwsh | powershell | nu | nushell)
      export PATH="$HOME/.local/share/mise/shims:$PATH"
      ;;
    *)
      eval "$("$_M_BIN" activate "$_SHELL" --shims)"
      ;;
    esac
    log_debug "mise environment synchronized for current session."
  fi
}

bootstrap_mise() {
  if command -v mise >/dev/null 2>&1; then
    log_debug "mise is already installed."
    _mise_apply_activation "$(_mise_detect_shell)"
    return 0
  fi

  log_info "mise not found. Initiating multi-tier prioritized bootstrap..."
  optimize_network

  local _M_SHELL
  _M_SHELL=$(_mise_detect_shell)
  local _M_OS
  _M_OS=$(_mise_detect_os)
  local _M_ARCH
  _M_ARCH=$(_mise_detect_arch "$_M_OS")

  # Priority 1: Official Streamer (Includes auto-activation for some methods)
  if _mise_install_tier1 "$_M_SHELL"; then
    log_success "mise installed via Tier 1 (Streamer)."
  # Priority 2: System Package Managers
  elif _mise_install_tier2; then
    log_success "mise installed via Tier 2 (Package Manager)."
  # Priority 3: Language Tools
  elif _mise_install_tier3; then
    log_success "mise installed via Tier 3 (Language Tool)."
  # Priority 4: Manual Binary Fallback
  elif _mise_install_tier4 "$_M_OS" "$_M_ARCH" "${MISE_VERSION#v}"; then
    log_success "mise installed via Tier 4 (Manual Binary)."
  else
    log_error "All mise installation tiers failed."
    return 1
  fi

  # ── 🏗️ Post-Install Configuration ──

  # Finalize Activation
  _mise_apply_activation "$_M_SHELL"

  # Path Refresh
  [ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

  # Setup Completions
  _mise_setup_completions "$_M_SHELL"

  # Security & Automation: Trust project config
  if [ -f ".mise.toml" ]; then
    log_info "Trusting local .mise.toml..."
    mise trust ".mise.toml" >/dev/null 2>&1 || true
  fi

  # Verify Health
  _mise_verify_health

  # Deploy uv as core dependency
  log_info "Deploying uv via mise..."
  run_mise install uv --global || log_warn "Warning: Failed to install uv via mise."
}

# ── 🌐 Network Optimization ──────────────────────────────────────────────────

# Purpose: Dynamically detects network connectivity and applies mirrors/proxies.
#          Tests access to GitHub and handles broken global git/proxy settings.
# Examples:
#   optimize_network
optimize_network() {
  if [ "$_NETWORK_OPTIMIZED" = "true" ]; then return 0; fi

  log_debug "Detecting network connectivity and global proxy health..."
  local _NEEDS_MIRROR=false
  local _GIT_INTERFERENCE=false

  # 1. Quick connectivity test to GitHub (2s timeout)
  if ! curl -Is --connect-timeout 2 --max-time 3 https://github.com >/dev/null 2>&1; then
    log_warn "Direct GitHub connectivity appears slow or restricted."
    _NEEDS_MIRROR=true
  fi

  # 2. Check for manual override
  if [ "${ENABLE_MIRROR}" = "1" ] || [ "${ENABLE_MIRROR}" = "true" ]; then
    _NEEDS_MIRROR=true
  fi

  # 3. Handle Git Interference (Bypass broken global insteadOf or dead proxies)
  # If we need mirrors OR if we suspect global git config is broken
  if [ "$_NEEDS_MIRROR" = "true" ]; then
    # Create an intelligent git override that redirects GitHub via GITHUB_PROXY
    # This prevents 'mise' plugins and other git-based tools from hanging or failing.
    log_info "Applying intelligent git proxy overrides..."
    mkdir -p "$(dirname "$_TEMP_GIT_CONFIG")"
    cat >"$_TEMP_GIT_CONFIG" <<EOF
[url "${GITHUB_PROXY}https://github.com/"]
  insteadOf = https://github.com/
EOF
    export GIT_CONFIG_GLOBAL="$_TEMP_GIT_CONFIG"
    export GIT_CONFIG_SYSTEM="/dev/null"

    # 4. Apply standard mirrors
    export ENABLE_MIRROR=1

    # Node/Python/JS Mirrors
    export NODEJS_ORG_MIRROR="${MIRROR_NODEJS}"
    export MISE_NODE_MIRROR_URL="${MIRROR_NODEJS}"
    export PYTHON_BUILD_MIRROR_URL="${MIRROR_PYTHON}"
    export NPM_CONFIG_REGISTRY="${MIRROR_NPM}"
    export YARN_REGISTRY="${MIRROR_NPM}"

    # Go & Rust mirrors (China optimization)
    export GOPROXY="${MIRROR_GO}"
    export RUSTUP_DIST_SERVER="${MIRROR_RUST_DIST}"
    export RUSTUP_UPDATE_ROOT="${MIRROR_RUST_UPDATE}"

    # Configure mise settings if mise is available
    if command -v mise >/dev/null 2>&1; then
      log_debug "Synchronizing mise mirror settings..."
      # 1. mise url_replacements (SSoT for mise network acceleration)
      run_mise settings set "url_replacements.https://github.com/" "${GITHUB_PROXY}https://github.com/"
      run_mise settings set "url_replacements.https://api.github.com/" "${GITHUB_PROXY}https://api.github.com/" || true
      run_quiet mise settings set node.mirror_url "${MIRROR_NODEJS}" || true
    fi
  fi

  export _NETWORK_OPTIMIZED=true
}

# Purpose: Executes a mise command with built-in retries and auto-proxy/mirror logic.
# Params:
#   $@ - Command and arguments for mise
# Examples:
#   run_mise install node
run_mise() {
  optimize_network
  local _MAX_RETRIES=3
  local _RETRY_COUNT=0
  local _STATUS=1

  # Propagate verbosity to mise
  local _MISE_OPTS=""
  if [ "${VERBOSE:-1}" -ge 2 ]; then
    _MISE_OPTS="--verbose"
  fi

  while [ $_RETRY_COUNT -lt $_MAX_RETRIES ]; do
    # shellcheck disable=SC2086
    if run_quiet mise $_MISE_OPTS "$@"; then
      _STATUS=0
      break
    else
      _RETRY_COUNT=$((_RETRY_COUNT + 1))
      log_warn "mise command failed (attempt $_RETRY_COUNT/$_MAX_RETRIES). Retrying..."
      sleep 1
    fi
  done

  return $_STATUS
}

# ── 📢 Standardized Logging ──────────────────────────────────────────────────

# Standardized logging functions for consistent colored output.
#
# Purpose: Log an informational message in blue.
# Params:
#   $1 - Message to log
# Examples:
#   log_info "Starting build process..."
log_info() {
  local _msg_info="$1"
  if [ "${VERBOSE:-1}" -ge 1 ]; then printf "%s%b%s\n" "$BLUE" "$_msg_info" "$NC"; fi
}

# Purpose: Log a success message in green.
# Params:
#   $1 - Message to log
# Examples:
#   log_success "Build completed successfully."
log_success() {
  local _msg_suc="$1"
  if [ "${VERBOSE:-1}" -ge 1 ]; then printf "%s%b%s\n" "$GREEN" "$_msg_suc" "$NC"; fi
}

# Purpose: Log a warning message in yellow.
# Params:
#   $1 - Message to log
# Examples:
#   log_warn "Dependency 'jq' not found. Some features may be limited."
log_warn() {
  local _msg_warn="$1"
  if [ "${VERBOSE:-1}" -ge 1 ]; then printf "%s%b%s\n" "$YELLOW" "$_msg_warn" "$NC"; fi
}

# Purpose: Log an error message in red to stderr.
# Params:
#   $1 - Message to log
# Examples:
#   log_error "Critical error: Database connection failed."
log_error() {
  local _msg_err="$1"
  printf "%s%b%s\n" "$RED" "$_msg_err" "$NC" >&2
}

# Purpose: Log a debug message if verbose level is 2 or higher.
# Params:
#   $1 - Message to log
# Examples:
#   log_debug "Temporary path: /tmp/build-123"
log_debug() {
  local _msg_dbg="$1"
  if [ "${VERBOSE:-1}" -ge 2 ]; then printf "[DEBUG] %b\n" "$_msg_dbg"; fi
}

# Purpose: Verifies that the current working directory is the project root.
#          Exit 1 if critical root files (Makefile or package.json) are missing.
# Examples:
#   guard_project_root
guard_project_root() {
  if [ ! -f "Makefile" ] && [ ! -f "package.json" ]; then
    log_error "Error: This script must be run from the project root."
    exit 1
  fi
}

# Purpose: Checks if a specific string exists in the GITHUB_STEP_SUMMARY.
#          Used as part of the Dual-Sentinel (双重哨兵) pattern.
# Params:
#   $1 - String/Pattern to search for
# Returns:
#   0 - Pattern found
#   1 - Pattern missing
# Examples:
#   if ! check_ci_summary "### Summary"; then ...; fi
check_ci_summary() {
  [ -n "$GITHUB_STEP_SUMMARY" ] && [ -f "$GITHUB_STEP_SUMMARY" ] && grep -qF "$1" "$GITHUB_STEP_SUMMARY"
}

# Purpose: Checks if a task is within its cooldown period.
# Params:
#   $1 - Task name (used for marker filename)
#   $2 - Cooldown duration in seconds (default: 86400 / 24h)
# Returns:
#   0 - Cooldown expired (update needed)
#   1 - Within cooldown (skip update)
# Examples:
#   if check_update_cooldown "brew" 86400; then update_brew; fi
check_update_cooldown() {
  local _NAME_COOL="$1"
  local _DURATION_COOL="${2:-86400}" # Default: 24h
  local _MARKER_COOL="${VENV}/.last_update_${_NAME_COOL}"

  if [ ! -f "$_MARKER_COOL" ]; then return 0; fi

  local _NOW_COOL
  local _LAST_COOL
  _NOW_COOL=$(date +%s)
  _LAST_COOL=$(cat "$_MARKER_COOL")
  if [ $((_NOW_COOL - _LAST_COOL)) -ge "$_DURATION_COOL" ]; then
    return 0
  fi
  return 1
}

# Purpose: Persists the current timestamp for a specific task marker.
# Params:
#   $1 - Task name
# Examples:
#   save_update_timestamp "brew"
save_update_timestamp() {
  local _NAME_TS="$1"
  local _MARKER_TS="${VENV}/.last_update_${_NAME_TS}"
  mkdir -p "$(dirname "$_MARKER_TS")"
  date +%s >"$_MARKER_TS"
}

# Purpose: Downloads a file from a URL with built-in retries and proxy fallback.
# Params:
#   $1 - Source URL
#   $2 - Target destination path
#   $3 - Description of the item (for logging)
# Returns:
#   0 - Success
#   1 - Fatal failure
# Examples:
#   download_url "https://example.com/tool.tar.gz" "/tmp/tool.tar.gz" "Awesome Tool"
download_url() {
  local _URL_DL="$1"
  local _OUT_DL="$2"
  local _DESC_DL="$3"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY-RUN: Would download $_URL_DL to $_OUT_DL"
    return 0
  fi

  # Ensure output directory exists
  local _DIR_DL
  _DIR_DL=$(dirname "$_OUT_DL")
  mkdir -p "$_DIR_DL"

  log_info "Downloading $_DESC_DL..."
  # curl with retry flags as per rules
  if curl --retry 5 --retry-delay 2 --retry-connrefused --fail \
    --connect-timeout 10 --max-time 60 \
    -fsSL "${_URL_DL}" -o "${_OUT_DL}"; then
    return 0
  fi

  # Fallback if proxy failed and it was a proxied URL
  if [ -n "${GITHUB_PROXY}" ] && echo "${_URL_DL}" | grep -q "^${GITHUB_PROXY}"; then
    local _FALLBACK_URL_DL="${_URL_DL#"$GITHUB_PROXY"}"
    log_warn "Proxy download failed for ${_DESC_DL}, retrying directly from ${_FALLBACK_URL_DL}..."
    if curl --retry 5 --retry-delay 2 --retry-connrefused --fail \
      --connect-timeout 10 --max-time 60 \
      -fsSL "${_FALLBACK_URL_DL}" -o "${_OUT_DL}"; then
      return 0
    fi
  fi

  log_error "Failed to download $_DESC_DL from $_URL_DL"
  return 1
}

# Purpose: Verifies the SHA256 checksum of a file.
# Params:
#   $1 - Path to the file
#   $2 - Expected SHA256 hash
# Returns:
#   0 - Verified
#   1 - Mismatch
# Examples:
#   verify_checksum "/tmp/tool.tar.gz" "abc123def..."
verify_checksum() {
  local _FILE_CS="$1"
  local _EXPECTED_SHA_CS="$2"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY-RUN: Would verify checksum for $_FILE_CS"
    return 0
  fi

  log_info "Verifying checksum for $(basename "$_FILE_CS")..."
  local _ACTUAL_SHA_CS
  if command -v sha256sum >/dev/null 2>&1; then
    _ACTUAL_SHA_CS=$(sha256sum "$_FILE_CS" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    _ACTUAL_SHA_CS=$(shasum -a 256 "$_FILE_CS" | awk '{print $1}')
  else
    log_warn "sha256sum/shasum not found. Skipping checksum verification."
    return 0
  fi

  if [ "$_ACTUAL_SHA_CS" != "$_EXPECTED_SHA_CS" ]; then
    log_error "Checksum mismatch for $_FILE_CS!"
    log_error "Expected: $_EXPECTED_SHA_CS"
    log_error "Actual:   $_ACTUAL_SHA_CS"
    return 1
  fi

  log_success "Checksum verified."
  return 0
}

# Purpose: Verifies if a required runtime or tool is available in the environment.
#          Silently EXITS the script (skip) if missing, assuming optionality.
# Params:
#   $1 - Command/Binary name to check
#   $2 - Human-readable tool name (for logging)
# Examples:
#   check_runtime "go" "Golang Builder"
check_runtime() {
  local _RT_NAME="$1"
  local _TOOL_DESC="${2:-Tool}"
  if ! command -v "$_RT_NAME" >/dev/null 2>&1; then
    log_warn "⏭️  Required runtime '$_RT_NAME' for $_TOOL_DESC is missing. Skipping."
    exit 0
  fi
}

# Purpose: Identifies the primary package manager on macOS.
# Returns: "brew", "port", or "none"
# Examples:
#   MGR=$(get_macos_pkg_mgr)
get_macos_pkg_mgr() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew"
  elif command -v port >/dev/null 2>&1; then
    echo "port"
  else
    echo "none"
  fi
}

# Purpose: Detects project language affiliation based on manifests or extensions.
# Params:
#   $1 - Manifest files (space-separated, e.g., "go.mod package.json")
#   $2 - File globs/extensions (space-separated, e.g., "*.go *.ts")
# Returns:
#   0 - Detected
#   1 - Not detected
# Examples:
#   if has_lang_files "package.json" "*.ts *.js"; then echo "Node project"; fi
has_lang_files() {
  local _FILES_LANG="$1"
  local _EXTS_LANG="$2"

  # 1. Check for specific config files in root
  local _f_lang
  for _f_lang in $_FILES_LANG; do
    [ -f "$_f_lang" ] && return 0
  done

  # 2. Check for file extensions (recursive, maxdepth 3 for performance)
  local _ext_lang
  for _ext_lang in $_EXTS_LANG; do
    # Use find for POSIX compatibility and performance
    if [ "$(find . -maxdepth 3 -name "$_ext_lang" -print -quit 2>/dev/null)" ]; then
      return 0
    fi
  done

  return 1
}

# Purpose: Dynamically extracts the project version from manifest files.
# Returns: Version string (detected) or "0.0.0" (fallback).
# Examples:
#   VER=$(get_project_version)
get_project_version() {
  if [ -f "$PACKAGE_JSON" ]; then
    grep '"version":' "$PACKAGE_JSON" | head -n 1 | sed 's/.*"version":[[:space:]]*"//;s/".*//'
  elif [ -f "$CARGO_TOML" ]; then
    grep '^version =' "$CARGO_TOML" | head -n 1 | sed -e 's/.*"\(.*\)"/\1/' -e "s/.*'\(.*\)'/\1/"
  elif [ -f "$PYPROJECT_TOML" ]; then
    grep '^version =' "$PYPROJECT_TOML" | head -n 1 | sed 's/.*"//;s/".*//'
  elif [ -f "$VERSION_FILE" ]; then
    cat "$VERSION_FILE" | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  else
    # Fallback to git tag if available
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0"
    else
      echo "0.0.0"
    fi
  fi
}

# Purpose: Executes an npm/pnpm script with infinite-recursion detection.
# Params:
#   $1 - Name of the npm script (e.g., "test")
# Examples:
#   run_npm_script "test"
run_npm_script() {
  local _SCRIPT_NAME_NPM="$1"
  local _CURRENT_BASENAME_NPM
  _CURRENT_BASENAME_NPM=$(basename "$0")

  if [ -f "$PACKAGE_JSON" ]; then
    local _CMD_NPM
    _CMD_NPM=$(grep "\"$_SCRIPT_NAME_NPM\":" "$PACKAGE_JSON" | sed "s/.*\"$_SCRIPT_NAME_NPM\":[[:space:]]*\"//;s/\".*//" || true)
    if [ -n "$_CMD_NPM" ]; then
      # Avoid infinite loop if the command points back to this script
      if echo "$_CMD_NPM" | grep -q "$_CURRENT_BASENAME_NPM"; then
        log_debug "npm script '$_SCRIPT_NAME_NPM' is a self-reference to '$_CURRENT_BASENAME_NPM'. Skipping."
        return 0
      fi
      log_info "── Running Node.js script: $NPM $_SCRIPT_NAME_NPM ──"
      "$NPM" run "$_SCRIPT_NAME_NPM"
      return 0
    fi
  fi
  return 0
}

# Purpose: Executes a command while suppressing its output in quiet mode.
# Params:
#   $@ - Command and arguments to execute
# Examples:
#   run_quiet git rev-parse --is-inside-work-tree
run_quiet() {
  if [ "${VERBOSE:-1}" -eq 0 ]; then
    "$@" >/dev/null 2>&1
  else
    "$@"
  fi
}

# Purpose: Performs an atomic file replacement (Build-then-Swap).
# Params:
#   $1 - Source (temporary) file path
#   $2 - Target destination path
# Returns:
#   0 - Success
#   1 - Source missing
# Examples:
#   atomic_swap "new_config.json.tmp" "config.json"
atomic_swap() {
  local _SRC_ATOMIC="$1"
  local _DST_ATOMIC="$2"
  if [ ! -f "$_SRC_ATOMIC" ]; then
    log_warn "atomic_swap: Source file $_SRC_ATOMIC does not exist."
    return 1
  fi
  # Use mv for atomic operation on the same filesystem
  mv "$_SRC_ATOMIC" "$_DST_ATOMIC"
}

# Purpose: Orchestrates global argument parsing for all project scripts.
# Params:
#   $@ - Command-line arguments to parse
# Examples:
#   parse_common_args "$@"
parse_common_args() {
  local _arg_common
  for _arg_common in "$@"; do
    case "$_arg_common" in
    --dry-run)
      # shellcheck disable=SC2034
      DRY_RUN=1
      log_warn "Running in DRY-RUN mode. No changes will be applied."
      ;;
    -q | --quiet) # shellcheck disable=SC2034
      VERBOSE=0 ;;
    -v | --verbose) # shellcheck disable=SC2034
      export VERBOSE=2 ;;
    -h | --help)
      # shellcheck disable=SC2317
      if command -v show_help >/dev/null 2>&1; then
        show_help
      else
        printf "Usage: %s [OPTIONS]\n\nOptions:\n  --dry-run      Show what would be done\n  -q, --quiet    Suppress output\n  -v, --verbose  Enable debug logging\n  -h, --help     Show this help\n" "$0"
      fi
      exit 0
      ;;
    esac
  done
}

# Purpose: Appends a status record to the centralized execution summary table.
# Params:
#   $1 - Category (e.g., Runtime, Tool, Audit)
#   $2 - Module name (e.g., Node.js, Gitleaks)
#   $3 - Status indicator (e.g., ✅ Success, ❌ Failed)
#   $4 - Version identifier string (or "-" if unavailable)
#   $5 - Duration in seconds (elapsed time)
#   $6 - Summary file path (optional, default: $SETUP_SUMMARY_FILE)
# Examples:
#   log_summary "Security" "Gitleaks" "✅ Clean" "v8.1.0" "5"
log_summary() {
  local _CAT_SUM="${1:-Other}"
  local _MOD_SUM="${2:-Unknown}"
  local _STAT_SUM="${3:-⏭️ Skipped}"
  local _VER_SUM="${4:--}"
  local _DUR_SUM="${5:--}"
  local _FILE_SUM="${6:-$SETUP_SUMMARY_FILE}"

  if [ -z "$_FILE_SUM" ] || [ ! -f "$_FILE_SUM" ]; then
    return 0
  fi

  # Automatically demote to Warning if status is supposedly Active/Installed but version detection failed
  case "$_STAT_SUM" in
  ✅*)
    if [ "$_VER_SUM" = "-" ] || [ -z "$_VER_SUM" ]; then
      case "$_MOD_SUM" in
      System | Shell | React | Vue | Tailwind | VitePress | Vite | pnpm-deps | Python-Venv | Homebrew | Hooks | Go-Mod | Cargo-Deps | Ruby-Gems) ;; # These don't always have a single version command
      *) _STAT_SUM="⚠️ Warning" ;;
      esac
    fi
    ;;
  esac

  printf "| %-12s | %-15s | %-20s | %-15s | %-6s |\n" "$_CAT_SUM" "$_MOD_SUM" "$_STAT_SUM" "$_VER_SUM" "${_DUR_SUM}s" >>"$_FILE_SUM"
}

# Purpose: Safely extracts version strings from various command outputs.
# Params:
#   $1 - Binary or Command path to execute
#   $2 - Argument to fetch version (default: --version)
# Returns:
#   Detected version string (stripped) or "-" if command fails/missing.
# Examples:
#   V=$(get_version "node")
#   V=$(get_version "go" "version")
get_version() {
  local _CMD_VER="$1"
  local _ARG_VER="${2:---version}"
  if command -v "$_CMD_VER" >/dev/null 2>&1; then
    # Standard version extraction: find the first sequence starting with a digit
    case "$_CMD_VER" in
    go)
      "$_CMD_VER" version 2>&1 | head -n 1 | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15
      ;;
    node | python | cargo | dotnet | dart | pwsh)
      "$_CMD_VER" "$_ARG_VER" 2>&1 | head -n 1 | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15
      ;;
    pip-audit)
      "$_CMD_VER" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
      ;;
    govulncheck)
      "$_CMD_VER" -version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
      ;;
    swift)
      # Swift version output: "swift-driver version: 1.115 Apple Swift version 6.0.3 (swiftlang-6.0.3.1.10 ...)"
      "$_CMD_VER" "$_ARG_VER" 2>&1 | sed -n 's/.*Swift version \([0-9][0-9.]*\).*/\1/p' | head -n 1
      ;;
    java)
      # java -version outputs to stderr and puts version in quotes
      "$_CMD_VER" "$_ARG_VER" 2>&1 | sed -n 's/.*version "\([0-9][0-9.]*\).*/\1/p' | head -n 1
      ;;
    *)
      # For other binaries, try to get version from the output
      "$_CMD_VER" "$_ARG_VER" 2>&1 | head -n 1 | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15
      ;;
    esac
  else
    echo "-"
  fi
}
