#!/usr/bin/env sh
# Lean 4 Logic Module

# Purpose: Installs Lean 4 via mise.
install_runtime_lean() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Lean 4 via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "lean@${MISE_TOOL_VERSION_LEAN}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Lean 4 environment for project.
setup_lean() {
  local _T0_LEAN_RT
  _T0_LEAN_RT=$(date +%s)
  _log_setup "Lean 4" "lean"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Lean 4" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Lean 4 files
  if ! has_lang_files "lean-toolchain lakefile.lean" "*.lean"; then
    log_summary "Runtime" "Lean 4" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_LEAN_RT="✅ Installed"
  install_runtime_lean || _STAT_LEAN_RT="❌ Failed"

  local _DUR_LEAN_RT
  _DUR_LEAN_RT=$(($(date +%s) - _T0_LEAN_RT))
  log_summary "Runtime" "Lean 4" "$_STAT_LEAN_RT" "$(get_version lean --version | awk '{print $NF}')" "$_DUR_LEAN_RT"
}

# Purpose: Checks if Lean 4 is available.
check_runtime_lean() {
  local _TOOL_DESC_LEAN="${1:-Lean 4}"
  if ! command -v lean >/dev/null 2>&1; then
    log_warn "Required runtime 'lean' for $_TOOL_DESC_LEAN is missing. Skipping."
    return 1
  fi
  return 0
}
