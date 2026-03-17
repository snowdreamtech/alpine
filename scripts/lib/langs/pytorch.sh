#!/usr/bin/env sh
# PyTorch Logic Module

# Purpose: Sets up PyTorch environment for project.
setup_pytorch() {
  local _T0_TORCH_RT
  _T0_TORCH_RT=$(date +%s)
  _log_setup "PyTorch" "pytorch"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "AI Framework" "PyTorch" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect PyTorch: check for torch in requirement files
  if [ -f "requirements.txt" ] && grep -q "torch" "requirements.txt"; then
    :
  elif [ -f "pyproject.toml" ] && grep -q "torch" "pyproject.toml"; then
    :
  else
    log_summary "AI Framework" "PyTorch" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_TORCH_RT="✅ Detected"

  local _DUR_TORCH_RT
  _DUR_TORCH_RT=$(($(date +%s) - _T0_TORCH_RT))
  log_summary "AI Framework" "PyTorch" "$_STAT_TORCH_RT" "-" "$_DUR_TORCH_RT"
}

# Purpose: Checks if PyTorch is relevant.
check_runtime_pytorch() {
  local _TOOL_DESC_TORCH="${1:-PyTorch}"
  if [ -f "requirements.txt" ] && grep -q "torch" "requirements.txt"; then
    return 0
  fi
  if [ -f "pyproject.toml" ] && grep -q "torch" "pyproject.toml"; then
    return 0
  fi
  return 1
}
