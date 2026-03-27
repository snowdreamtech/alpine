#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

# ── 🛠️ POSIX realpath Fallback ───────────────────────────────────────────────
# Ensures compatibility for tools/plugins that expect 'realpath' (missing on macOS/minimal systems).
if ! command -v realpath >/dev/null 2>&1; then
  if command -v grealpath >/dev/null 2>&1; then
    realpath() { grealpath "$@"; }
  elif command -v python3 >/dev/null 2>&1; then
    realpath() { python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$1"; }
  elif command -v perl >/dev/null 2>&1; then
    realpath() { perl -MCwd -e 'print Cwd::abs_path($ARGV[0])' "$1"; }
  fi
  # shellcheck disable=SC3045
  export -f realpath 2>/dev/null || true
fi

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
  _G_MISE_SHIMS_BASE="${_G_APP_DATA_LOCAL:-${HOME:-}/AppData/Local}/mise/shims"
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
export MISE_QUIET=true
# Suppress mise's built-in update checker to avoid GitHub API calls on every invocation.
export MISE_CHECK_FOR_UPDATES=0
# Force mise to use system git for better proxy/config compatibility
export MISE_GIT_ALWAYS_USE_GIX=0
export MISE_GIX=0
export MISE_USE_GIX=0
# In CI, ensure GitHub tokens are correctly normalized for both mise and GitHub CLI (gh).
# This MUST happen at bootstrap, before any direct tool invocation.
if [ -n "${GITHUB_TOKEN:-}" ]; then
  # mise-specific token variable
  [ -z "${MISE_GITHUB_TOKEN:-}" ] && export MISE_GITHUB_TOKEN="$GITHUB_TOKEN"
  # GitHub CLI (gh) preferred variable
  [ -z "${GH_TOKEN:-}" ] && export GH_TOKEN="$GITHUB_TOKEN"
fi

# ──  Project Context Detection ──────────────────────────────────────────────
# robustly identify the project root directory relative to the script location.
if [ -z "${_G_PROJECT_ROOT:-}" ]; then
  # Unified Context Detection: Prioritize physical location of the CALLING script ($0).
  # This avoids dependency on caller-defined variables like SCRIPT_DIR.
  _G_CALLER_DIR=$(cd "$(dirname "$0")" && pwd)
  if [ -f "$_G_CALLER_DIR/lib/common.sh" ]; then
    # Caller is in 'scripts/' folder (Standard Orchestration pattern).
    _G_LIB_DIR="$_G_CALLER_DIR/lib"
    _G_PROJECT_ROOT=$(cd "$_G_CALLER_DIR/.." && pwd)
  elif [ -f "$_G_CALLER_DIR/scripts/lib/common.sh" ]; then
    # Caller is in project root (Mock tests or direct root execution).
    _G_LIB_DIR="$_G_CALLER_DIR/scripts/lib"
    _G_PROJECT_ROOT="$_G_CALLER_DIR"
  elif [ -f "$_G_CALLER_DIR/common.sh" ]; then
    # Caller is inside 'scripts/lib/' folder itself.
    _G_LIB_DIR="$_G_CALLER_DIR"
    _G_PROJECT_ROOT=$(cd "$_G_CALLER_DIR/../.." && pwd)
  fi

  # Fallback: Multi-Marker Sentinel (If $0 doesn't lead to library or for direct sourcing)
  if [ -z "${_G_PROJECT_ROOT:-}" ]; then
    if [ -n "${SCRIPT_DIR:-}" ]; then
      if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
        _G_LIB_DIR="$SCRIPT_DIR/lib"
        _G_PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
      elif [ -f "$SCRIPT_DIR/scripts/lib/common.sh" ]; then
        _G_LIB_DIR="$SCRIPT_DIR/scripts/lib"
        _G_PROJECT_ROOT="$SCRIPT_DIR"
      elif [ -f "$SCRIPT_DIR/common.sh" ]; then
        _G_LIB_DIR="$SCRIPT_DIR"
        _G_PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
      fi
    fi
  fi

  # Final Fallback: Traverse upwards from PWD (for direct library sourcing or missing markers)
  if [ -z "${_G_PROJECT_ROOT:-}" ]; then
    # Try markers starting from PWD traversal
    _G_PROJECT_ROOT=$(pwd)
    while [ "${_G_PROJECT_ROOT:-}" != "/" ] && [ "${_G_PROJECT_ROOT:-}" != "." ]; do
      if [ -f "$_G_PROJECT_ROOT/package.json" ] || [ -f "$_G_PROJECT_ROOT/Makefile" ] || [ -d "$_G_PROJECT_ROOT/.git" ]; then
        break
      fi
      _G_PROJECT_ROOT=$(dirname "$_G_PROJECT_ROOT")
    done
  fi
  export _G_PROJECT_ROOT
fi
# ── 📊 CI Step Summary Abstraction (Cross-Platform) ──────────────────────────
# Detect and unify CI summary reporting paths (GitHub, GitLab, Gitea, Local).
# Ref: Rule 09 (Interaction/Summary Integration)
if [ -n "${GITHUB_STEP_SUMMARY:-}" ] && [ -z "${GITEA_ACTIONS:-}" ] && [ -z "${FORGEJO_ACTIONS:-}" ]; then
  # GitHub Actions: Native summary file
  CI_STEP_SUMMARY="$GITHUB_STEP_SUMMARY"
elif [ -n "${GITEA_ACTIONS:-}" ] || [ -n "${FORGEJO_ACTIONS:-}" ]; then
  # Gitea/Forgejo: Often follows GitHub conventions but may need fallback
  CI_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-${_G_PROJECT_ROOT:-}/.ci_summary.log}"
elif [ -n "${GITLAB_CI:-}" ]; then
  # GitLab: Use a standard log file that can be rendered as an artifact
  CI_STEP_SUMMARY="${_G_PROJECT_ROOT}/ci_summary.md"
