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
#   - Build-then-Swap atomic file operations.
#   - Dual-Sentinel (双重哨兵) pattern for CI reporting.
#
# shellcheck disable=SC2034
export PAGER="cat"
export MISE_LOCKFILE=0
export MISE_LOCKED=0
export NO_UPDATE_NOTIFIER=1

# ── 🎨 Visual Assets ─────────────────────────────────────────────────────────

# Colors (using printf to generate literal ESC characters for maximum compatibility)
BLUE=$(printf '\033[0;34m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
RED=$(printf '\033[0;31m')
NC=$(printf '\033[0m')

# ── 🎭 Global Environment Detection ──────────────────────────────────────────

# Detect OS and set pathing conventions dynamically to ensure absolute parity
# between Linux, macOS, and Windows (via POSIX shells like Git Bash).
_G_UNAME=$(uname -s)
case "$_G_UNAME" in
Darwin)
  _G_OS="macos"
  _G_VENV_BIN="bin"
  _G_MISE_BIN_BASE="$HOME/.local/bin"
  _G_MISE_SHIMS_BASE="$HOME/.local/share/mise/shims"
  ;;
Linux)
  _G_OS="linux"
  _G_VENV_BIN="bin"
  _G_MISE_BIN_BASE="$HOME/.local/bin"
  _G_MISE_SHIMS_BASE="$HOME/.local/share/mise/shims"
  ;;
MINGW* | MSYS* | CYGWIN*)
  _G_OS="windows"
  _G_VENV_BIN="Scripts"
  # In Windows-based POSIX shells, AppData/Local is the standard base for mise data
  if command -v cygpath >/dev/null 2>&1; then
    _G_APP_DATA_LOCAL=$(cygpath -u "$LOCALAPPDATA")
  else
    # Fallback to manual path translation if cygpath is missing
    _G_APP_DATA_LOCAL=$(echo "$LOCALAPPDATA" | sed 's/\\/\//g; s/:\(.*\)/\/\1/; s/^\([A-Za-z]\)\//\/\L\1\//')
  fi
  _G_MISE_BIN_BASE="$HOME/.local/bin" # Mise installer usually puts bin here in Git Bash
  _G_MISE_SHIMS_BASE="${_G_APP_DATA_LOCAL:-$HOME/AppData/Local}/mise/shims"
  ;;
*)
  _G_OS="linux"
  _G_VENV_BIN="bin"
  _G_MISE_BIN_BASE="$HOME/.local/bin"
  _G_MISE_SHIMS_BASE="$HOME/.local/share/mise/shims"
  ;;
esac

# ── ⚙️ Global Configuration ──────────────────────────────────────────────────

# Default verbosity
# shellcheck disable=SC2034
VERBOSE=${VERBOSE:-1} # 0: quiet, 1: normal, 2: verbose
DRY_RUN=${DRY_RUN:-0}

# Enforce Non-Interactive Mode (For CI/CD and Headless Setup)
# These prevent 'mise' from asking for user confirmation or trust prompts.
# Ref: Rule 01 (General), Rule 08 (Dev Env)
export MISE_YES=true
export MISE_NON_INTERACTIVE=true
# Force mise to use system git for better proxy/config compatibility
export MISE_GIT_ALWAYS_USE_GIX=0
export MISE_GIX=0
export MISE_USE_GIX=0

# Orchestration tracking (detect if we are running as a sub-script)
if [ -z "$_SNOWDREAM_TOP_LEVEL_SCRIPT" ]; then
  _SCRIPT_NAME=$(basename "$0")
  export _SNOWDREAM_TOP_LEVEL_SCRIPT="$_SCRIPT_NAME"
  _IS_TOP_LEVEL=true
else
  _IS_TOP_LEVEL=false
fi

# ── 📄 SSoT Constants (Paths and Files) ──────────────────────────────────────

VENV="${VENV:-.venv}"
PYTHON="${PYTHON:-python3}"
# Dynamically detect Node.js package manager if not explicitly set
if [ -z "$NPM" ]; then
  if command -v bun >/dev/null 2>&1; then
    NPM="bun"
  elif command -v pnpm >/dev/null 2>&1; then
    NPM="pnpm"
  elif command -v yarn >/dev/null 2>&1; then
    NPM="yarn"
  else
    NPM="npm"
  fi
