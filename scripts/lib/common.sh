#!/bin/sh
# scripts/lib/common.sh - Shared logic for project scripts.
# Unified logging, colors, and utility functions.
# shellcheck disable=SC2034

# Colors (using printf to generate literal ESC characters for maximum compatibility)
BLUE=$(printf '\033[0;34m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
RED=$(printf '\033[0;31m')
NC=$(printf '\033[0m')

# Default verbosity
# shellcheck disable=SC2034
VERBOSE=${VERBOSE:-1} # 0: quiet, 1: normal, 2: verbose
DRY_RUN=${DRY_RUN:-0}

# SSoT Constants (Paths and Files)
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

# Tool Versions (SSoT)
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

# Logging functions
log_info() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%s%b%s\n" "$BLUE" "$1" "$NC"; fi
}
log_success() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%s%b%s\n" "$GREEN" "$1" "$NC"; fi
}
log_warn() {
  if [ "$VERBOSE" -ge 1 ]; then printf "%s%b%s\n" "$YELLOW" "$1" "$NC"; fi
}
log_error() {
  printf "%s%b%s\n" "$RED" "$1" "$NC" >&2
}
log_debug() {
  if [ "$VERBOSE" -ge 2 ]; then printf "[DEBUG] %b\n" "$1"; fi
}

# Execution context guard
guard_project_root() {
  if [ ! -f "Makefile" ] && [ ! -f "package.json" ]; then
    log_error "Error: This script must be run from the project root."
    exit 1
  fi
}

# Enhanced download helper with retry and proxy fallback
download_url() {
  _URL="$1"
  _OUT="$2"
  _DESC="$3"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_debug "DRY-RUN: Would download $_URL to $_OUT"
    return 0
  fi

  # Ensure output directory exists
  _DIR=$(dirname "$_OUT")
  mkdir -p "$_DIR"

  log_info "Downloading $_DESC..."
  # curl with retry flags as per rules
  if curl --retry 5 --retry-delay 2 --retry-connrefused --fail \
    --connect-timeout 10 --max-time 60 \
    -fsSL "${_URL}" -o "${_OUT}"; then
    return 0
  fi

  # Fallback if proxy failed and it was a proxied URL
  if [ -n "${GITHUB_PROXY}" ] && echo "${_URL}" | grep -q "^${GITHUB_PROXY}"; then
    _FALLBACK_URL="${_URL#"$GITHUB_PROXY"}"
    log_warn "Proxy download failed for ${_DESC}, retrying directly from ${_FALLBACK_URL}..."
    if curl --retry 5 --retry-delay 2 --retry-connrefused --fail \
      --connect-timeout 10 --max-time 60 \
      -fsSL "${_FALLBACK_URL}" -o "${_OUT}"; then
      return 0
    fi
  fi

  log_error "Failed to download $_DESC from $_URL"
  return 1
}

# Checksum verification helper
verify_checksum() {
  _FILE="$1"
  _EXPECTED_SHA="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    log_debug "DRY-RUN: Would verify checksum for $_FILE"
    return 0
  fi

  log_info "Verifying checksum for $(basename "$_FILE")..."
  if command -v sha256sum >/dev/null 2>&1; then
    _ACTUAL_SHA=$(sha256sum "$_FILE" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    _ACTUAL_SHA=$(shasum -a 256 "$_FILE" | awk '{print $1}')
  else
    log_warn "sha256sum/shasum not found. Skipping checksum verification."
    return 0
  fi

  if [ "$_ACTUAL_SHA" != "$_EXPECTED_SHA" ]; then
    log_error "Checksum mismatch for $_FILE!"
    log_error "Expected: $_EXPECTED_SHA"
    log_error "Actual:   $_ACTUAL_SHA"
    return 1
  fi

  log_success "Checksum verified."
  return 0
}

# Graceful runtime check helper
# Usage: check_runtime "node" "LINTER_NAME"
check_runtime() {
  _RT="$1"
  _TOOL="${2:-Tool}"
  if ! command -v "$_RT"; then
    log_warn "⏭️  Required runtime '$_RT' for $_TOOL is missing. Skipping."
    exit 0
  fi
}

# Package manager detection for macOS
get_macos_pkg_mgr() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew"
  elif command -v port >/dev/null 2>&1; then
    echo "port"
  else
    echo "none"
  fi
}

