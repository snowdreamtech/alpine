#!/usr/bin/env sh
# Clojure Logic Module

# Purpose: Installs Clojure and Leiningen via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_clojure() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Clojure and Leiningen via mise."
    return 0
  fi

  run_mise install clojure
  # shellcheck disable=SC2154
  run_mise install "clojure@$(get_mise_tool_version clojure)"
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Clojure environment for project.
setup_clojure() {
  if ! has_lang_files "project.clj deps.edn bb.edn" "*.clj *.cljs *.cljc *.edn"; then
    return 0
  fi

  local _T0_CLJ_RT
  _T0_CLJ_RT=$(date +%s)
  _log_setup "Clojure" "clojure"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Clojure" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_CLJ_RT="✅ Installed"
  install_runtime_clojure || _STAT_CLJ_RT="❌ Failed"

  local _DUR_CLJ_RT
  _DUR_CLJ_RT=$(($(date +%s) - _T0_CLJ_RT))
  log_summary "Runtime" "Clojure" "$_STAT_CLJ_RT" "$(get_version clojure --version | head -n 1)" "$_DUR_CLJ_RT"
}

# Purpose: Checks if Clojure is available.
# Examples:
#   check_runtime_clojure "Linter"
check_runtime_clojure() {
  local _TOOL_DESC_CLJ="${1:-Clojure}"
  if ! command -v clojure >/dev/null 2>&1; then
    log_warn "Required runtime 'clojure' for $_TOOL_DESC_CLJ is missing. Skipping."
    return 1
  fi
  return 0
}