fi
export NPM
DOCS_DIR="docs"
PACKAGE_JSON="${PACKAGE_JSON:-package.json}"
REQUIREMENTS_TXT="${REQUIREMENTS_TXT:-requirements.txt}"
PYPROJECT_TOML="${PYPROJECT_TOML:-pyproject.toml}"
CARGO_TOML="${CARGO_TOML:-Cargo.toml}"
VERSION_FILE="${VERSION_FILE:-VERSION}"
CHANGELOG="${CHANGELOG:-CHANGELOG.md}"
LOCK_DIR="${LOCK_DIR:-.archival_lock}"
ARCHIVE_DIR="${ARCHIVE_DIR:-.}"

# Network Optimization & Mirror Configuration
# NOTE: GITHUB_PROXY is optimized for Release/Archive/File downloads.
# It does NOT support project folder clones (git clone).
ENABLE_GITHUB_PROXY="${ENABLE_GITHUB_PROXY:-0}"

# ── 🔨 SSoT Tool Versions ────────────────────────────────────────────────────

# Runtime versions (Managed via .mise.toml, but some logic might still reference these for bootstrap purposes)
# Only MISE is hardcoded here to facilitate the zero-dependency bootstrap phase.
MISE_VERSION="${MISE_VERSION:-2026.3.8}"

# Note: All other tools (Gitleaks, Shellcheck, Shfmt, Java Format, etc.) are purely managed
# by the project's .mise.toml file. Do not add hardcoded version variables here.
# Any tool added below MUST have a corresponding entry in .mise.toml Tools section.

# ── 🛣️ PATH Augmentation ──────────────────────────────────────────────────────

# Automatically add local bin directories to PATH to ensure orchestrated tools
# are prioritized over system globals without requiring manual activation.
_LOCAL_BIN_VENV=$(pwd)/${VENV}/${_G_VENV_BIN}
_LOCAL_BIN_NODE=$(pwd)/node_modules/.bin
_LOCAL_MISE_BIN="$_G_MISE_BIN_BASE"
_LOCAL_MISE_SHIMS="$_G_MISE_SHIMS_BASE"

if [ -d "$_LOCAL_MISE_BIN" ]; then
  case ":$PATH:" in
  *":$_LOCAL_MISE_BIN:"*) ;;
  *) export PATH="$_LOCAL_MISE_BIN:$PATH" ;;
  esac
fi

if [ -d "$_LOCAL_MISE_SHIMS" ]; then
  case ":$PATH:" in
  *":$_LOCAL_MISE_SHIMS:"*) ;;
  *) export PATH="$_LOCAL_MISE_SHIMS:$PATH" ;;
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

# ── 🛣️ CI Persistence (GitHub Actions) ───────────────────────────────────────

