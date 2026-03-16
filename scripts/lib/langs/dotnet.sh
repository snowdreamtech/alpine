#!/usr/bin/env sh
# Dotnet Logic Module

# Purpose: Installs .NET runtime via mise.
# Delegate: Managed by mise (.mise.toml)
install_runtime_dotnet() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install .NET runtime."
    return 0
  fi

  # Runtime initialization
  run_mise install dotnet
  eval "$(mise activate bash --shims)"
}

# Purpose: Sets up Dotnet runtime.
setup_dotnet() {
  local _T0_DOTNET_RT
  _T0_DOTNET_RT=$(date +%s)
  _log_setup ".NET Runtime" "dotnet"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" ".NET" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "global.json *.csproj *.fsproj *.sln" ""; then
    log_summary "Runtime" ".NET" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_DOTNET_RT="✅ Installed"
  install_runtime_dotnet || _STAT_DOTNET_RT="❌ Failed"

  local _DUR_DOTNET_RT
  _DUR_DOTNET_RT=$(($(date +%s) - _T0_DOTNET_RT))
  log_summary "Runtime" ".NET" "$_STAT_DOTNET_RT" "$(get_version dotnet --version)" "$_DUR_DOTNET_RT"
}
