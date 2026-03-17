#!/usr/bin/env sh
# CUDA Logic Module

# Purpose: Sets up CUDA environment for project.
setup_cuda() {
  local _T0_CUDA_RT
  _T0_CUDA_RT=$(date +%s)
  _log_setup "CUDA" "cuda"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "AI Tool" "CUDA" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect CUDA files
  if ! has_lang_files "*.cu *.cuh"; then
    log_summary "AI Tool" "CUDA" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # CUDA requires the NVIDIA driver and toolkit.
  # We focus on detection and availability of nvcc.
  local _STAT_CUDA_RT="✅ Detected"

  local _DUR_CUDA_RT
  _DUR_CUDA_RT=$(($(date +%s) - _T0_CUDA_RT))
  log_summary "AI Tool" "CUDA" "$_STAT_CUDA_RT" "-" "$_DUR_CUDA_RT"
}

# Purpose: Checks if nvcc is available.
check_runtime_cuda() {
  local _TOOL_DESC_CUDA="${1:-CUDA}"
  if ! command -v nvcc >/dev/null 2>&1; then
    log_warn "Required tool 'nvcc' for $_TOOL_DESC_CUDA is missing. Skipping."
    return 1
  fi
  return 0
}