else
  # Local Development / Other environments: Default to a local log file
  CI_STEP_SUMMARY="${_G_PROJECT_ROOT}/.ci_summary.log"
fi
export CI_STEP_SUMMARY

# Mandatory Fallback: Ensure CI_STEP_SUMMARY is NEVER empty (fixes "cannot create : Directory nonexistent")
if [ -z "${CI_STEP_SUMMARY:-}" ]; then
  CI_STEP_SUMMARY="${_G_PROJECT_ROOT:-.}/.ci_summary.log"
fi
export CI_STEP_SUMMARY

# In CI, prevent mise from fetching remote version lists from GitHub.
# All versions are pinned in .mise.toml / versions.sh, so remote lookups are unnecessary
# and are the biggest hidden source of GitHub API calls during `mise install`.
if [ "${CI:-}" = "true" ] || [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  export MISE_FETCH_REMOTE_VERSIONS_TIMEOUT=30s
fi

# Orchestration tracking (detect if we are running as a sub-script)
if [ -z "${_SNOWDREAM_TOP_LEVEL_SCRIPT:-}" ]; then
  _SCRIPT_NAME=$(basename "$0")
  export _SNOWDREAM_TOP_LEVEL_SCRIPT="$_SCRIPT_NAME"
  _IS_TOP_LEVEL=true
else
  _IS_TOP_LEVEL=false
fi

# ── 📄 SSoT Constants (Paths and Files) ──────────────────────────────────────

VENV="${VENV:-.venv}"
PYTHON="${PYTHON:-python3}"

# ── 🛣️ PATH Augmentation ──────────────────────────────────────────────────────

# Automatically add local bin directories to PATH to ensure orchestrated tools
# are prioritized over system globals without requiring manual activation.
_LOCAL_BIN_VENV=$(pwd)/${VENV}/${_G_VENV_BIN}
_LOCAL_BIN_NODE=$(pwd)/node_modules/.bin
_LOCAL_MISE_BIN="$_G_MISE_BIN_BASE"
_LOCAL_MISE_SHIMS="$_G_MISE_SHIMS_BASE"

# Resilience: Always attempt to add these paths to ensure toolchain availability
# even if directories are created later (like during setup JIT).
case ":$PATH:" in
*":$_LOCAL_MISE_BIN:"*) ;;
*) export PATH="$_LOCAL_MISE_BIN:$PATH" ;;
esac

case ":$PATH:" in
*":$_LOCAL_MISE_SHIMS:"*) ;;
*) export PATH="$_LOCAL_MISE_SHIMS:$PATH" ;;
esac

case ":$PATH:" in
*":$_LOCAL_BIN_VENV:"*) ;;
*) export PATH="$_LOCAL_BIN_VENV:$PATH" ;;
esac

case ":$PATH:" in
*":$_LOCAL_BIN_NODE:"*) ;;
*) export PATH="$_LOCAL_BIN_NODE:$PATH" ;;
esac

# Purpose: Dynamically detects the Node.js package manager based on lockfiles.
# Returns: "pnpm", "yarn", "bun", or "npm".
_detect_node_manager() {
  if [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "bun.lockb" ]; then
    echo "bun"
  elif [ -f "package-lock.json" ]; then
    echo "npm"
  elif command -v pnpm >/dev/null 2>&1; then
    echo "pnpm"
  elif command -v yarn >/dev/null 2>&1; then
    echo "yarn"
  elif command -v bun >/dev/null 2>&1; then
    echo "bun"
  else
    echo "npm"
  fi
}

# Dynamically# Purpose: Runs a Node.js package manager script safely.
if [ -z "${NPM:-}" ]; then
  NPM=$(_detect_node_manager)
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
GITHUB_PROXY="${GITHUB_PROXY:-https://gh-proxy.sn0wdr1am.com/}"

# ── 🔨 SSoT Tool Versions ────────────────────────────────────────────────────

# Runtime versions (Managed via .mise.toml, but some logic might still reference these for bootstrap purposes)
# Only MISE is hardcoded here to facilitate the zero-dependency bootstrap phase.
MISE_VERSION="${MISE_VERSION:-2026.3.8}"

# Note: All other tools (Gitleaks, Shellcheck, Shfmt, Java Format, etc.) are purely managed
# by the project's .mise.toml file. Do not add hardcoded version variables here.
# Any tool added below MUST have a corresponding entry in .mise.toml Tools section.

# Standardized library directory reference (calculated during early detection)
_G_LIB_DIR="${_G_LIB_DIR:-${_G_PROJECT_ROOT:-}/scripts/lib}"
export _G_LIB_DIR

# ── 🛣️ CI Persistence (GitHub Actions) ───────────────────────────────────────

if [ "${GITHUB_ACTIONS:-}" = "true" ] && [ -n "${GITHUB_PATH:-}" ]; then
  # Proactively add mise paths to GITHUB_PATH using absolute references.
  # Note: GitHub Actions expects the runner's native path format.
  _M_BIN_CI="$_G_MISE_BIN_BASE"
  _M_SHIMS_CI="$_G_MISE_SHIMS_BASE"

  if [ "${_G_OS:-}" = "windows" ] && command -v cygpath >/dev/null 2>&1; then
    _M_BIN_CI=$(cygpath -w "$_M_BIN_CI")
    _M_SHIMS_CI=$(cygpath -w "$_M_SHIMS_CI")
  fi

  case ":$PATH:" in
  *":$_G_MISE_BIN_BASE:"*) ;;
  *) echo "$_M_BIN_CI" >>"$GITHUB_PATH" ;;
  esac

  case ":$PATH:" in
  *":$_G_MISE_SHIMS_BASE:"*) ;;
  *) echo "$_M_SHIMS_CI" >>"$GITHUB_PATH" ;;
  esac