if [ "${GITHUB_ACTIONS:-}" = "true" ] && [ -n "${GITHUB_PATH:-}" ]; then
  # Proactively add mise paths to GITHUB_PATH using absolute references.
  # This ensures tools like 'commitlint' and 'vitepress' are available in subsequent steps.
  # Note: GitHub Actions reads these at the end of the step to update PATH for the next.
  _M_BIN_CI="$_G_MISE_BIN_BASE"
  _M_SHIMS_CI="$_G_MISE_SHIMS_BASE"

  case ":$PATH:" in
  *":$_M_BIN_CI:"*) ;;
  *) echo "$_M_BIN_CI" >>"$GITHUB_PATH" ;;
  esac

  case ":$PATH:" in
  *":$_M_SHIMS_CI:"*) ;;
  *) echo "$_M_SHIMS_CI" >>"$GITHUB_PATH" ;;
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
  zsh | bash | fish | pwsh | powershell | nu | xonsh | elvish)
    _M_SHELL="$_PARENT_SHELL"
    ;;
  *)
    case "$SHELL" in
    *zsh*) _M_SHELL="zsh" ;;
    *bash*) _M_SHELL="bash" ;;
    *fish*) _M_SHELL="fish" ;;
    *pwsh*) _M_SHELL="pwsh" ;;
    *nu*) _M_SHELL="nu" ;;
    *xonsh*) _M_SHELL="xonsh" ;;
    *elvish*) _M_SHELL="elvish" ;;
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
  if [ "${ENABLE_GITHUB_PROXY}" = "1" ] || [ "${ENABLE_GITHUB_PROXY}" = "true" ]; then
    _M_URL="${GITHUB_PROXY}${_M_URL}"
  fi
  local _DEST="$HOME/.local/bin/mise"
  [ "$_OS" = "windows" ] && _DEST="${_DEST}.exe"

  mkdir -p "$(dirname "$_DEST")"

  _download() {
    if command -v curl >/dev/null 2>&1; then
      run_quiet curl -fSL --connect-timeout 15 -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then
      run_quiet wget -q --timeout=15 -O "$2" "$1"
    else
      log_error "Neither curl nor wget is available for manual download."
      return 1
    fi
  }

  if [ "$_OS" = "windows" ]; then
    if ! command -v unzip >/dev/null 2>&1; then
      log_error "Error: 'unzip' is required for Windows manual bootstrap."
      return 1
    fi
    local _TMP_DIR
    _TMP_DIR=$(mktemp -d 2>/dev/null || echo "/tmp/mise_win_extract")
    local _TMP_ZIP="${_TMP_DIR}/mise.zip"

    if _download "$_M_URL" "$_TMP_ZIP"; then
      if unzip -q "$_TMP_ZIP" -d "$_TMP_DIR"; then
        # Robustly find mise.exe and mise-shim.exe in any extracted path
        local _FOUND_BIN
        _FOUND_BIN=$(find "$_TMP_DIR" -maxdepth 3 -name "mise.exe" | head -n 1)
        if [ -n "$_FOUND_BIN" ]; then
          mv "$_FOUND_BIN" "$_DEST"
          local _FOUND_SHIM
          _FOUND_SHIM=$(find "$_TMP_DIR" -maxdepth 3 -name "mise-shim.exe" | head -n 1)
          [ -n "$_FOUND_SHIM" ] && mv "$_FOUND_SHIM" "$(dirname "$_DEST")/mise-shim.exe"
          rm -rf "$_TMP_DIR"
          return 0
        fi
      fi
    fi
    rm -rf "$_TMP_DIR"
  else
    if _download "$_M_URL" "$_DEST"; then
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

  # mise completion performs better when 'usage' is installed.
  run_mise use --global usage >/dev/null 2>&1 || true

  case "$_SHELL" in
  zsh)
    local _DIR="${ZDOTDIR:-$HOME}/.zsh/completions"
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
  pwsh | powershell)
    local _DIR="$HOME/Documents/PowerShell/Completions"
    mkdir -p "$_DIR"
    # mise completion supports 'powershell' (or 'pwsh' as alias in newer versions)
    mise completion powershell >"$_DIR/mise-completion.ps1" 2>/dev/null || true
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
  _M_BIN=$(command -v mise || echo "$_G_MISE_BIN_BASE/mise")
  [ "$_G_OS" = "windows" ] && [ ! -x "$_M_BIN" ] && _M_BIN="${_M_BIN}.exe"

  if [ -x "$_M_BIN" ]; then
    # PowerShell and Nushell activation in POSIX sh is complex/limited to shims.
    # We focus on the most impactful session update: shims.
    case "$_SHELL" in
    pwsh | powershell | nu | nushell)
      export PATH="$_G_MISE_SHIMS_BASE:$PATH"
      ;;
    *)
      eval "$("$_M_BIN" activate "$_SHELL" --shims)"
      ;;
    esac
    log_debug "mise environment synchronized for current session."
  fi
}

bootstrap_mise() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_info "Dry-run: Skipping mise bootstrap."
    return 0
  fi

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
  # Priority 3: Manual Binary (Fast & cross-platform)
  elif _mise_install_tier4 "$_M_OS" "$_M_ARCH" "${MISE_VERSION#[vV]}"; then
    log_success "mise installed via Tier 3 (Manual Binary)."
  # Priority 4: Language Tools (Slowest fallback)
  elif _mise_install_tier3; then
    log_success "mise installed via Tier 4 (Language Tool)."
  else
    log_error "All mise installation tiers failed."
    return 1
  fi

  # Path Refresh: Ensure MISE is available for immediate setup
  [ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
  [ -d "$_G_MISE_BIN_BASE" ] && export PATH="$_G_MISE_BIN_BASE:$PATH"
  [ -d "$_G_MISE_SHIMS_BASE" ] && export PATH="$_G_MISE_SHIMS_BASE:$PATH"

  # ── 🏗️ Post-Install Configuration ──

  # Finalize Activation
  _mise_apply_activation "$_M_SHELL"

  # Setup Completions
  _mise_setup_completions "$_M_SHELL"

  # Security & Automation: Trust project config
  if [ -f ".mise.toml" ]; then
    log_info "Trusting local .mise.toml..."
    mise trust ".mise.toml" >/dev/null 2>&1 || true
  fi

  # Verify Health
  _mise_verify_health
}

# ── 🌐 Network Optimization ──────────────────────────────────────────────────

