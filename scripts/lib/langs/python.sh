#!/usr/bin/env sh
# Python Logic Module

# Purpose: Installs the Python runtime, creates a venv, and installs dependencies.
# Delegate: Managed via mise (.mise.toml) and pip.
install_runtime_python() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Python runtime and virtual environment."
    return 0
  fi

  # 1. Runtime initialization
  run_mise install python
  eval "$(mise activate bash --shims)"

  # 2. Virtualenv management
  if [ ! -d "$VENV" ]; then
    run_quiet "$PYTHON" -m venv "$VENV"
  fi

  # 3. Dependency resolution
  if [ -d "$VENV" ]; then
    # Standard requirements
    if [ -f "$REQUIREMENTS_TXT" ]; then
      run_quiet "$VENV/$_G_VENV_BIN/pip" install -r "$REQUIREMENTS_TXT"
    fi
    # Dev requirements (setup.sh specific but safe here)
    if [ -f "requirements-dev.txt" ]; then
      run_quiet "$VENV/$_G_VENV_BIN/pip" install -r "requirements-dev.txt"
    fi
  fi
}

# Purpose: Sets up Python runtime for project.
# Delegate: Managed by mise (.mise.toml)
setup_python() {
  if ! has_lang_files "requirements.txt pyproject.toml .python-version" "*.py"; then
    return 0
  fi

  local _T0_PY_RT
  _T0_PY_RT=$(date +%s)
  local _TITLE="Python Virtual Environment"
  local _PROVIDER="python"

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version python)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Python" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Python" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_PY_RT="✅ Installed"
  install_python_venv || _STAT_PY_RT="❌ Failed"

  local _DUR_PY_RT
  _DUR_PY_RT=$(($(date +%s) - _T0_PY_RT))
  log_summary "Runtime" "Python" "$_STAT_PY_RT" "$(get_version python)" "$_DUR_PY_RT"
}
# Purpose: Checks if Python runtime is available.
# Examples:
#   check_runtime_python "Linter"
check_runtime_python() {
  local _TOOL_DESC_PY="${1:-Python}"
  if ! command -v "$PYTHON" >/dev/null 2>&1; then
    log_warn "Required runtime 'python' for $_TOOL_DESC_PY is missing. Skipping."
    return 1
  fi
  return 0
}
