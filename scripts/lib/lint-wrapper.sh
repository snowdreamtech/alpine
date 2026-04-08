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

  # Early Return: Optional Security Tools
  # These heavy scanners are NOT registered in .mise.toml and have dedicated
  # coverage in CI audit stages (trivy-action, CodeQL, SARIF uploads).
  # They should skip gracefully in ALL environments (CI and local) when not
  # installed, instead of hard-failing the lint pipeline.
  case "${_LINTER_WRAP:-}" in
  trivy | checkov | semgrep | bandit | zizmor)
    log_warn "⏭️  ${_LINTER_WRAP:-} not available. Skipping (covered by CI audit stage)."
    exit 0
    ;;
  esac

  # 1. Resolve Binary Path
  local _LINTER_BIN="${_LINTER_WRAP:-}"
  local _MISE_TOOL_SPEC=""
  case "${_LINTER_WRAP:-}" in
  psscriptanalyzer) _LINTER_BIN="pwsh" ;;
  osv_scanner) _LINTER_BIN="osv-scanner" ;;
  node-audit)
    # node-audit is a logical tool, we resolve the package manager instead
    _LINTER_BIN="${NPM:-pnpm}"
    ;;
  # Map tool names to mise tool specs for tools with different binary names
  shfmt)
    _MISE_TOOL_SPEC="github:mvdan/sh"
    _LINTER_BIN="shfmt"
    ;;
  taplo)
    _MISE_TOOL_SPEC="npm:@taplo/cli"
    _LINTER_BIN="taplo"
    ;;
  editorconfig-checker)
    _MISE_TOOL_SPEC="github:editorconfig-checker/editorconfig-checker"
    # Binary name is 'ec' with platform-specific suffixes
    # The mise tool spec uses bin = "ec-*" to match all variants
    _LINTER_BIN="ec"
    ;;
  esac

  local _RESOLVED_BIN_WRAP
  _RESOLVED_BIN_WRAP=$(resolve_bin "${_LINTER_BIN:-}") || true

  # 2. Check Existence
  if [ -z "${_RESOLVED_BIN_WRAP:-}" ]; then
    # Dynamic Handler: On-demand Tier 2 tools (not registered in .mise.toml)
    if [ "${_LINTER_WRAP:-}" = "zizmor" ]; then
      local _ZM_SPEC="${VER_ZIZMOR_PROVIDER:-zizmor}@${VER_ZIZMOR:-latest}"
      log_info "── Executing ${_LINTER_WRAP:-} (dynamic) ──"
      # Execute directly with mise exec
      # shellcheck disable=SC2093
      exec mise exec "${_ZM_SPEC:-}" -- zizmor "$@"
    fi

    # CI Fallback: Try mise exec directly if tool not resolved
    # This handles cases where mise shims exist but resolve_bin fails
    if is_ci_env; then
      log_info "Attempting to run ${_LINTER_WRAP:-} via mise exec..."

      # Use tool spec if available, otherwise use binary name
      local _EXEC_TARGET="${_MISE_TOOL_SPEC:-${_LINTER_BIN:-}}"

      # Try to execute the tool first
      if mise exec "${_EXEC_TARGET:-}" -- "${_LINTER_BIN:-}" --version >/dev/null 2>&1; then
        log_info "── Executing ${_LINTER_WRAP:-} via mise exec ──"
        # shellcheck disable=SC2093
        exec mise exec "${_EXEC_TARGET:-}" -- "${_LINTER_BIN:-}" "$@"
      fi

      # Tool execution failed - try to install/reinstall
      log_warn "Tool ${_LINTER_WRAP:-} execution failed. Attempting to (re)install..."

      # Force reinstall by uninstalling first
      mise uninstall "${_EXEC_TARGET:-}" 2>/dev/null || true

      if mise install "${_EXEC_TARGET:-}"; then
        log_info "Successfully installed ${_EXEC_TARGET:-}"
        # Try again after installation
        if mise exec "${_EXEC_TARGET:-}" -- "${_LINTER_BIN:-}" --version >/dev/null 2>&1; then
          log_info "── Executing ${_LINTER_WRAP:-} via mise exec ──"
          # shellcheck disable=SC2093
          exec mise exec "${_EXEC_TARGET:-}" -- "${_LINTER_BIN:-}" "$@"
        fi
      fi

      log_error "❌ ${_LINTER_WRAP:-} not found in CI. Failing."
      log_info "💡 CI environments must have all required tools installed."
      log_info "💡 Tool spec: ${_EXEC_TARGET:-}, Binary: ${_LINTER_BIN:-}"
      exit 1
    fi
    log_warn "⚠️  ${_LINTER_WRAP:-} not found locally. Skipping linting for this module."
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
    # NOTE: Some registries (like npmmirror.com) do not support the audit endpoint.
    # We use the official registry for the audit scan to ensure reliability.
    exec "${_RESOLVED_BIN_WRAP:-}" audit --registry="${NPM_AUDIT_REGISTRY:-https://registry.npmjs.org}" "$@"
  fi

  exec "${_RESOLVED_BIN_WRAP:-}" "$@"
}

main "$@"