# Purpose: Dynamically detects network connectivity and applies mirrors/proxies.
#          Tests access to GitHub and handles broken global git/proxy settings.
# Examples:
#   optimize_network
optimize_network() {
  if [ "$_NETWORK_OPTIMIZED" = "true" ]; then return 0; fi

  local _TEMP_GIT_CONFIG
  _TEMP_GIT_CONFIG="/tmp/.git_config_$(id -u)"

  log_debug "Detecting network connectivity and global proxy health..."

  # 1. Handle Git Protocols & Proxies
  # Guard: If GITHUB_TOKEN is set, verify it's not broken (avoid 401 errors).
  if [ -n "$GITHUB_TOKEN" ]; then
    if ! curl -Is --connect-timeout 2 -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user >/dev/null 2>&1; then
      log_warn "Current GITHUB_TOKEN appears invalid or unauthorized (401). Unsetting for this session..."
      unset GITHUB_TOKEN
    fi
  fi

  # Apply Git optimization and GitHub Proxy if ENABLE_GITHUB_PROXY is active.
  # Registry mirrors (npm, pip, etc.) are now always active via .mise.toml [env].
  if [ "${ENABLE_GITHUB_PROXY}" = "1" ] || [ "${ENABLE_GITHUB_PROXY}" = "true" ]; then
    log_info "Bypassing broken global git proxies and applying network optimization..."

    mkdir -p "$(dirname "$_TEMP_GIT_CONFIG")"
    cat >"$_TEMP_GIT_CONFIG" <<EOF
[http]
  postBuffer = 524288000
  lowSpeedLimit = 0
  lowSpeedTime = 999999
[protocol]
  version = 2
EOF
    export GIT_CONFIG_GLOBAL="$_TEMP_GIT_CONFIG"
    export GIT_CONFIG_SYSTEM="/dev/null"
  fi

  export _NETWORK_OPTIMIZED=true
}

# Purpose: Extracts the configured version of a tool from .mise.toml.
# Params:
#   $1 - Tool name (e.g., "node", "python", "golangci-lint")
# Returns:
#   The version string or empty if not found.
# Examples:
#   VER=$(get_mise_tool_version "node")
get_mise_tool_version() {
  local _TOOL_NAME_MISE="$1"
  local _MISE_TOM_PATH
  _MISE_TOM_PATH=$(get_project_root)/.mise.toml
  [ -f "$_MISE_TOM_PATH" ] || return 0

  # Robust regex for [.mise.toml] parsing:
  # - Matches lines starting with the tool name (optionally quoted and prefixed)
  # - Extracts the value inside double quotes
  grep -E "^\"?([^:]+:)?${_TOOL_NAME_MISE}\"?[[:space:]]*=" "$_MISE_TOM_PATH" 2>/dev/null |
    sed -E 's/^[^=]*=[[:space:]]*"([^"]*)".*/\1/' | head -n 1 || true
}

