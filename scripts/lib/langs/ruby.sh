#!/usr/bin/env sh
# Ruby Logic Module

# Purpose: Installs Ruby runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_ruby() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Ruby runtime."
    return 0
  fi

  # Runtime initialization
  run_mise install ruby
  eval "$(mise activate bash --shims)"

  # Project dependencies
  if [ -f "Gemfile" ]; then
    run_quiet bundle install
  fi
}

# Purpose: Sets up Ruby runtime and mandatory linting tools.
# Delegate: Managed by mise (.mise.toml)
setup_ruby() {
  local _T0_RUBY_RT
  _T0_RUBY_RT=$(date +%s)
  _log_setup "Ruby Runtime" "ruby"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Ruby" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "Gemfile Gemfile.lock" "*.rb"; then
    log_summary "Runtime" "Ruby" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_RUBY_RT="✅ Installed"
  install_runtime_ruby || _STAT_RUBY_RT="❌ Failed"

  local _DUR_RUBY_RT
  _DUR_RUBY_RT=$(($(date +%s) - _T0_RUBY_RT))
  log_summary "Runtime" "Ruby" "$_STAT_RUBY_RT" "$(get_version ruby)" "$_DUR_RUBY_RT"

  # Also ensure linting tools are present
  install_ruby_lint
}
# Purpose: Checks if Rust runtime is available.
# Examples:
#   check_runtime_rust "Linter"
check_runtime_rust() {
  local _TOOL_DESC_RUBY="${1:-Ruby}"
  if ! command -v ruby >/dev/null 2>&1; then
    log_warn "Required runtime 'ruby' for $_TOOL_DESC_RUBY is missing. Skipping."
    return 1
  fi
  return 0
}
