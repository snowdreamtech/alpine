#!/bin/sh
# scripts/lib/common.sh - Shared utility library for automation scripts.
#
# This library provides centralized configuration, logging, and helper
# functions used across the project's orchestration layer.
#
# Features:
#   - Standardized colored logging (info, success, warn, error).
#   - Robust downloading with retry and proxy logic.
#   - Operation throttling (24h cooldown for heavy tasks).
#   - Build-then-Swap atomic file operations.
#   - POSIX-compliant environment detections.

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

# ── 🔨 SSoT Tool Versions ────────────────────────────────────────────────────

GITLEAKS_VERSION="${GITLEAKS_VERSION:-v8.30.0}"
HADOLINT_VERSION="${HADOLINT_VERSION:-v2.14.0}"
GOLANGCI_VERSION="${GOLANGCI_VERSION:-v1.64.5}"
CHECKMAKE_VERSION="${CHECKMAKE_VERSION:-v0.3.2}"
TFLINT_VERSION="${TFLINT_VERSION:-v0.61.0}"
KUBE_LINTER_VERSION="${KUBE_LINTER_VERSION:-v0.8.1}"
JAVA_FORMAT_VERSION="${JAVA_FORMAT_VERSION:-1.34.1}"
PHP_CS_FIXER_VERSION="${PHP_CS_FIXER_VERSION:-v3.94.2}"
OSV_SCANNER_VERSION="${OSV_SCANNER_VERSION:-v1.9.2}"
TRIVY_VERSION="${TRIVY_VERSION:-v0.69.3}"

# Export versions for sub-shells
export GITLEAKS_VERSION HADOLINT_VERSION GOLANGCI_VERSION CHECKMAKE_VERSION
export TFLINT_VERSION KUBE_LINTER_VERSION JAVA_FORMAT_VERSION PHP_CS_FIXER_VERSION
export OSV_SCANNER_VERSION TRIVY_VERSION

# ── 📢 Standardized Logging ──────────────────────────────────────────────────

# Standardized logging functions for consistent colored output.
# @param $1 - Message to log
log_info() {
  local _msg="$1"
  if [ "${VERBOSE:-1}" -ge 1 ]; then printf "%s%b%s\n" "$BLUE" "$_msg" "$NC"; fi
}
log_success() {
  local _msg="$1"
  if [ "${VERBOSE:-1}" -ge 1 ]; then printf "%s%b%s\n" "$GREEN" "$_msg" "$NC"; fi
}
log_warn() {
  local _msg="$1"
  if [ "${VERBOSE:-1}" -ge 1 ]; then printf "%s%b%s\n" "$YELLOW" "$_msg" "$NC"; fi
}
log_error() {
  local _msg="$1"
  printf "%s%b%s\n" "$RED" "$_msg" "$NC" >&2
}
log_debug() {
  local _msg="$1"
  if [ "${VERBOSE:-1}" -ge 2 ]; then printf "[DEBUG] %b\n" "$_msg"; fi
}

# Verifies that the current working directory is the project root.
# Exit 1 if critical root files (Makefile or package.json) are missing.
guard_project_root() {
  if [ ! -f "Makefile" ] && [ ! -f "package.json" ]; then
    log_error "Error: This script must be run from the project root."
    exit 1
  fi
}

# Checks if a task is within its cooldown period to avoid redundant high-cost operations.
# @param $1 - Task name (used for marker filename)
# @param $2 - Cooldown duration in seconds (default: 86400 / 24h)
# @returns 0 if cooldown expired (update needed), 1 if within cooldown
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

# Persists the current timestamp for a specific task to manage its cooldown.
# @param $1 - Task name
save_update_timestamp() {
  local _NAME_TS="$1"
  local _MARKER_TS="${VENV}/.last_update_${_NAME_TS}"
  mkdir -p "$(dirname "$_MARKER_TS")"
  date +%s >"$_MARKER_TS"
}

# Downloads a file from a URL with built-in retries and proxy fallback.
# @param $1 - Source URL
# @param $2 - Target destination path
# @param $3 - Description of the item for logging
# @returns 0 on success, 1 on fatal failure
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

# Verifies the SHA256 checksum of a file.
# @param $1 - Path to the file
# @param $2 - Expected SHA256 hash
# @returns 0 if verified, 1 on mismatch
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

# Verifies if a required runtime or tool is available in the environment.
# Silently exits the script (skip) if the runtime is missing, assuming it's an optional module.
# @param $1 - Command/Binary name to check
# @param $2 - Human-readable tool name for logging
check_runtime() {
  local _RT_NAME="$1"
  local _TOOL_DESC="${2:-Tool}"
  if ! command -v "$_RT_NAME" >/dev/null 2>&1; then
    log_warn "⏭️  Required runtime '$_RT_NAME' for $_TOOL_DESC is missing. Skipping."
    exit 0
  fi
}

