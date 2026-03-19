#!/usr/bin/env sh
# Starlark Logic Module

# Purpose: Installs Bazel (for Starlark) via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_starlark() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Bazel via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "bazel@$(get_mise_tool_version bazel)"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Starlark environment for project.
setup_starlark() {
  if ! has_lang_files "BUILD WORKSPACE MODULE.bazel" "*.star *.bzl"; then
    return 0
  fi

  local _T0_STAR_RT
  _T0_STAR_RT=$(date +%s)
  _log_setup "Starlark" "bazel"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Starlark" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_STAR_RT="✅ Installed"
  install_runtime_starlark || _STAT_STAR_RT="❌ Failed"

  local _DUR_STAR_RT
  _DUR_STAR_RT=$(($(date +%s) - _T0_STAR_RT))
  log_summary "Runtime" "Starlark" "$_STAT_STAR_RT" "$(get_version bazel --version | awk '{print $NF}')" "$_DUR_STAR_RT"
}

# Purpose: Checks if Bazel is available.
# Examples:
#   check_runtime_starlark "Linter"
check_runtime_starlark() {
  local _TOOL_DESC_STAR="${1:-Starlark}"
  if ! command -v bazel >/dev/null 2>&1; then
    log_warn "Required runtime 'bazel' for $_TOOL_DESC_STAR is missing. Skipping."
    return 1
  fi
  return 0
}