fi

# ── 🪄 Mise Bootstrap ────────────────────────────────────────────────────────
# Logic extracted to ./lib/bootstrap.sh
# shellcheck source=/dev/null
. "${_G_LIB_DIR}/bootstrap.sh"

# Purpose: Runs a command with a timeout, handling gtimeout (macOS) and timeout (Linux).
# Params:
#   $1 - Timeout in seconds
#   $@ - Command and arguments
run_with_timeout() {
  local _SEC="$1"
  shift
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$_SEC" "$@"
  elif command -v timeout >/dev/null 2>&1; then
    timeout "$_SEC" "$@"
  else
    "$@"
  fi
}

# ── 🌐 Network Optimization ──────────────────────────────────────────────────

# Purpose: Dynamically detects network connectivity and applies mirrors/proxies.
#          Tests access to GitHub and handles broken global git/proxy settings.
# Examples:
#   optimize_network
optimize_network() {
  if [ "${_NETWORK_OPTIMIZED:-}" = "true" ]; then return 0; fi

  local _TEMP_GIT_CONFIG
  _TEMP_GIT_CONFIG="${TMPDIR:-/tmp}/.git_config_$(id -u)"

  log_debug "Detecting network connectivity and global proxy health..."

  # 1. Handle Git Protocols & Proxies
  # Guard: If GITHUB_TOKEN is set, verify it's not broken (avoid 401 errors).
  # Test via `/rate_limit` endpoint because GitHub Bot tokens lack `/user` access.
  # Cache: Skip verification if already validated within the last hour (3600s)
  # to avoid hitting the GitHub API on every script invocation.
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    local _TOKEN_CACHE
    _TOKEN_CACHE="${TMPDIR:-/tmp}/.mise_token_verified_$(id -u)"
    local _SKIP_VERIFY=false
    if [ -f "$_TOKEN_CACHE" ]; then
      local _CACHE_AGE=0
      if [ "${_G_OS:-}" = "macos" ]; then
        _CACHE_AGE=$(($(date +%s) - $(stat -f %m "$_TOKEN_CACHE")))
      else
        # Linux and Windows (Git Bash) both use GNU stat
        _CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$_TOKEN_CACHE" 2>/dev/null || echo "0")))
      fi
      [ "$_CACHE_AGE" -lt 3600 ] && _SKIP_VERIFY=true
    fi

    if [ "${_SKIP_VERIFY:-}" = "true" ]; then
      log_debug "GITHUB_TOKEN recently validated (cache age: ${_CACHE_AGE}s). Skipping API check."
    else
      local _HTTP_CODE
      _HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/rate_limit --connect-timeout 2 2>/dev/null || echo "000")
      if [ "${_HTTP_CODE:-}" = "401" ]; then
        log_warn "Current GITHUB_TOKEN appears invalid or unauthorized ($_HTTP_CODE). Unsetting for this session..."
        unset GITHUB_TOKEN
        rm -f "$_TOKEN_CACHE"
      elif [ -z "${_HTTP_CODE:-}" ] || [ "${_HTTP_CODE:-}" = "000" ]; then
        log_debug "Network timeout verifying GITHUB_TOKEN. Keeping token."
      else
        # Token is valid, cache the result
        touch "$_TOKEN_CACHE"
      fi
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

# Purpose: Extracts the configured version of a tool from .mise.toml or VER_* env vars.
# Lookup order:
#   1. Exact key match in .mise.toml
#   2. Basename match in .mise.toml  (e.g. "github:foo/bar" -> "bar")
#   3. VER_<UPPER_NAME> env variable set by scripts/lib/versions.sh (Tier 2 tools)
#   4. Fallback: "latest"
# Params:
#   $1 - Tool name (e.g., "rust", "helm", "github:goreleaser/goreleaser")
# Returns:
#   The pinned version string, or "latest" if not found anywhere.
# Examples:
#   VER=$(get_mise_tool_version "rust")      # -> VER_RUST from versions.sh
#   VER=$(get_mise_tool_version "node")      # -> from .mise.toml
get_mise_tool_version() {
  local _TOOL_NAME_MISE="$1"
  local _MISE_TOM_PATH
  _MISE_TOM_PATH=$(get_project_root)/.mise.toml

  local _VER=""

  if [ -f "$_MISE_TOM_PATH" ]; then
    # 1. Try exact match (including quotes and provider prefix if provider string given)
    _VER=$(grep -E "^\"?${_TOOL_NAME_MISE}\"?[[:space:]]*=" "$_MISE_TOM_PATH" 2>/dev/null |
      sed -E 's/^[^=]*=[[:space:]]*"([^"]*)".*/\1/' | head -n 1 || true)

    # 2. Try matching the "basename" of the tool (e.g. github:foo/bar -> bar)
    if [ -z "${_VER:-}" ]; then
      local _SHORT_NAME
      _SHORT_NAME=$(echo "$_TOOL_NAME_MISE" | sed -E 's/^[^:]+://; s/.*\///')
      _VER=$(grep -E "^\"?([^:]+:)?${_SHORT_NAME}\"?[[:space:]]*=" "$_MISE_TOM_PATH" 2>/dev/null |
        sed -E 's/^[^=]*=[[:space:]]*"([^"]*)".*/\1/' | head -n 1 || true)
    fi
  fi

  # 3. Check VER_<UPPER> env variable from versions.sh (Tier 2 tools not in .mise.toml)
  if [ -z "${_VER:-}" ]; then
    # Normalize: strip provider prefix, take basename, uppercase, replace non-alnum with _
    local _VAR_KEY
    _VAR_KEY=$(echo "$_TOOL_NAME_MISE" |
      sed -E 's/^[^:]+://; s/.*\///' |
      tr '[:lower:]' '[:upper:]' |
      tr -c 'A-Z0-9\n' '_' |
      sed 's/_*$//')
    # Safety: Only eval if key is a valid shell variable name (A-Z, 0-9, _)
    case "$_VAR_KEY" in
    *[!A-Z0-9_]*) ;;
    *) eval "_VER=\${VER_${_VAR_KEY}:-}" ;;
    esac
  fi

  # 4. Fallback to 'latest' if no version is explicitly defined anywhere
  echo "${_VER:-latest}"
}