# Identifies the primary package manager on macOS (Homebrew or MacPorts).
# @returns "brew", "port", or "none"
get_macos_pkg_mgr() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew"
  elif command -v port >/dev/null 2>&1; then
    echo "port"
  else
    echo "none"
  fi
}

# Detects if the project uses a specific language based on manifest files or file extensions.
# @param $1 - Space-separated list of manifest files (e.g., "go.mod package.json")
# @param $2 - Space-separated list of file globs (e.g., "*.go *.ts")
# @returns 0 if detected, 1 otherwise
has_lang_files() {
  local _FILES_LANG="$1"
  local _EXTS_LANG="$2"

  # 1. Check for specific config files in root
  local _f
  for _f in $_FILES_LANG; do
    [ -f "$_f" ] && return 0
  done

  # 2. Check for file extensions (recursive, maxdepth 3 for performance)
  local _ext
  for _ext in $_EXTS_LANG; do
    # Use find for POSIX compatibility and performance
    if [ "$(find . -maxdepth 3 -name "$_ext" -print -quit 2>/dev/null)" ]; then
      return 0
    fi
  done

  return 1
}

# Dynamically detects the project version from various manifests (package.json, Cargo.toml, pyproject.toml, VERSION).
# @returns The detected version string (e.g., "1.2.3") or "0.0.0" as fallback.
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

# Executes an npm/pnpm script while preventing infinite recursion if the script delegates back to itself.
# @param $1 - Name of the script to run (e.g., "test", "build")
run_npm_script() {
  local _SCRIPT_NAME_NPM="$1"
  local _CURRENT_SCRIPT_NPM
  _CURRENT_SCRIPT_NPM=$(basename "$0")

  if [ -f "$PACKAGE_JSON" ]; then
    local _CMD_NPM
    _CMD_NPM=$(grep "\"$_SCRIPT_NAME_NPM\":" "$PACKAGE_JSON" | sed "s/.*\"$_SCRIPT_NAME_NPM\":[[:space:]]*\"//;s/\".*//" || true)
    if [ -n "$_CMD_NPM" ]; then
      # Avoid infinite loop if the command points back to this script
      if echo "$_CMD_NPM" | grep -q "$_CURRENT_SCRIPT_NPM"; then
        log_debug "npm script '$_SCRIPT_NAME_NPM' is a self-reference to '$_CURRENT_SCRIPT_NPM'. Skipping."
        return 0
      fi
      log_info "── Running Node.js script: $NPM $_SCRIPT_NAME_NPM ──"
      "$NPM" run "$_SCRIPT_NAME_NPM"
      return 0
    fi
  fi
  return 0
}

# Executes a command while suppressing output if the quiet flag (-q/--quiet) is active.
# @param $@ - Command and arguments to execute
run_quiet() {
  if [ "${VERBOSE:-1}" -eq 0 ]; then
    "$@" >/dev/null 2>&1
  else
    "$@"
  fi
}

# Performs an atomic file swap using the Build-then-Swap pattern.
# @param $1 - Source (temporary) file path
# @param $2 - Target destination path
# @returns 0 on success, 1 if source is missing
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

# Standardizes argument parsing for global flags across all project scripts.
# Handles: --dry-run, -q/--quiet, -v/--verbose, -h/--help
# @param $@ - Script arguments
parse_common_args() {
  local _arg_parse
  for _arg_parse in "$@"; do
    case "$_arg_parse" in
    --dry-run)
      # shellcheck disable=SC2034
      DRY_RUN=1
      log_warn "Running in DRY-RUN mode. No changes will be applied."
      ;;
    -q | --quiet) # shellcheck disable=SC2034
      VERBOSE=0 ;;
    -v | --verbose) # shellcheck disable=SC2034
      VERBOSE=2 ;;
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
# ── Summary Helpers ─────────────────────────────────────────────────────────

# Appends a standardized status row to the shared summary report.
# @param $1 - Category (e.g., "Runtime", "Tool", "Audit")
# @param $2 - Module name (e.g., "Node.js", "Gitleaks")
# @param $3 - Status indicator (e.g., "✅ Success", "❌ Failed")
# @param $4 - Version detected (or "-" if N/A)
# @param $5 - Duration in seconds
# @param $6 - Override path to summary file (internal use)
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

# Safely extracts the version string from a binary or command.
# @param $1 - Command or binary path
# @param $2 - Version argument (default: --version)
# @returns The extracted version number or "-" if not detected.
get_version() {
  local _CMD_VER="$1"
  local _ARG_VER="${2:---version}"
  if command -v "$_CMD_VER" >/dev/null 2>&1; then
    # Standard version extraction: find the first sequence starting with a digit
    case "$_CMD_VER" in
    node | python | go | cargo | dotnet | dart | pwsh)
      "$_CMD_VER" "$_ARG_VER" 2>&1 | head -n 1 | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15
      ;;
    pip-audit)
      # pip-audit version output: "pip-audit 2.8.0" or with warnings
      "$_CMD_VER" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
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
