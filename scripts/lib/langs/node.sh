#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Node.js Logic Module

# Purpose: Installs Node.js runtime via mise.
# Delegate: Managed via mise (.mise.toml) and the best available manager.
install_runtime_node() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Node.js runtime and project dependencies."
    return 0
  fi

  # Fix: Windows Node 20 has an old bundled corepack that doesn't recognise
  # the new npm signing key (SHA256:DhQ8...). Setting COREPACK_INTEGRITY_KEYS=0
  # disables signature verification globally for this process and its children.
  # See: https://github.com/nodejs/corepack/issues/612
  export COREPACK_INTEGRITY_KEYS=0

  # 1. Runtime initialization
  run_mise install node

  # Optimization: If pnpm/yarn are already managed by mise (via .mise.toml), skip corepack to avoid
  # redundant network calls and signature errors, especially in Node 22+.
  if grep -qE "pnpm|yarn" .mise.toml 2>/dev/null; then
    log_info "Package managers are already managed by mise. Skipping corepack."
    if grep -q "npm:pnpm" .mise.toml 2>/dev/null; then
      run_mise install npm:pnpm || log_warn "Failed to install npm:pnpm via mise"
    fi
    if grep -q "npm:yarn" .mise.toml 2>/dev/null; then
      run_mise install npm:yarn || log_warn "Failed to install npm:yarn via mise"
    fi
  else
    log_info "Initializing Node.js package managers (corepack)..."

    # Check if corepack exists before enabling. If missing, try to install it.
    if ! run_mise x -- corepack --version >/dev/null 2>&1; then
      log_warn "corepack not found. Attempting to install via npm..."
      npm install -g corepack@latest --force >/dev/null 2>&1 || true
    fi

    # Attempt to enable, but don't fail if it's fundamentally missing
    run_mise x -- corepack enable >/dev/null 2>&1 || log_warn "Could not enable corepack. Proceeding with fallbacks."

    local _V_PNPM
    _V_PNPM=$(get_mise_tool_version pnpm)
    local _V_YARN
    _V_YARN=$(get_mise_tool_version yarn)

    # Resilient pnpm installation
    if ! run_mise x -- corepack prepare "pnpm@${_V_PNPM:-latest}" --activate 2>/dev/null; then
      log_warn "Corepack failed for pnpm. Falling back to direct npm installation."
      npm install -g "pnpm@${_V_PNPM:-latest}" --force >/dev/null 2>&1 || true
    fi

    # Resilient yarn installation
    if ! run_mise x -- corepack prepare "yarn@${_V_YARN:-latest}" --activate 2>/dev/null; then
      log_warn "Corepack failed for yarn. Falling back to direct npm installation."
      npm install -g "yarn@${_V_YARN:-latest}" --force >/dev/null 2>&1 || true
    fi
  fi

  # 2. Dependency resolution
  if [ -f "${PACKAGE_JSON:-}" ]; then
    # We use 'install' explicitly to bypass manager detection overhead for bootstrap
    # but still use run_npm_script to leverage its guards.
    run_npm_script install
  fi
}

# Purpose: Installs sort-package-json.
# Delegate: Managed by mise (.mise.toml)
install_sort_package_json() {
  if ! has_lang_files "package.json" ""; then
    return 0
  fi

  install_tool_safe "sort-package-json" "${VER_SORT_PACKAGE_JSON_PROVIDER:-}" "sort-package-json" "--version" 0 "" "package.json"
}

# Purpose: Installs eslint.
# Delegate: Managed by mise (.mise.toml)
install_eslint() {
  if ! has_lang_files "package.json" "*.js *.ts *.jsx *.tsx *.vue *.svelte *.astro"; then
    return 0
  fi

  install_tool_safe "eslint" "${VER_ESLINT_PROVIDER:-}" "ESLint" "--version" 0 "*.js *.ts *.jsx *.tsx" ""
}

# Purpose: Installs stylelint.
# Delegate: Managed by mise (.mise.toml)
install_stylelint() {
  if ! has_lang_files "package.json" "*.css *.scss *.sass *.less"; then
    return 0
  fi

  install_tool_safe "stylelint" "${VER_STYLELINT_PROVIDER:-}" "Stylelint" "--version" 0 "*.css *.scss *.sass *.less" ""
}