# Purpose: Executes a mise command with retry logic and intelligent fallback.
# Params:
#   $@ - Command and arguments for mise
# Examples:
#   run_mise install node
run_mise() {
  local _CMD="$1"
  shift

  # Guard: Only unset GITHUB_TOKEN if we are NOT in CI.
  # In CI (GitHub Actions, etc.), we MUST keep the token to avoid 403 Rate Limit errors.
  # optimize_network() has already verified the token's validity during bootstrap.
  local _OLD_GITHUB_TOKEN="$GITHUB_TOKEN"
  if ! is_ci_env; then
    unset GITHUB_TOKEN
  else
    # Ensure MISE_GITHUB_TOKEN is set for mise's internal GitHub API calls.
    # Workflows set this at env level, but ensure it survives subshell/export boundaries.
    if [ -n "${GITHUB_TOKEN:-}" ] && [ -z "${MISE_GITHUB_TOKEN:-}" ]; then
      export MISE_GITHUB_TOKEN="$GITHUB_TOKEN"
      log_debug "Forwarded GITHUB_TOKEN -> MISE_GITHUB_TOKEN for mise."
    fi
  fi

  # Adaptive Lock Forgiveness (ALF)
  # Mise cannot reliably lock source-compiled tools (go: prefix). To prevent CI
  # failures in --locked mode, we automatically drop the strict requirement
  # for these tools while preserving it for the rest of the orchestration.
  local _EFFECTIVE_LOCKED="${MISE_LOCKED:-}"
  if [ "${_CMD:-}" = "install" ]; then
    for _arg in "$@"; do
      case "$_arg" in
      go:*)
        _EFFECTIVE_LOCKED="0"
        break
        ;;
      esac
    done
  fi

  local _M_BIN
  _M_BIN=$(command -v mise || echo "$HOME/.local/bin/mise")
  [ "${_G_OS:-}" = "windows" ] && [ ! -x "$_M_BIN" ] && _M_BIN="${_M_BIN}.exe"

  # Performance Opt: Skip installation if version already matches SSoT
  if [ "${_CMD:-}" = "install" ] && [ -n "${1:-}" ]; then
    local _T_CHECK="$1"
    local _R_VER
    _R_VER=$(get_mise_tool_version "$_T_CHECK")
    local _T_BASE
    _T_BASE=$(echo "$_T_CHECK" | sed -E 's/^([^:]+:)?(@[^/]+\/)?//; s/.*\///') # Fast-path: Check version-aware existence
    local _C_VER
    _C_VER=$(get_version "$_T_BASE" | tr -d '\r')

    if [ "${_C_VER:-}" != "-" ] && [ -n "${_R_VER:-}" ]; then
      # Use prefix matching: e.g. 3.12.0.2 (required) matches 3.12.0 (current)
      case "$_R_VER" in "$_C_VER"*) return 0 ;; esac
    fi

    # Native/Backend Manager Awareness
    case "$_T_CHECK" in
    cargo:*)
      if ! command -v cargo >/dev/null 2>&1; then
        log_error "Cannot install '$_T_CHECK': 'cargo' (Rust) is missing." && return 1
      fi
      ;;
    go:*)
      if ! command -v go >/dev/null 2>&1; then
        log_error "Cannot install '$_T_CHECK': 'go' (Golang) is missing." && return 1
      fi
      ;;
    npm:*)
      if ! command -v npm >/dev/null 2>&1; then
        log_error "Cannot install '$_T_CHECK': 'npm' (Node.js) is missing." && return 1
      fi
      ;;
    esac
  fi

  # ── Execution with Retry & Timeout ──
  local _MAX_RETRIES=3
  local _RETRY_COUNT=0
  local _STATUS=1
  # 120s per attempt to handle large GitHub releases on slow networks.
  # Previously 60s which caused frequent timeouts for tools like moonbit/grain.
  local _T_OUT=120

  local _MISE_OPTS=""
  if [ "${VERBOSE:-1}" -ge 2 ]; then _MISE_OPTS="--verbose"; fi

  while [ $_RETRY_COUNT -lt $_MAX_RETRIES ]; do
    # Wrap in timeout if available
    if command -v gtimeout >/dev/null 2>&1; then
      # shellcheck disable=SC2086
      gtimeout "$_T_OUT" "$_M_BIN" $_MISE_OPTS "$_CMD" "$@"
    elif command -v timeout >/dev/null 2>&1; then
      # shellcheck disable=SC2086
      timeout "$_T_OUT" "$_M_BIN" $_MISE_OPTS "$_CMD" "$@"
    else
      # shellcheck disable=SC2086
      MISE_LOCKED="$_EFFECTIVE_LOCKED" "$_M_BIN" $_MISE_OPTS "$_CMD" "$@"
    fi
    _STATUS=$?
    [ $_STATUS -eq 0 ] && break
    # Exit code 124 = timeout expiry; treat as retryable network failure.
    # Exit codes > 128 = signal (SIGTERM/SIGKILL); abort immediately.
    if [ $_STATUS -gt 128 ] && [ $_STATUS -ne 124 ]; then break; fi

    _RETRY_COUNT=$((_RETRY_COUNT + 1))
    if [ $_RETRY_COUNT -lt $_MAX_RETRIES ]; then
      # Exponential backoff: 1s, 2s, 4s... to recover from transient rate limits.
      local _BACKOFF=$((1 << (_RETRY_COUNT - 1)))
      log_warn "mise $_CMD failed (attempt $_RETRY_COUNT/$_MAX_RETRIES). Retrying in ${_BACKOFF}s..."
      sleep "$_BACKOFF"
    fi
  done

  # Restore GITHUB_TOKEN
  if [ -n "${_OLD_GITHUB_TOKEN:-}" ]; then
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

