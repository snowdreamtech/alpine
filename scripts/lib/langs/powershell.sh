#!/usr/bin/env sh
# PowerShell Logic Module

# Purpose: Sets up PowerShell environment for project.
setup_powershell() {
  local _T0_PS
  _T0_PS=$(date +%s)
  _log_setup "PowerShell" "powershell"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Lint Tool" "PowerShell" "⚖️ Previewed" "-" "0"
    return 0
  fi

  if ! has_lang_files "" "*.ps1 *.psm1 *.psd1"; then
    log_summary "Lint Tool" "PowerShell" "⏭️ Skipped" "-" "0"
    return 0
  fi

  if ! command -v pwsh >/dev/null 2>&1; then
    log_summary "Lint Tool" "PowerShell" "⏭️ Skipped (pwsh missing)" "-" "0"
    return 0
  fi

  local _TITLE="PowerShell Linter"
  local _PROVIDER="PSScriptAnalyzer"
  _log_setup "$_TITLE" "$_PROVIDER"

  local _STAT_PS="✅ Installed"
  run_quiet pwsh -NoProfile -Command "if (!(Get-Module -ListAvailable PSScriptAnalyzer)) { Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser }" || _STAT_PS="❌ Failed"

  # shellcheck disable=SC2016
  local _V_PS
  # shellcheck disable=SC2016
  _V_PS=$(pwsh -NoProfile -Command '(Get-Module PSScriptAnalyzer -ListAvailable).Version | Select-Object -First 1 | ForEach-Object { $_.ToString() }' 2>/dev/null || echo "installed")

  local _DUR_PS
  _DUR_PS=$(($(date +%s) - _T0_PS))
  log_summary "Lint Tool" "PowerShell" "$_STAT_PS" "$_V_PS" "$_DUR_PS"
}

# Purpose: Checks if PowerShell is available.
check_runtime_powershell() {
  local _TOOL_DESC_PS="${1:-PowerShell}"
  if ! command -v pwsh >/dev/null 2>&1; then
    log_warn "Required tool 'pwsh' (PowerShell Core) for $_TOOL_DESC_PS is missing. Skipping."
    return 1
  fi
  return 0
}