# Purpose: Executes a mise command with retry logic and intelligent fallback.
# Params:
#   $@ - Command and arguments for mise
# Examples:
#   run_mise install node
run_mise() {
  local _CMD="$1"
  shift

  # Guard: Unset potentially invalid GITHUB_TOKEN to avoid 401 errors for GitHub-based tools.
  # This is safe because our mirrors and global proxy handle connectivity.
  local _OLD_GITHUB_TOKEN="$GITHUB_TOKEN"
  unset GITHUB_TOKEN

  # (Mise install is generally fast, but checking avoids overhead)
  if [ "$_CMD" = "install" ] && [ -n "$1" ]; then
    local _TOOL_CHECK="$1"

    # 1. Required Version from .mise.toml (SSoT)
    local _REQ_VER
    _REQ_VER=$(get_mise_tool_version "$_TOOL_CHECK")

    # 2. Normalize binary name for check (strip prefixes and Stoplight scope etc)
    local _TOOL_BASE
    _TOOL_BASE=$(echo "$_TOOL_CHECK" | sed -E 's/^([^:]+:)?(@[^/]+\/)?//; s/.*\///')

    # 3. Current Version Check
    local _CUR_VER
    _CUR_VER=$(get_version "$_TOOL_BASE" | tr -d '\r')

    # 4. Rigorous Comparison (Ensures exact match or prefix)
    if [ "$_CUR_VER" != "-" ] && [ -n "$_REQ_VER" ]; then
      if [ "$_CUR_VER" = "$_REQ_VER" ] || echo "$_CUR_VER" | grep -q "^${_REQ_VER}"; then
        # Skip if version matches
        return 0
      fi
    fi

    # 5. Backend-aware Manager Existence Check
    case "$_TOOL_CHECK" in
    cargo:*)
      if ! command -v cargo >/dev/null 2>&1; then
        log_error "Cannot install '$_TOOL_CHECK': 'cargo' (Rust) is missing. Please install Rust first."
        return 1
      fi
      ;;
    go:*)
      if ! command -v go >/dev/null 2>&1; then
        log_error "Cannot install '$_TOOL_CHECK': 'go' (Golang) is missing. Please install Go first."
        return 1
      fi
      ;;
    pipx:*)
      if ! command -v pipx >/dev/null 2>&1; then
        log_info "pipx not found — bootstrapping..."
        local _M_BIN_PIPX
        _M_BIN_PIPX=$(command -v mise 2>/dev/null || echo "$_G_MISE_BIN_BASE/mise")
        [ "$_G_OS" = "windows" ] && [ ! -x "$_M_BIN_PIPX" ] && _M_BIN_PIPX="${_M_BIN_PIPX}.exe"

        if [ "$_G_OS" = "windows" ]; then
          # On Windows, pipx via mise (aqua) often fails. Use pip fallback.
          python -m pip install --user pipx >/dev/null 2>&1 || true
        else
          # Install pipx without GITHUB_TOKEN
          "$_M_BIN_PIPX" install pipx >/dev/null 2>&1 || true
        fi

        # Ensure mise shims and pipx paths are available
        # pipx on windows typically installs to USERPROFILE/AppData/Local/pipx/pipx/bin or similar,
        # but the shim is usually in the python scripts folder if installed via pip --user.
        export PATH="$_G_MISE_SHIMS_BASE:$_G_MISE_BIN_BASE:$PATH"
        if ! command -v pipx >/dev/null 2>&1; then
          log_error "Cannot install '$_TOOL_CHECK': 'pipx' is missing even after bootstrap. Please run 'make setup' or install pipx first."
          export GITHUB_TOKEN="$_OLD_GITHUB_TOKEN"
          return 1
        fi
      fi
      ;;
    npm:*)
      if ! command -v npm >/dev/null 2>&1; then
        log_error "Cannot install '$_TOOL_CHECK': 'npm' (Node.js) is missing. Please install Node.js first."
        return 1
      fi
      ;;
    esac

    log_debug "Tool $_TOOL_BASE (current: $_CUR_VER, required: $_REQ_VER) needs initialization/update."
  fi

  # ── Attempt 1: Standard Execution ──
  optimize_network
  local _MAX_RETRIES=3
  local _RETRY_COUNT=0
  local _STATUS=1

  # Defensive: Ensure mise is available even if PATH is slightly out of sync
  local _M_BIN
  _M_BIN=$(command -v mise || echo "$HOME/.local/bin/mise")

  # Propagate verbosity to mise
  local _MISE_OPTS=""
  if [ "${VERBOSE:-1}" -ge 2 ]; then
    _MISE_OPTS="--verbose"
  fi

  while [ $_RETRY_COUNT -lt $_MAX_RETRIES ]; do
    # ── Intelligent Fallback ──
    # If first attempt failed and we have a global git proxy active,
    # try running with proxy disabled for subsequent attempts.
    if [ $_RETRY_COUNT -gt 0 ]; then
      log_warn "Retrying with direct connection (bypassing all git proxies)..."
      if (
        export GIT_CONFIG_GLOBAL=/dev/null
        export GIT_CONFIG_SYSTEM=/dev/null
        if [ "${VERBOSE:-1}" -le 1 ]; then
          # shellcheck disable=SC2086
          MISE_QUIET=1 "$_M_BIN" $_MISE_OPTS "$_CMD" "$@" >/dev/null 2>&1
        else
          # shellcheck disable=SC2086
          MISE_QUIET=1 "$_M_BIN" $_MISE_OPTS "$_CMD" "$@"
        fi
      ); then
        _STATUS=0
        break
      fi
    else
      if [ "${VERBOSE:-1}" -le 1 ]; then
        # shellcheck disable=SC2086
        MISE_QUIET=1 "$_M_BIN" $_MISE_OPTS "$_CMD" "$@" >/dev/null 2>&1
      else
        # shellcheck disable=SC2086
        MISE_QUIET=1 "$_M_BIN" $_MISE_OPTS "$_CMD" "$@"
      fi
      _STATUS=$?
      [ $_STATUS -eq 0 ] && break
    fi

    _RETRY_COUNT=$((_RETRY_COUNT + 1))
    if [ $_RETRY_COUNT -lt $_MAX_RETRIES ]; then
      log_warn "mise command failed (attempt $_RETRY_COUNT/$_MAX_RETRIES). Retrying..."
      sleep 1
    fi
  done

  # Restore GITHUB_TOKEN
  if [ -n "$_OLD_GITHUB_TOKEN" ]; then
    export GITHUB_TOKEN="$_OLD_GITHUB_TOKEN"
  else
    unset GITHUB_TOKEN
  fi

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

