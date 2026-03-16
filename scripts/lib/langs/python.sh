#!/usr/bin/env bash
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

# Purpose: Initializes a Python virtual environment and installs development dependencies.
setup_python() {
  local _T0_PY
  _T0_PY=$(date +%s)
  _log_setup "Python Virtual Environment" "python"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Python" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_PY="✅ Installed"
  install_runtime_python || _STAT_PY="❌ Failed"

  local _DUR_PY
  _DUR_PY=$(($(date +%s) - _T0_PY))
  log_summary "Runtime" "Python" "$_STAT_PY" "$(get_version "$VENV/bin/python")" "$_DUR_PY"
}
