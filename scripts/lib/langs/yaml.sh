#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# YAML Logic Module

# Purpose: Installs yamllint for YAML linting.
# Delegate: Managed by mise (.mise.toml)
install_yamllint() {
  local _T0_YAML
  _T0_YAML=$(date +%s)
  local _TITLE="Yamllint"
  local _PROVIDER="pipx:yamllint"

  if ! has_lang_files "" "*.yaml *.yml"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version yamllint)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Config" "Yamllint" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Config" "Yamllint" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_YAML="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_YAML="❌ Failed"
  log_summary "Config" "Yamllint" "$_STAT_YAML" "$(get_version yamllint)" "$(($(date +%s) - _T0_YAML))"
}

# Purpose: Installs dotenv-linter for .env file linting.
# Delegate: Managed by mise (.mise.toml)
install_dotenv_linter() {
  local _T0_ENV
  _T0_ENV=$(date +%s)
  local _TITLE="Dotenv-Linter"
  local _PROVIDER="github:dotenv-linter/dotenv-linter"

  if ! has_lang_files ".env .env.example .env.template" ""; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version dotenv-linter)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Config" "Dotenv-Linter" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Config" "Dotenv-Linter" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_ENV="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_ENV="❌ Failed"
  log_summary "Config" "Dotenv-Linter" "$_STAT_ENV" "$(get_version dotenv-linter)" "$(($(date +%s) - _T0_ENV))"
}

# Purpose: Sets up YAML and Env environment.
setup_yaml() {
  install_yamllint
  install_dotenv_linter
}