# Purpose: Verifies that a required toolchain manager (e.g., cargo, npm, go) is available.
# Params:
#   $1 - Manager command name
# Examples:
#   ensure_manager cargo
ensure_manager() {
  local _MGR="$1"
  if ! command -v "$_MGR" >/dev/null 2>&1; then
    log_error "Error: Toolchain manager '$_MGR' is missing but required for this installation."
    exit 1
  fi
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

log_debug "common.sh (v2026.03.14.01) loaded"

# Purpose: Returns the absolute path to the project root directory.
# Returns:
#   Absolute path string.
# Examples:
#   ROOT=$(get_project_root)
get_project_root() {
  local _DIR
  _DIR=$(pwd)
  while [ "$_DIR" != "/" ]; do
    if [ -f "$_DIR/Makefile" ] || [ -f "$_DIR/package.json" ] || [ -d "$_DIR/.git" ] || [ -f "$_DIR/.mise.toml" ]; then
      echo "$_DIR"
      return 0
    fi
    _DIR=$(dirname "$_DIR")
  done
  pwd
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

# Purpose: Detects the current CI platform by inspecting well-known environment variables.
# Returns: Platform name string, or "local" if not in a CI environment.
# Examples:
#   PLATFORM=$(detect_ci_platform)
detect_ci_platform() {
  if [ "${FORGEJO_ACTIONS:-}" = "true" ]; then
    echo "forgejo-actions"
  elif [ "${GITEA_ACTIONS:-}" = "true" ]; then
    echo "gitea-actions"
  elif [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    echo "github-actions"
  elif [ "${GITLAB_CI:-}" = "true" ]; then
    echo "gitlab-ci"
  elif [ "${DRONE:-}" = "true" ]; then
    echo "drone"
  elif [ "${WOODPECKER_CI:-}" = "true" ] || [ "${CI:-}" = "woodpecker" ]; then
    echo "woodpecker"
  elif [ "${CIRCLECI:-}" = "true" ]; then
    echo "circleci"
  elif [ "${TRAVIS:-}" = "true" ]; then
    echo "travis"
  elif [ "${TF_BUILD:-}" = "true" ]; then
    echo "azure-pipelines"
  elif [ "${JENKINS_URL:-}" != "" ]; then
    echo "jenkins"
  elif [ "${CI:-}" = "true" ]; then
    echo "ci-unknown"
  else
    echo "local"
  fi
}

# Purpose: Returns true (0) if running in any CI environment, false (1) if local.
# Examples:
#   if is_ci_env; then echo "CI"; fi
is_ci_env() {
  [ "$(detect_ci_platform)" != "local" ]
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

  # 2. Check for file extensions (recursive, maxdepth 5 for performance)
  # Exclude common build/dependency/cache directories to avoid false positives and improve speed

  local _ext_lang
  for _ext_lang in $_EXTS_LANG; do
    # Specialty cases for common multi-file structures
    case "$_ext_lang" in
    CHARTS)
      [ -f "Chart.yaml" ] && return 0
      [ -d "charts" ] && return 0
      ;;
    K8S)
      # Check for common Kubernetes folder or specific schemas
      [ -d "kubernetes" ] && return 0
      [ -d "k8s" ] && return 0
      [ -d "manifests" ] && return 0
      ;;
    esac

    # Use find for POSIX compatibility and performance
    if [ "$(find . \( -name .git -o -name node_modules -o -name .venv -o -name venv -o -name env -o -name vendor -o -name dist -o -name build -o -name out -o -name target -o -name .next -o -name .nuxt -o -name .output -o -name __pycache__ -o -name .specify -o -name .tmp -o -name tmp \) -prune -o -maxdepth 5 -name "$_ext_lang" -print -quit 2>/dev/null)" ]; then
      return 0
    fi
  done

  return 1
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
  [ -z "$_CMD_VER" ] && {
    echo "-"
    return 0
  }

  # 1. Try Mise First (Fast & Reliable for JIT tools)
  if command -v mise >/dev/null 2>&1; then
    local _MISE_VER_OUT
    # We search for the tool name with potential prefixes (npm:, github:, cargo:, pipx:)
    _MISE_VER_OUT=$(mise ls --json | jq -r "to_entries[] | select(.key == \"$_CMD_VER\" or .key == \"npm:$_CMD_VER\" or .key == \"github:$_CMD_VER\" or .key == \"cargo:$_CMD_VER\" or .key == \"pipx:$_CMD_VER\" or .key == \"github:goreleaser/$_CMD_VER\") | .value[] | select(.active==true) | .version" | head -n 1)
    if [ -n "$_MISE_VER_OUT" ]; then
      echo "$_MISE_VER_OUT"
      return 0
    fi
  fi

  # 2. Fallback to binary execution
  if command -v "$_CMD_VER" >/dev/null 2>&1; then
    case "$_CMD_VER" in
    python | python3)
      "$_CMD_VER" --version 2>&1 | cut -d' ' -f2
      ;;
    node)
      "$_CMD_VER" --version 2>&1 | sed 's/^v//'
      ;;
    go)
      "$_CMD_VER" version 2>&1 | awk '{print $3}' | sed 's/^go//'
      ;;
    java)
      # java -version outputs to stderr and puts version in quotes
      "$_CMD_VER" "$_ARG_VER" 2>&1 | sed -n 's/.*version "\([0-9][0-9.]*\).*/\1/p' | head -n 1
      ;;
    *)
      # For other binaries, try to get version from the output
      # We strip 'v' or 'V' prefix and focus on the version number
      "$_CMD_VER" "$_ARG_VER" 2>&1 | head -n 1 | sed 's/^[vV]//' | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15
      ;;
    esac
  else
    echo "-"
  fi
}

