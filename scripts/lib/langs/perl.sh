#!/usr/bin/env sh
# Perl Logic Module

# Purpose: Installs Perl runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_perl() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Perl runtime."
    return 0
  fi
  # shellcheck disable=SC2154
  run_mise install "perl@$(get_mise_tool_version perl)"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Perl runtime.
setup_perl() {
  if ! has_lang_files "Makefile.PL Build.PL" "*.pl *.pm"; then
    return 0
  fi

  local _T0_PERL_RT
  _T0_PERL_RT=$(date +%s)
  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version perl)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "perl")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Perl" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "Perl Runtime" "perl"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Perl" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_PERL_RT="✅ Installed"
  install_runtime_perl || _STAT_PERL_RT="❌ Failed"

  local _DUR_PERL_RT
  _DUR_PERL_RT=$(($(date +%s) - _T0_PERL_RT))
  log_summary "Runtime" "Perl" "$_STAT_PERL_RT" "$(get_version perl -v | grep 'v[0-9]' | head -n 1)" "$_DUR_PERL_RT"
}
# Purpose: Checks if Perl runtime is available.
# Examples:
#   check_runtime_perl "Linter"
check_runtime_perl() {
  local _TOOL_DESC_PERL="${1:-Perl}"
  if ! command -v perl >/dev/null 2>&1; then
    log_warn "Required runtime 'perl' for $_TOOL_DESC_PERL is missing. Skipping."
    return 1
  fi
  return 0
}
