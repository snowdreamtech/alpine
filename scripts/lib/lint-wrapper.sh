#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/lib/lint-wrapper.sh - Robust wrapper for pre-commit hooks.
#
# Purpose:
#   Ensures that optional linters skip gracefully if specialized tools
#   or runtimes are missing, maintaining cross-platform integrity.
#
# Usage:
#   sh scripts/lib/lint-wrapper.sh LINTER_NAME [ARGS...]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 02 (Coding Style).
#
# Features:
#   - Dynamic binary resolution (.venv, node_modules, PATH).
#   - Native runtime detection (Java, Ruby, Node, Dart, DOTNET).
#   - OS-specific guards (Apple Swift).
set -eu

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "${0:-}")" && pwd)
. "${SCRIPT_DIR:-}/common.sh"

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Main entry point for the linter delegation engine.
#          Resolves the linter binary path and performs language-specific checks.
# Params:
#   $1 - Linter binary/hook name (e.g., "eslint", "gofmt")
#   $@ - Arguments passed to the linter
# Examples:
#   main eslint --fix path/to/file.js
main() {
  local _LINTER_WRAP="${1:-}"
  [ -z "${_LINTER_WRAP:-}" ] && return 0
  shift

  # 1. Resolve Binary Path
  local _LINTER_BIN="${_LINTER_WRAP:-}"
  case "${_LINTER_WRAP:-}" in
  psscriptanalyzer) _LINTER_BIN="pwsh" ;;
  osv_scanner) _LINTER_BIN="osv-scanner" ;;
  node-audit)
    # node-audit is a logical tool, we resolve the package manager instead
    _LINTER_BIN="${NPM:-pnpm}"
    ;;
  esac

  local _RESOLVED_BIN_WRAP
  _RESOLVED_BIN_WRAP=$(resolve_bin "${_LINTER_BIN:-}") || true

  # 2. Check Existence
  if [ -z "${_RESOLVED_BIN_WRAP:-}" ]; then
    if [ "${_G_AUDIT_MODE:-0}" -eq 1 ]; then
      log_error "❌ ${_LINTER_WRAP:-} not found but required in AUDIT mode. Failing."
      exit 1
    fi
    log_warn "⚠️  ${_LINTER_WRAP:-} not found. Skipping linting for this module."
    log_info "💡 Run 'make setup' to install required tools."
    exit 0
  fi

  # 3. Special Runtime Checks (Fail-Fast for missing language foundations)
  case "${_LINTER_WRAP:-}" in
  rubocop) check_runtime ruby "${_LINTER_WRAP:-}" ;;
  dart) check_runtime dart "${_LINTER_WRAP:-}" ;;
  mix) check_runtime elixir "${_LINTER_WRAP:-}" ;;
  scalafmt | google-java-format | ktlint) check_runtime java "${_LINTER_WRAP:-}" ;;
  ormolu)
    if [ "${_G_OS:-}" = "windows" ]; then
      log_info "⏭️  ormolu (Haskell) is skipped on Windows CI due to GHC candidate availability. Skipping."
      exit 0
    fi
    check_runtime haskell "${_LINTER_WRAP:-}"
    ;;
  eslint | prettier | stylelint | spectral | sort-package-json | markdownlint-cli2 | taplo | dockerfile-utils | commitlint | node-audit)
    check_runtime node "${_LINTER_WRAP:-}"
    ;;
  psscriptanalyzer)
    # Binary is pwsh, but check_runtime can use pwsh direct or a module if we had one
    check_runtime pwsh "${_LINTER_WRAP:-}"
    ;;
  swiftformat | swiftlint)
    if [ "$(uname -s)" != "Darwin" ]; then
      log_info "⏭️  ${_LINTER_WRAP:-} is only supported on macOS. Skipping."
      exit 0
    fi
    check_runtime swift "${_LINTER_WRAP:-}"
    ;;
  dotnet) check_runtime dotnet "${_LINTER_WRAP:-}" ;;
  gofmt) check_runtime go "${_LINTER_WRAP:-}" ;;
  cargo) check_runtime rust "${_LINTER_WRAP:-}" ;;
  osv_scanner | trivy | checkov | semgrep)
    # Generic binaries or cross-language tools
    # check_runtime will use resolve_bin to find them
    # For osv_scanner, we mapped it to osv-scanner binary in step 1
    check_runtime "${_LINTER_BIN:-}" "${_LINTER_WRAP:-}"
    ;;
  bandit) check_runtime python "${_LINTER_WRAP:-}" ;;
  gosec | govulncheck) check_runtime go "${_LINTER_WRAP:-}" ;;
  cargo-audit) check_runtime rust "${_LINTER_WRAP:-}" ;;
  *)
    # Generic fallback for other binary tools (yamllint, etc.)
    # If a module exists for the tool name, it will be used.
    check_runtime "${_LINTER_WRAP:-}" "${_LINTER_WRAP:-}"
    ;;
  esac

  # 4. Execute Linter
  # shellcheck disable=SC2086
  if [ "${_LINTER_WRAP:-}" = "node-audit" ]; then
    # logical case: call package manager audit command
    exec "${_RESOLVED_BIN_WRAP:-}" audit "$@"
  fi

  exec "${_RESOLVED_BIN_WRAP:-}" "$@"
}

main "$@"