# Purpose: Attempts to install a tool using native package managers (brew, apt, choco, etc.)
# Params:
#   $1 - Tool/Package name
# Returns:
#   0 - Success
#   1 - Failure or no manager found
install_native_tool() {
  local _PKG="$1"
  [ -z "${_PKG:-}" ] && return 1

  case "$_G_OS" in
  macos)
    if command -v brew >/dev/null 2>&1; then
      log_info "Installing $_PKG via Homebrew..."
      brew install "$_PKG" && return 0
    elif command -v port >/dev/null 2>&1; then
      log_info "Installing $_PKG via MacPorts..."
      sudo port install "$_PKG" && return 0
    fi
    ;;
  linux)
    if command -v apt-get >/dev/null 2>&1; then
      log_info "Installing $_PKG via apt..."
      sudo apt-get update -y && sudo apt-get install -y "$_PKG" && return 0
    elif command -v dnf >/dev/null 2>&1; then
      log_info "Installing $_PKG via dnf..."
      sudo dnf install -y "$_PKG" && return 0
    elif command -v pacman >/dev/null 2>&1; then
      log_info "Installing $_PKG via pacman..."
      sudo pacman -S --noconfirm "$_PKG" && return 0
    fi
    ;;
  windows)
    if command -v choco >/dev/null 2>&1; then
      log_info "Installing $_PKG via Chocolatey..."
      choco install -y "$_PKG" && return 0
    elif command -v scoop >/dev/null 2>&1; then
      log_info "Installing $_PKG via Scoop..."
      scoop install "$_PKG" && return 0
    elif command -v winget >/dev/null 2>&1; then
      log_info "Installing $_PKG via Winget..."
      winget install "$_PKG" && return 0
    fi
    ;;
  esac

  return 1
}

