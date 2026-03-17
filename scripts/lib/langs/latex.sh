#!/usr/bin/env sh
# LaTeX Logic Module

# Purpose: Sets up LaTeX environment for project.
setup_latex() {
  local _T0_TEX_RT
  _T0_TEX_RT=$(date +%s)
  _log_setup "LaTeX" "latex"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Doc Tool" "LaTeX" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect LaTeX files
  if ! has_lang_files "*.tex *.bib"; then
    log_summary "Doc Tool" "LaTeX" "⏭️ Skipped" "-" "0"
    return 0
  fi

  # LaTeX is typically installed via TeX Live or MikTeX.
  # We focus on detection and availability.
  local _STAT_TEX_RT="✅ Detected"

  local _DUR_TEX_RT
  _DUR_TEX_RT=$(($(date +%s) - _T0_TEX_RT))
  log_summary "Doc Tool" "LaTeX" "$_STAT_TEX_RT" "-" "$_DUR_TEX_RT"
}

# Purpose: Checks if LaTeX is available.
check_runtime_latex() {
  local _TOOL_DESC_TEX="${1:-LaTeX}"
  if ! command -v pdflatex >/dev/null 2>&1 && ! command -v xelatex >/dev/null 2>&1; then
    log_warn "Required tool 'pdflatex' or 'xelatex' for $_TOOL_DESC_TEX is missing. Skipping."
    return 1
  fi
  return 0
}
