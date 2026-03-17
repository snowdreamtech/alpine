#!/usr/bin/env sh
# OCaml Logic Module

# Purpose: Installs OCaml and OPAM via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_ocaml() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install OCaml via mise."
    return 0
  fi

  # shellcheck disable=SC2154
  run_mise install "ocaml@${MISE_TOOL_VERSION_OCAML}"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up OCaml environment for project.
setup_ocaml() {
  local _T0_OCM_RT
  _T0_OCM_RT=$(date +%s)
  _log_setup "OCaml" "ocaml"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "OCaml" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect OCaml files
  # opam files, dune files, or .ml/.mli files
  if ! has_lang_files "dune-project dune opam" "*.ml *.mli *.mll *.mly"; then
    log_summary "Runtime" "OCaml" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_OCM_RT="✅ Installed"
  install_runtime_ocaml || _STAT_OCM_RT="❌ Failed"

  local _DUR_OCM_RT
  _DUR_OCM_RT=$(($(date +%s) - _T0_OCM_RT))
  log_summary "Runtime" "OCaml" "$_STAT_OCM_RT" "$(get_version ocaml --version | head -n 1)" "$_DUR_OCM_RT"
}

# Purpose: Checks if OCaml is available.
# Examples:
#   check_runtime_ocaml "Linter"
check_runtime_ocaml() {
  local _TOOL_DESC_OCM="${1:-OCaml}"
  if ! command -v ocaml >/dev/null 2>&1; then
    log_warn "Required runtime 'ocaml' for $_TOOL_DESC_OCM is missing. Skipping."
    return 1
  fi
  return 0
}