# Purpose: Ensures a tool is available (Check system -> Try Native -> Try Mise).
# Params:
#   $1 - Tool name
#   $2 - Mise provider name (optional, defaults to tool name)
ensure_tool() {
  local _TOOL="$1"
  local _PRV="${2:-${_TOOL:-}}"

  if command -v "$_TOOL" >/dev/null 2>&1; then
    return 0
  fi

  install_native_tool "$_TOOL" && return 0

  if command -v mise >/dev/null 2>&1; then
    run_mise install "$_PRV" && return 0
  fi

  return 1
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
  while [ "${_DIR:-}" != "/" ]; do
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
  [ -n "${CI_STEP_SUMMARY:-}" ] && [ -f "$CI_STEP_SUMMARY" ] && grep -qF "$1" "$CI_STEP_SUMMARY"
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
#   0 - Detected (or Force Setup active)
#   1 - Not detected
#
# NOTE: If the environment variable FORCE_SETUP is set to 1, this function
#       will always return 0 (success). This is useful for pre-provisioning
#       environments (like DevContainer image building) where language-specific
#       tools need to be installed before the actual source code is present.
#
# Examples:
#   if has_lang_files "package.json" "*.ts *.js"; then echo "Node project"; fi
has_lang_files() {
  # Support for pre-provisioning: Skip file detection if force mode is active.
  # This allows 'make setup <lang>' to work in headless/empty environments.
  if [ "${FORCE_SETUP:-0}" -eq 1 ]; then
    return 0
  fi

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
    HCL)
      [ -f ".terraform.lock.hcl" ] && return 0
      [ -f "terragrunt.hcl" ] && return 0
      # HCL is generic, so we also check for .tf files via the find loop later
      ;;
    PROTOC)
      [ -f "buf.yaml" ] && return 0
      # Also check for .proto files via find loop
      _ext_lang="*.proto"
      ;;
    LUA)
      _ext_lang="*.lua"
      ;;
    JUST)
      [ -f "Justfile" ] && return 0
      [ -f ".justfile" ] && return 0
      ;;
    TASK)
      [ -f "Taskfile.yml" ] && return 0
      [ -f "Taskfile.yaml" ] && return 0
      ;;
    ZIG)
      [ -f "build.zig" ] && return 0
      _ext_lang="*.zig"
      ;;
    CUES)
      _ext_lang="*.cue *.jsonnet"
      ;;
    REGO)
      _ext_lang="*.rego"
      ;;
    EDGE)
      # Modern edge/frontend deployment configs
      [ -f "vercel.json" ] && return 0
      [ -f "netlify.toml" ] && return 0
      ;;
    FLUTTER)
      [ -f "pubspec.yaml" ] && return 0
      _ext_lang="*.dart"
      ;;
    RN)
      [ -f "metro.config.js" ] && return 0
      [ -f "metro.config.ts" ] && return 0
      ;;
    PULUMI)
      [ -f "Pulumi.yaml" ] && return 0
      [ -f "Pulumi.stack.yaml" ] && return 0
      ;;
    CROSSPLANE)
      _ext_lang="*.crossplane.yaml"
      ;;
    PLAYWRIGHT)
      [ -f "playwright.config.ts" ] && return 0
      [ -f "playwright.config.js" ] && return 0
      ;;
    CYPRESS)
      [ -f "cypress.config.ts" ] && return 0
      [ -f "cypress.config.js" ] && return 0
      [ -f "cypress.json" ] && return 0
      ;;
    VITEST)
      [ -f "vitest.config.ts" ] && return 0
      [ -f "vitest.config.js" ] && return 0
      ;;
    DOCUSAURUS)
      [ -f "docusaurus.config.js" ] && return 0
      [ -f "docusaurus.config.ts" ] && return 0
      ;;
    MKDOCS)
      [ -f "mkdocs.yml" ] && return 0
      [ -f "mkdocs.yaml" ] && return 0
      ;;
    SPHINX)
      [ -f "conf.py" ] && return 0
      [ -d "docs/source" ] && return 0
      ;;
    JUPYTER)
      _ext_lang="*.ipynb"
      ;;
    DVC)
      [ -d ".dvc" ] && return 0
      [ -f "dvc.yaml" ] && return 0
      ;;
    ELIXIR)
      [ -f "mix.exs" ] && return 0
      _ext_lang="*.ex *.exs"
      ;;
    HASKELL)
      [ -f "stack.yaml" ] && return 0
      [ -f "package.yaml" ] && return 0
      _ext_lang="*.hs *.cabal"
      ;;
    SCALA)
      [ -f "build.sbt" ] && return 0
      _ext_lang="*.scala"
      ;;
    esac

    # Use find for POSIX compatibility and performance
    # Prune common build/dependency/cache/AI/IDE directories to ensure speed
    if [ "$(find . \( -name .git -o -name node_modules -o -name .venv -o -name venv -o -name env -o -name vendor -o -name dist -o -name build -o -name out -o -name target -o -name .next -o -name .nuxt -o -name .output -o -name __pycache__ -o -name .specify -o -name .tmp -o -name tmp -o -name .agent -o -name .agents -o -name .gemini -o -name .trae -o -name .windsurf -o -name .cursor -o -name .cline -o -name .roo -o -name .aide -o -name .bob -o -name .pi -o -name .adal -o -name .aide -o -name .zencoder -o -name .supermaven -o -name .neovate -o -name .qoder -o -name .kode -o -name .mux -o -name .shai -o -name .vibe -o -name .void -o -name .factory -o -name .bob -o -name .crush -o -name .pi -o -name .pochi -o -name .opencode -o -name .iflow -o -name .kilocode -o -name .bito -o -name .amazonq -o -name .codeium -o -name .tabnine -o -name .codegeex -o -name .blackbox -o -name .cody -o -name .continue -o -name .codebuddy -o -name .codex -o -name .cortex -o -name .openhands -o -name .melty -o -name .pearai -o -name .mcpjam -o -name .aider.conf.yml -o -name .commandcode -o -name .goose -o -name .aide -o -name .bob -o -name .pi -o -name .adal \) -prune -o -maxdepth 5 -type f -name "$_ext_lang" -print -quit 2>/dev/null)" ]; then
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
  local _FILE_SUM="${6:-${SETUP_SUMMARY_FILE:-}}"

  if [ -z "${_FILE_SUM:-}" ] || [ ! -f "$_FILE_SUM" ]; then
    return 0
  fi

  # Automatically demote to Warning if status is supposedly Active/Installed but version detection failed
  case "$_STAT_SUM" in
  ✅*)
    if [ "${_VER_SUM:-}" = "-" ] || [ -z "${_VER_SUM:-}" ]; then
      case "$_MOD_SUM" in
      System | Shell | React | Vue | Tailwind | VitePress | Vite | pnpm-deps | Python-Venv | Homebrew | Hooks | Go-Mod | Cargo-Deps | Ruby-Gems | Go | Rust | Pipx) ;; # These are complex or bootstrap components
      *) _STAT_SUM="⚠️ Warning" ;;
      esac
    fi
    ;;
  esac

  printf "| %-12s | %-15s | %-20s | %-15s | %-6s |\n" "$_CAT_SUM" "$_MOD_SUM" "$_STAT_SUM" "$_VER_SUM" "${_DUR_SUM}s" >>"$_FILE_SUM"
}

