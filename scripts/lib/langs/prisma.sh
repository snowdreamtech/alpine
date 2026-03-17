#!/usr/bin/env sh
# Prisma Logic Module

# Purpose: Sets up Prisma environment for project.
setup_prisma() {
  local _T0_PRISMA_RT
  _T0_PRISMA_RT=$(date +%s)
  _log_setup "Prisma" "prisma"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Data Tool" "Prisma" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Prisma: check for schema.prisma or *.prisma
  if ! has_lang_files "schema.prisma" "*.prisma"; then
    log_summary "Data Tool" "Prisma" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_PRISMA_RT="✅ Detected"

  local _DUR_PRISMA_RT
  _DUR_PRISMA_RT=$(($(date +%s) - _T0_PRISMA_RT))
  log_summary "Data Tool" "Prisma" "$_STAT_PRISMA_RT" "-" "$_DUR_PRISMA_RT"
}

# Purpose: Checks if Prisma is relevant.
check_runtime_prisma() {
  local _TOOL_DESC_PRISMA="${1:-Prisma}"
  if has_lang_files "schema.prisma" "*.prisma"; then
    return 0
  fi
  return 1
}
