#!/usr/bin/env sh
# Runner Logic Module

# Purpose: Installs Just (modern runner).
# Delegate: Managed by mise (.mise.toml)
install_just() {
  local _T0_JUST
  _T0_JUST=$(date +%s)
  local _TITLE="Just"
  local _PROVIDER="github:casey/just"
  if ! has_lang_files "" "JUST"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version just --version)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Base" "Just" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Just" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_JUST="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_JUST="❌ Failed"
  log_summary "Base" "Just" "$_STAT_JUST" "$(get_version just --version)" "$(($(date +%s) - _T0_JUST))"
}

# Purpose: Installs Task (modern runner).
# Delegate: Managed by mise (.mise.toml)
install_task() {
  local _T0_TASK
  _T0_TASK=$(date +%s)
  local _TITLE="Task"
  local _PROVIDER="github:go-task/task"
  if ! has_lang_files "" "TASK"; then
    return 0
  fi

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version task --version)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if is_version_match "$_CUR_VER" "$_REQ_VER"; then
    log_summary "Base" "Task" "✅ Exists" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Base" "Task" '⚖️ Previewed' "-" '0'
    return 0
  fi
  local _STAT_TASK="✅ mise"
  run_mise install "$_PROVIDER" || _STAT_TASK="❌ Failed"
  log_summary "Base" "Task" "$_STAT_TASK" "$(get_version task --version)" "$(($(date +%s) - _T0_TASK))"
}

# Purpose: Sets up Runners environment.
setup_runners() {
  install_just
  install_task
}