# Purpose: Safely extracts version strings from various command outputs.
# Params:
#   $1 - Binary or Command name to execute
#   $2 - Argument to fetch version (default: --version)
#   $3 - Optional: Exact Mise plugin/provider name for cache lookup
# Returns:
#   Detected version string (stripped) or "-" if command fails/missing.
# Examples:
#   V=$(get_version "node")
#   V=$(get_version "shfmt" "" "shfmt-py")
get_version() {
  local _CMD_VER="$1"
  local _ARG_VER="${2:---version}"
  local _M_PLUGIN="${3:-${_CMD_VER:-}}"
  [ -z "${_CMD_VER:-}" ] && {
    echo "-"
    return 0
  }

  local _BIN_PATH
  _BIN_PATH=$(command -v "$_CMD_VER" 2>/dev/null || true)

  # 1. Try Mise First (Fast & Reliable for JIT tools)
  # Check mise via cache first (fastest)
  local _MISE_VER_OUT
  # Optimization: Prefer the currently active version; fall back to any installed version
  # to avoid slow shim fallbacks. Using 'first(select(...))' or sort ensures active wins.
  _MISE_VER_OUT=$(echo "$_G_MISE_LS_JSON_CACHE" | jq -r "
    # Priority 1: Exact key match (e.g. 'go' matches only 'go', not 'go-task/task')
    # Priority 2: Provider suffix match (e.g. ':go' or '/go' at end of key)
    # This prevents false positives where short names like 'go' match unrelated
    # tools such as 'github:go-task/task' via substring contains().
    (to_entries[] | select(.key == \"$_M_PLUGIN\")) //
    (to_entries[] | select(.key | endswith(\":$_M_PLUGIN\") or endswith(\"/$_M_PLUGIN\")))
    | .value
    | (map(select(.active==true))[0] // map(select(.installed==true))[0])
    | .version // empty" 2>/dev/null | head -n 1 || true)

  if [ -n "${_MISE_VER_OUT:-}" ] && [ "${_MISE_VER_OUT:-}" != "null" ]; then
    echo "$_MISE_VER_OUT" && return 0
  fi

  # Fallback to system command or mise direct binary
  local _LV_RESOLVED
  _LV_RESOLVED=$(resolve_bin "$_CMD_VER") || true

  if [ -n "${_LV_RESOLVED:-}" ]; then
    # Special cases for tools with unusual version output or slow shims
    case "$_CMD_VER" in
    python*)
      "$_LV_RESOLVED" --version 2>/dev/null | cut -d' ' -f2 && return 0
      ;;
    node)
      "$_LV_RESOLVED" --version 2>/dev/null | sed 's/^v//'
      ;;
    go)
      "$_LV_RESOLVED" version 2>/dev/null | awk '{print $3}' | sed 's/^go//'
      ;;
    java)
      # java -version outputs to stderr and puts version in quotes
      "$_LV_RESOLVED" "$_ARG_VER" 2>&1 | sed -n 's/.*version "\([0-9][0-9.]*\).*/\1/p' | head -n 1
      ;;
    vitepress | docusaurus)
      # Avoid running binaries that might start a dev server on --version/--help
      echo "-"
      ;;
    *)
      # For other binaries, try to get version from the output
      # We strip 'v' or 'V' prefix and focus on the version number
      # Use MISE_OFFLINE=1 to prevent shims from trying to resolve versions over network
      # On Windows, ensures we don't hang on interactive prompts or external lookups.
      # shellcheck disable=SC2155
      local _VERSION_RAW
      _VERSION_RAW="$(MISE_OFFLINE=1 "$_LV_RESOLVED" "$_ARG_VER" 2>/dev/null | tr -d '\r' | sed 's/^[vV]//' | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15 2>/dev/null)"
      echo "${_VERSION_RAW:--}" && return 0
      ;;

    esac
  else
    echo "-"
  fi
}

# Purpose: Resolves the executable path for a tool across venv, node_modules,
#          system PATH, and mise-managed environments (shim + direct install).
# Params:
#   $1 - Binary name (e.g., "eslint", "pytest", "bats")
# Returns:
#   Echoes the resolved path. Exit 0 on success, 1 if not found.
# Environments:
#   - Local dev (with/without mise cache)
#   - CI runners (clean or pre-cached)
#   - Windows (Git Bash/MSYS2), macOS, Linux
# Examples:
#   BIN=$(resolve_bin "eslint") || true
resolve_bin() {
  local _BIN="$1"
  [ -z "${_BIN:-}" ] && return 1

  # ── 1. Python Venv ──
  local _VP="${VENV:-.venv}/$_G_VENV_BIN/$_BIN"
  if [ -x "$_VP" ]; then echo "$_VP" && return 0; fi
  # Windows: venv scripts use .exe suffix
  if [ "${_G_OS:-}" = "windows" ] && [ -x "${_VP}.exe" ]; then echo "${_VP}.exe" && return 0; fi

  # ── 2. Node Modules ──
  local _NP="node_modules/.bin/$_BIN"
  if [ -x "$_NP" ]; then echo "$_NP" && return 0; fi
  # Windows: npm generates .cmd wrappers
  if [ "${_G_OS:-}" = "windows" ] && [ -f "${_NP}.cmd" ]; then echo "${_NP}.cmd" && return 0; fi

  # ── 3. System PATH ──
  local _SP
  _SP=$(command -v "$_BIN" 2>/dev/null) || true

  # Windows: command -v might miss extensions or return sh wrappers
  if [ -z "${_SP:-}" ] && [ "${_G_OS:-}" = "windows" ]; then
    _SP=$(command -v "${_BIN}.exe" 2>/dev/null) || _SP=$(command -v "${_BIN}.cmd" 2>/dev/null) || true
  fi

  if [ -n "${_SP:-}" ]; then
    # Guard: If it resolves to a mise shim, verify the tool is actually installed.
    # Shims exist for ALL tools in .mise.toml, even uninstalled ones ("hollow shims").
    case "$_SP" in
    *"$_G_MISE_SHIMS_BASE"*)
      # Use 'mise which' — the lightweight, jq-free way to validate a shim.
      # Returns the real binary path if installed, non-zero if not.
      local _MW
      _MW=$(mise which "$_BIN" 2>/dev/null) || true
      if [ -n "${_MW:-}" ] && [ -x "$_MW" ]; then
        echo "$_MW" && return 0
      fi
      # Shim is hollow — fall through to Layer 4.
      ;;
    *)
      # Not a shim — it's a real system binary.
      echo "$_SP" && return 0
      ;;
    esac
  fi

  # ── 4. Mise direct lookup (no shim in PATH, e.g., fresh CI) ──
  # Covers: mise installed the tool but shims/PATH not yet activated.
  local _MW
  _MW=$(mise which "$_BIN" 2>/dev/null) || true
  if [ -n "${_MW:-}" ] && [ -x "$_MW" ]; then
    echo "$_MW" && return 0
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

# Purpose: Verifies that a required runtime is available.
#          Gracefully skips (exit 0) if missing, for linter wrappers.
# Params:
#   $1 - Runtime name (e.g., "go", "python")
#   $2 - Tool description (e.g., "Golang Builder")
# Examples:
#   check_runtime "go" "Golang Builder"
check_runtime() {
  local _RT_NAME="$1"
  local _TOOL_DESC="${2:-Tool}"

  # Priority 1: Modular Check Delegation
  # If check_runtime_<name> exists in the environment, delegate to it.
  if command -v "check_runtime_${_RT_NAME}" >/dev/null 2>&1; then
    if ! "check_runtime_${_RT_NAME}" "$_TOOL_DESC"; then
      if [ "${_G_AUDIT_MODE:-0}" -eq 1 ]; then
        return 1
      fi
      exit 0 # Graceful skip for pre-commit
    fi
    return 0
  fi

  # Priority 2: Standard Command Check (Fallback using resolve_bin)
  if ! resolve_bin "$_RT_NAME" >/dev/null 2>&1; then
    log_warn "Required runtime '$_RT_NAME' for $_TOOL_DESC is missing. Skipping."
    if [ "${_G_AUDIT_MODE:-0}" -eq 1 ]; then
      return 1
    fi
    exit 0
  fi
}