# Universal project version detector
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

# Helper to run npm/pnpm scripts without infinite recursion
run_npm_script() {
  _SCRIPT_NAME="$1"
  _CURRENT_SCRIPT=$(basename "$0")

  if [ -f "$PACKAGE_JSON" ]; then
    _CMD=$(grep "\"$_SCRIPT_NAME\":" "$PACKAGE_JSON" | sed "s/.*\"$_SCRIPT_NAME\":[[:space:]]*\"//;s/\".*//" || true)
    if [ -n "$_CMD" ]; then
      # Avoid infinite loop if the command points back to this script
      if echo "$_CMD" | grep -q "$_CURRENT_SCRIPT"; then
        log_debug "npm script '$_SCRIPT_NAME' is a self-reference to '$_CURRENT_SCRIPT'. Skipping."
        return 0
      fi
      log_info "── Running Node.js script: $NPM $_SCRIPT_NAME ──"
      "$NPM" run "$_SCRIPT_NAME"
    fi
  fi
}

# Helper to run a command while respecting the quiet flag (-q/--quiet)
# Usage: run_quiet cmd arg1 arg2 ...
run_quiet() {
  if [ "$VERBOSE" -eq 0 ]; then
    "$@" >/dev/null 2>&1
  else
    "$@"
  fi
}

# Standard argument parsing for DRY_RUN and VERBOSE
parse_common_args() {
  for _arg in "$@"; do
    case "$_arg" in
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
      show_help
      exit 0
      ;;
    esac
  done
}
# ── Summary Helpers ─────────────────────────────────────────────────────────

log_summary() {
  _CAT="${1:-Other}"
  _MOD="${2:-Unknown}"
  _STAT="${3:-⏭️ Skipped}"
  _VER="${4:--}"
  _DUR="${5:--}"
  _SUMMARY_FILE="${6:-$SETUP_SUMMARY_FILE}"

  if [ -z "$_SUMMARY_FILE" ] || [ ! -f "$_SUMMARY_FILE" ]; then
    return 0
  fi

  # Automatically demote to Warning if status is supposedly Active/Installed but version detection failed
  case "$_STAT" in
  ✅*)
    if [ "$_VER" = "-" ] || [ -z "$_VER" ]; then
      case "$_MOD" in
      System | Shell | React | Vue | Tailwind | VitePress | Vite | pnpm-deps | Python-Venv | Homebrew | Hooks | Go-Mod | Cargo-Deps | Ruby-Gems) ;; # These don't always have a single version command
      *) _STAT="⚠️ Warning" ;;
      esac
    fi
    ;;
  esac

  printf "| %-12s | %-15s | %-20s | %-15s | %-6s |\n" "$_CAT" "$_MOD" "$_STAT" "$_VER" "${_DUR}s" >>"$_SUMMARY_FILE"
}

# Helper to get version safely
get_version() {
  _CMD="$1"
  _ARG="${2:---version}"
  if command -v "$_CMD" >/dev/null 2>&1; then
    # Standard version extraction: find the first sequence starting with a digit
    case "$_CMD" in
    node | python | go | cargo | dotnet | dart | pwsh)
      "$_CMD" "$_ARG" 2>&1 | head -n 1 | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15
      ;;
    pip-audit)
      # pip-audit version output: "pip-audit 2.8.0" or with warnings
      "$_CMD" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
      ;;
    *)
      # For other binaries, try to get version from the output
      "$_CMD" "$_ARG" 2>&1 | head -n 1 | grep -o '[0-9][0-9.]*' | head -n 1 | cut -c1-15
      ;;
    esac
  else
    echo "-"
  fi
}