# Purpose: Installs vitepress.
# Delegate: Managed by mise (.mise.toml)
install_vitepress() {
  if [ ! -d docs ] && ! grep -q '"vitepress"' "${PACKAGE_JSON:-}" 2>/dev/null; then
    return 0
  fi

  install_tool_safe "vitepress" "${VER_VITEPRESS_PROVIDER:-}" "VitePress" "--version" 1
}

# Purpose: Installs prettier.
# Delegate: Managed by mise (.mise.toml)
install_prettier() {
  install_tool_safe "prettier" "${VER_PRETTIER_PROVIDER:-}" "Prettier" "--version" 1
}

# Purpose: Installs commitlint.
# Delegate: Managed by mise (.mise.toml)
install_commitlint() {
  install_tool_safe "commitlint" "${VER_COMMITLINT_PROVIDER:-}" "Commitlint" "--version" 1
}

# Purpose: Installs commitizen.
# Delegate: Managed by mise (.mise.toml)
install_commitizen() {
  install_tool_safe "commitizen" "${VER_COMMITIZEN_PROVIDER:-}" "Commitizen" "--version" 1
}

# Purpose: Sets up Node.js runtime for project.
# Delegate: Managed by mise (.mise.toml)
setup_node() {
  # Node.js is a first-class citizen: setup is always performed.

  local _T0_NODE_RT
  _T0_NODE_RT=$(date +%s)
  local _TITLE="Node.js"
  local _PROVIDER="node"

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version node)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "${_PROVIDER:-}")

  # Always log setup start for consistency and test assertions
  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if is_version_match "${_CUR_VER:-}" "${_REQ_VER:-}"; then
    log_summary "Runtime" "Node.js" "✅ Detected" "${_CUR_VER:-}" "0"
  else

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_summary "Runtime" "Node.js" "⚖️ Previewed" "-" "0"
    else
      local _STAT_NODE_RT="✅ Installed"
      install_runtime_node || _STAT_NODE_RT="❌ Failed"

      local _DUR_NODE_RT
      _DUR_NODE_RT=$(($(date +%s) - _T0_NODE_RT))
      log_summary "Runtime" "Node.js" "${_STAT_NODE_RT:-}" "$(get_version node)" "${_DUR_NODE_RT:-}"
    fi
  fi

  if [ -f "${PACKAGE_JSON:-}" ]; then
    # Detect Frameworks from package.json for summary
    if grep -q '"vue"' "${PACKAGE_JSON:-}"; then log_summary "Framework" "Vue" "✅ Detected" "-" "0"; fi
    if grep -q '"react"' "${PACKAGE_JSON:-}"; then log_summary "Framework" "React" "✅ Detected" "-" "0"; fi
    if grep -q '"astro"' "${PACKAGE_JSON:-}"; then log_summary "Framework" "Astro" "✅ Detected" "-" "0"; fi
    if grep -q '"svelte"' "${PACKAGE_JSON:-}"; then log_summary "Framework" "Svelte" "✅ Detected" "-" "0"; fi
    if grep -q '"tailwindcss"' "${PACKAGE_JSON:-}"; then log_summary "Framework" "Tailwind" "✅ Detected" "-" "0"; fi
  fi

  # Detect Bun if bun.lockb exists
  if [ -f "bun.lockb" ]; then
    log_summary "Runtime" "Bun" "✅ Detected" "$(bun --version 2>/dev/null || echo "exists")" "0"
  fi

  # Detect Deno if deno.json exists
  if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
    log_summary "Runtime" "Deno" "✅ Detected" "$(deno --version 2>/dev/null | head -n 1 | awk '{print $2}')" "0"
  fi

  # Setup related tools (Conditional on project files)
  if has_lang_files "package.json" "*.js *.ts *.jsx *.tsx *.vue *.svelte *.astro"; then
    install_sort_package_json
    install_eslint
    install_stylelint
    install_vitepress
  fi

  # Base tools often used project-wide across all languages
  install_commitizen
  install_prettier
  install_commitlint
}
# Purpose: Checks if Node.js runtime is available.
# Examples:
#   check_runtime_node "Linter"
check_runtime_node() {
  local _TOOL_DESC_NODE="${1:-Node.js}"
  if ! resolve_bin "node" >/dev/null 2>&1; then
    log_warn "Required runtime 'node' for ${_TOOL_DESC_NODE:-} is missing. Skipping."
    return 1
  fi
  return 0
}