# Purpose: Installs the Node.js runtime and project dependencies.
# language-specific modules will be loaded dynamically below

# Logic extracted to modules in ./langs/

# Logic extracted to modules in ./langs/

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
  _PRE_COMMIT_BIN=$(resolve_bin "pre-commit") || true
  if [ -n "${_PRE_COMMIT_BIN:-}" ]; then
    log_info "Running pre-commit install..."
    run_quiet "$_PRE_COMMIT_BIN" install
  else
    log_warn "pre-commit binary not found. Skipping hook installation."
  fi
}

# Purpose: Synchronizes Node.js lockfile safely.
sync_node_lockfile() {
  local _SYNC_DIR="${1:-.}"
  local _OLDPWD_SYNC
  _OLDPWD_SYNC="$(pwd)"

  cd "$_SYNC_DIR" || return 1

  if [ -f "package.json" ]; then
    case "$NPM" in
    pnpm)
      log_info "Syncing Node.js lockfile (pnpm)..."
      run_quiet pnpm install --no-frozen-lockfile
      ;;
    yarn)
      log_info "Syncing Node.js lockfile (yarn)..."
      run_quiet yarn install --no-immutable
      ;;
    bun)
      log_info "Syncing Node.js lockfile (bun)..."
      run_quiet bun install
      ;;
    *)
      log_info "Syncing Node.js lockfile (npm)..."
      run_quiet npm install --package-lock-only
      ;;
    esac
  fi

  cd "$_OLDPWD_SYNC" || exit 1
}

# Purpose: Executes an npm/pnpm script with infinite-recursion detection.
# Params:
#   $1 - Name of the npm script (e.g., "test")
# Examples:
#   run_npm_script "test"
run_npm_script() {
  local _SCRIPT_NAME_NPM="$1"
  shift # Capture remaining arguments
  local _EXTRA_ARGS_NPM="$*"
  local _CURRENT_BASENAME_NPM
  _CURRENT_BASENAME_NPM="$(basename "$0")"

  if [ -f "package.json" ]; then
    # 1. Manager Detection & Guard
    _NODE_MGR="$NPM"

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

    if [ -n "${_CMD_NPM:-}" ]; then
      # Avoid infinite loop if the command points back to this script
      if echo "$_CMD_NPM" | grep -q "$_CURRENT_BASENAME_NPM"; then
        log_debug "Node script '$_SCRIPT_NAME_NPM' is a self-reference to '$_CURRENT_BASENAME_NPM'. Skipping."
        return 0
      fi
      log_info "── Running Node.js script: $_NODE_MGR $_SCRIPT_NAME_NPM $_EXTRA_ARGS_NPM ──"
      # shellcheck disable=SC2086
      "$_NODE_MGR" run "$_SCRIPT_NAME_NPM" $_EXTRA_ARGS_NPM
    elif [ "${_SCRIPT_NAME_NPM:-}" = "install" ] || [ "${_SCRIPT_NAME_NPM:-}" = "update" ]; then
      # 4. Special Fallback for native commands if not defined in package.json scripts
      log_info "── Node.js standard command: $_NODE_MGR $_SCRIPT_NAME_NPM $_EXTRA_ARGS_NPM ──"
      # shellcheck disable=SC2086
      run_quiet "$_NODE_MGR" "$_SCRIPT_NAME_NPM" $_EXTRA_ARGS_NPM
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

  # Sentinel to prevent duplicate headers in the same summary stream
  local _SENTINEL_TABLE
  _SENTINEL_TABLE="_SUMMARY_TABLE_INITIALIZED_$(echo "$_TITLE_TABLE" | tr ' ' '_')"
  if [ "$(eval echo "\${$_SENTINEL_TABLE:-}")" = "true" ]; then
    return 0
  fi

  # Ensure the summary file exists
  touch "$CI_STEP_SUMMARY"

  {
    printf "### %s\n\n" "$_TITLE_TABLE"
    printf "| Category | Module | Status | Version | Time |\n"
    printf "| :--- | :--- | :--- | :--- | :--- |\n"
  } >>"$CI_STEP_SUMMARY"

  eval "export $_SENTINEL_TABLE=true"
}

# Purpose: Finalizes the summary table. (Deprecated: Writes are now direct).
finalize_summary_table() {
  log_debug "Summary table finalized in $CI_STEP_SUMMARY"
}

# Purpose: Checks if the current tool version matches the required version (prefix match).
# Params:
#   $1 - Current version (detected)
#   $2 - Required version (from registry/.mise.toml)
# Returns:
#   0 - Match
#   1 - Mismatch
is_version_match() {
  local _CUR_V_M="$1"
  local _REQ_V_M="$2"
  [ "${_CUR_V_M:- -}" = "-" ] && return 1
  [ -z "${_REQ_V_M:-}" ] && return 1
  [ "${_REQ_V_M:-}" = "latest" ] && return 0
  # Use prefix match to handle diffs like 3.12.0.2 (pkg) vs 3.12.0 (binary)
  case "$_REQ_V_M" in "$_CUR_V_M"*) return 0 ;; esac
  return 1
}

# ── Extension Modules Sourcing ──
# Note: Dynamic loading of language-specific setup modules has been moved to setup.sh
# to optimize performance for non-setup scripts.
