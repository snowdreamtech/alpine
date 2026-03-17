#!/usr/bin/env sh
# Kustomize Logic Module

# Purpose: Sets up Kustomize environment for project.
setup_kustomize() {
  local _T0_KUSTOMIZE_RT
  _T0_KUSTOMIZE_RT=$(date +%s)
  _log_setup "Kustomize" "kustomize"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Ops Tool" "Kustomize" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Kustomize files
  if ! has_lang_files "kustomization.yaml kustomization.yml"; then
    log_summary "Ops Tool" "Kustomize" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # Kustomize is a K8s configuration tool. We focus on detection.
  local _STAT_KUSTOMIZE_RT="✅ Detected"

  local _DUR_KUSTOMIZE_RT
  _DUR_KUSTOMIZE_RT=$(($(date +%s) - _T0_KUSTOMIZE_RT))
  log_summary "Ops Tool" "Kustomize" "$_STAT_KUSTOMIZE_RT" "-" "$_DUR_KUSTOMIZE_RT"
}

# Purpose: Checks if Kustomize files are present.
check_runtime_kustomize() {
  local _TOOL_DESC_KUSTOMIZE="${1:-Kustomize}"
  if ! has_lang_files "kustomization.yaml kustomization.yml"; then
    return 1
  fi
  return 0
}