# Purpose: Resolves a binary path by checking local virtualenvs, node_modules, and PATH.
# Params:
#   $1 - Binary name (e.g., "eslint", "pytest")
# Returns:
#   Absolute or relative path to the resolved binary, or empty if not found.
# Examples:
#   BIN=$(resolve_bin "eslint")
resolve_bin() {
  local _BIN_RES="$1"
  [ -z "$_BIN_RES" ] && return 1

  # 1. Check Python Venv
  local _VENV_RES="${VENV:-.venv}"
  if [ -x "$_VENV_RES/$_G_VENV_BIN/$_BIN_RES" ]; then
    echo "$_VENV_RES/$_G_VENV_BIN/$_BIN_RES"
    return 0
  fi

  # 2. Check Node Modules
  if [ -x "node_modules/.bin/$_BIN_RES" ]; then
    echo "node_modules/.bin/$_BIN_RES"
    return 0
  fi

  # 3. Check System PATH
  if command -v "$_BIN_RES" >/dev/null 2>&1; then
    command -v "$_BIN_RES"
    return 0
  fi

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
    awk 'NR==1' "$VERSION_FILE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  else
    echo "0.0.0"
  fi
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
    log_warn "Required runtime '$_RT_NAME' for $_TOOL_DESC is missing. Skipping."
    exit 0
  fi
}

# Purpose: Installs the Node.js runtime and project dependencies.
# Delegate: Managed via mise (.mise.toml) and the best available manager.
# Examples:
#   install_runtime_node
install_runtime_node() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Node.js runtime and project dependencies."
    return 0
  fi

  # 1. Runtime initialization
  run_mise install node
  eval "$(mise activate bash --shims)"

  # 2. Dependency resolution
  if [ -f "$PACKAGE_JSON" ]; then
    # We use 'install' explicitly to bypass manager detection overhead for bootstrap
    # but still use run_npm_script to leverage its guards.
    run_npm_script install
  fi
}

# Purpose: Dynamically detects the best available Node.js package manager.
# Priority: bun -> pnpm -> yarn -> npm
# Returns: Binary name string.
_detect_node_manager() {
  if command -v bun >/dev/null 2>&1; then
    echo "bun"
  elif command -v pnpm >/dev/null 2>&1; then
    echo "pnpm"
  elif command -v yarn >/dev/null 2>&1; then
    echo "yarn"
  else
    echo "npm"
  fi
}

