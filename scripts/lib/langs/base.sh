#!/usr/bin/env sh
# Base Logic Module

# Purpose: Installs pipx.
# Delegate: Managed by mise (.mise.toml)
install_pipx() {
  local _T0_PIPX
  _T0_PIPX=$(date +%s)
  local _TITLE="Pipx"
  local _PROVIDER="pipx"
  if command -v pipx >/dev/null 2>&1; then
    log_summary "Base" "Pipx" "✅ Exists" "$(get_version pipx)" "$(($(date +%s) - _T0_PIPX))"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Pipx" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_PIPX="✅ mise"
  run_mise install pipx || _STAT_PIPX="❌ Failed"
  log_summary "Base" "Pipx" "$_STAT_PIPX" "$(get_version pipx)" "$(($(date +%s) - _T0_PIPX))"
}

# Purpose: Installs Gitleaks for secrets scanning.
# Delegate: Managed by mise (.mise.toml)
install_gitleaks() {
  local _T0_GITL
  _T0_GITL=$(date +%s)
  local _TITLE="Gitleaks"
  local _PROVIDER="gitleaks"

  if [ ! -d ".git" ]; then
    return 0
  fi

  # Fast-path: Check version-aware existence (Optimized via _G_MISE_LS_JSON)
  local _CUR_VER
  _CUR_VER=$(get_version gitleaks)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Base" "Gitleaks" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_GITL="✅ mise"
  run_mise install gitleaks || _STAT_GITL="❌ Failed"
  log_summary "Base" "Gitleaks" "$_STAT_GITL" "$(get_version gitleaks)" "$(($(date +%s) - _T0_GITL))"
}

# Purpose: Installs checkmake for Makefile linting.
# Delegate: Managed by mise (.mise.toml)
install_checkmake() {
  local _T0_CM
  _T0_CM=$(date +%s)
  local _TITLE="Checkmake"
  local _PROVIDER="checkmake"

  if ! has_lang_files "Makefile" "*.make"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version checkmake)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Base" "Checkmake" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"
  local _STAT_CM="✅ mise"
  run_mise install checkmake || _STAT_CM="❌ Failed"
  log_summary "Base" "Checkmake" "$_STAT_CM" "$(get_version checkmake)" "$(($(date +%s) - _T0_CM))"
}

# Purpose: Installs pre-commit runtime via pipx.
install_runtime_hooks() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install pre-commit via pipx."
    return 0
  fi
  run_mise install pipx:pre-commit
}

# Purpose: Activates git pre-commit hooks.
setup_hooks() {
  local _T0_HOOK
  _T0_HOOK=$(date +%s)
  # 2. Fast-path: Check if hooks already exist
  if [ -f ".git/hooks/pre-commit" ]; then
    log_summary "Base" "Hooks" "✅ Activated" "4.5.1" "0"
    return 0
  fi

  # 3. Action Required (Real or Preview)
  _log_setup "Pre-commit Hooks" "pipx:pre-commit"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Hooks" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_HOOK="✅ Activated"
  install_runtime_hooks || _STAT_HOOK="❌ Failed"

  local _DUR_HOOK
  _DUR_HOOK=$(($(date +%s) - _T0_HOOK))
  log_summary "Base" "Hooks" "$_STAT_HOOK" "$(get_version pre-commit --version)" "$_DUR_HOOK"
}

# Purpose: Installs editorconfig-checker.
# Delegate: Managed by mise (.mise.toml)
install_editorconfig_checker() {
  local _T0_EC
  _T0_EC=$(date +%s)
  local _TITLE="Editorconfig-Checker"
  local _PROVIDER="github:editorconfig-checker/editorconfig-checker"

  if [ ! -f ".editorconfig" ]; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version editorconfig-checker)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Base" "Editorconfig-Checker" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Editorconfig-Checker" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_EC="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_EC="❌ Failed"
  log_summary "Base" "Editorconfig-Checker" "$_STAT_EC" "$(get_version editorconfig-checker)" "$(($(date +%s) - _T0_EC))"
}

# Purpose: Installs GoReleaser as a universal release automation tool.
# Note: goreleaser supports multi-language projects (Go, Rust, Python, Node, etc.)
#       It is installed globally regardless of project language.
install_goreleaser() {
  local _T0_GR
  _T0_GR=$(date +%s)
  local _TITLE="GoReleaser"
  local _PROVIDER="github:goreleaser/goreleaser"

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version goreleaser "")
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Base" "GoReleaser" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "GoReleaser" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_GR="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_GR="❌ Failed"
  log_summary "Base" "GoReleaser" "$_STAT_GR" "$(get_version goreleaser)" "$(($(date +%s) - _T0_GR))"
}

# Purpose: Sets up Base environment.
setup_base() {
  install_pipx
  install_gitleaks
  install_checkmake
  setup_hooks
  install_editorconfig_checker
  install_goreleaser
}
