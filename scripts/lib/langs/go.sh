#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Go Logic Module

# Purpose: Installs Go runtime via mise (version pinned in scripts/lib/versions.sh).
install_runtime_go() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Go runtime."
    return 0
  fi
  run_mise install "go@${VER_GO:-}"
}

# Purpose: Installs golangci-lint for Go projects (version pinned in versions.sh).
install_go_lint() {
  local _T0_GO
  _T0_GO=$(date +%s)
  local _TITLE="Go Lint"
  local _PROVIDER="golangci-lint"

  # Fast-path: Check version-aware existence — avoid re-downloading the large
  # GitHub-released binary (~50MB) on every local setup run.
  local _CUR_VER
  _CUR_VER=$(get_version golangci-lint)
  local _REQ_VER="${VER_GOLANGCI_LINT:-}"

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Go" "Go Lint" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Go" "Go Lint" "⚖️ Previewed" "-" "0"
    return 0
  fi
  local _STAT_GO="✅ mise"
  run_mise install golangci-lint || _STAT_GO="❌ Failed"
  log_summary "Go" "Go Lint" "${_STAT_GO:-}" "$(get_version golangci-lint)" "$(($(date +%s) - _T0_GO))"
}

# Purpose: Installs govulncheck for Go project vulnerability scanning.
# NOTE: CI-only tool — vulnerability scanner. Skipped on local environments.
install_govulncheck() {
  local _T0_GOVC
  _T0_GOVC=$(date +%s)
  local _TITLE="Govulncheck"
  local _PROVIDER="${VER_GOVULNCHECK_PROVIDER:-}"
  if ! is_ci_env; then
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Go" "Govulncheck" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_GOVC="✅ mise"
  run_mise install "${_PROVIDER:-}" || _STAT_GOVC="❌ Failed"
  log_summary "Go" "Govulncheck" "${_STAT_GOVC:-}" "$(get_version govulncheck)" "$(($(date +%s) - _T0_GOVC))"
}

# Purpose: Sets up Go runtime for project.
# Delegate: Managed by mise (.mise.toml)
setup_go() {
  if ! has_lang_files "go.mod go.sum" "*.go"; then
    return 0
  fi

  # Dynamically register Go in .mise.toml if not already present.
  # This is essential for pre-provisioning (e.g., DevContainer builds)
  # where Go is explicitly requested before source files exist.
  setup_registry_go

  local _T0_GO_RT
  _T0_GO_RT=$(date +%s)
  local _TITLE="Go Runtime"
  local _PROVIDER="go"

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version go)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Runtime" "Go" "✅ Detected" "${_CUR_VER:-}" "0"
  else
    _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_summary "Runtime" "Go" "⚖️ Previewed" "-" "0"
    else
      local _STAT_GO_RT="✅ Installed"
      install_runtime_go || _STAT_GO_RT="❌ Failed"

      local _DUR_GO_RT
      _DUR_GO_RT=$(($(date +%s) - _T0_GO_RT))
      log_summary "Runtime" "Go" "${_STAT_GO_RT:-}" "$(get_version go)" "${_DUR_GO_RT:-}"
    fi
  fi

  # Setup related tools
  install_go_lint
  install_govulncheck
}
# Purpose: Checks if Go runtime is available.
# Examples:
#   check_runtime_go "Linter"
check_runtime_go() {
  local _TOOL_DESC_GO="${1:-Go}"
  if ! resolve_bin "go" >/dev/null 2>&1; then
    log_warn "Required runtime 'go' for $_TOOL_DESC_GO is missing. Skipping."
    return 1
  fi
  return 0
}