# Purpose: Installs the Python runtime, creates a venv, and installs dependencies.
# Delegate: Managed via mise (.mise.toml) and pip.
# Examples:
#   install_runtime_python
install_runtime_python() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Python runtime and virtual environment."
    return 0
  fi

  # 1. Runtime initialization
  run_mise install python
  eval "$(mise activate bash --shims)"

  # 2. Virtualenv management
  if [ ! -d "$VENV" ]; then
    run_quiet "$PYTHON" -m venv "$VENV"
  fi

  # 3. Dependency resolution
  if [ -d "$VENV" ]; then
    # Standard requirements
    if [ -f "$REQUIREMENTS_TXT" ]; then
      run_quiet "$VENV/$_G_VENV_BIN/pip" install -r "$REQUIREMENTS_TXT"
    fi
    # Dev requirements (setup.sh specific but safe here)
    if [ -f "requirements-dev.txt" ]; then
      run_quiet "$VENV/$_G_VENV_BIN/pip" install -r "requirements-dev.txt"
    fi
  fi
}

# Purpose: Installs git hooks using pre-commit.
# Delegate: Managed via pipx (pre-commit).
# Examples:
#   install_runtime_hooks
install_runtime_hooks() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would active pre-commit hooks."
    return 0
  fi

  if [ ! -d ".git" ]; then
    log_debug "Not a git repository. Skipping hook installation."
    return 0
  fi

  local _PRE_COMMIT_BIN
  _PRE_COMMIT_BIN=$(resolve_bin "pre-commit")
  if [ -n "$_PRE_COMMIT_BIN" ]; then
    log_info "Running pre-commit install..."
    run_quiet "$_PRE_COMMIT_BIN" install
  else
    log_warn "pre-commit binary not found. Skipping hook installation."
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

  if [ -f "package.json" ]; then
    # 1. Manager Detection & Guard
    local _NODE_MGR
    if [ -n "$NPM" ]; then
      _NODE_MGR="$NPM"
    else
      _NODE_MGR=$(_detect_node_manager)
    fi

    if ! command -v "$_NODE_MGR" >/dev/null 2>&1; then
      log_warn "Warning: $_NODE_MGR command not found and no fallback available. Skipping Node.js task: $_SCRIPT_NAME_NPM."
      return 0
    fi

    # 2. Package.json Integrity check (Avoid empty/invalid JSON crashes)
    if [ ! -s "package.json" ] || ! grep -q "{" "package.json"; then
      log_debug "package.json is empty or invalid. Skipping Node.js task: $_SCRIPT_NAME_NPM."
      return 0
    fi

    # 3. Check for script in package.json
    local _CMD_NPM
    _CMD_NPM=$(grep "\"$_SCRIPT_NAME_NPM\":" "package.json" | sed "s/.*\"$_SCRIPT_NAME_NPM\":[[:space:]]*\"//;s/\".*//" || true)

    if [ -n "$_CMD_NPM" ]; then
      # Avoid infinite loop if the command points back to this script
      if echo "$_CMD_NPM" | grep -q "$_CURRENT_BASENAME_NPM"; then
        log_debug "Node script '$_SCRIPT_NAME_NPM' is a self-reference to '$_CURRENT_BASENAME_NPM'. Skipping."
        return 0
      fi
      log_info "── Running Node.js script: $_NODE_MGR $_SCRIPT_NAME_NPM ──"
      "$_NODE_MGR" run "$_SCRIPT_NAME_NPM"
    elif [ "$_SCRIPT_NAME_NPM" = "install" ] || [ "$_SCRIPT_NAME_NPM" = "update" ]; then
      # 4. Special Fallback for native commands if not defined in package.json scripts
      log_info "── Node.js standard command: $_NODE_MGR $_SCRIPT_NAME_NPM ──"
      run_quiet "$_NODE_MGR" "$_SCRIPT_NAME_NPM"
    fi
  fi
  return 0
}

# Purpose: Initializes the execution summary table file.
# Params:
#   $1 - Header title (e.g., "Execution Summary")
# Examples:
#   init_summary_table "Setup Execution Summary"
init_summary_table() {
  local _TITLE_TABLE="${1:-Execution Summary}"

  if [ -z "$SETUP_SUMMARY_FILE" ]; then
    SETUP_SUMMARY_FILE=$(mktemp)
    export SETUP_SUMMARY_FILE
  fi

  local _SENTINEL_TABLE
  _SENTINEL_TABLE="_SUMMARY_TABLE_INITIALIZED_$(echo "$_TITLE_TABLE" | tr ' ' '_')"
  if [ "$(eval echo "\$$_SENTINEL_TABLE")" = "true" ]; then
    return 0
  fi

  {
    printf "### %s\n\n" "$_TITLE_TABLE"
    printf "| Category | Module | Status | Version | Time |\n"
    printf "| :--- | :--- | :--- | :--- | :--- |\n"
  } >>"$SETUP_SUMMARY_FILE"

  eval "export $_SENTINEL_TABLE=true"
}
