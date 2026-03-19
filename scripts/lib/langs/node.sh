#!/usr/bin/env sh
# Node.js Logic Module

# Purpose: Installs Node.js runtime via mise.
# Delegate: Managed via mise (.mise.toml) and the best available manager.
install_runtime_node() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install Node.js runtime and project dependencies."
    return 0
  fi

  # 1. Runtime initialization
  run_mise install node
  eval "$(mise activate bash --shims)"

  # 1b. Package Manager initialization (Corepack)
  log_info "Initializing Node.js package managers (corepack)..."
  corepack enable
  local _V_PNPM
  _V_PNPM=$(get_mise_tool_version pnpm)
  local _V_YARN
  _V_YARN=$(get_mise_tool_version yarn)

  # Resilient pnpm installation (Handles corepack signature errors in fresh CI)
  if ! corepack prepare "pnpm@${_V_PNPM:-latest}" --activate; then
    log_warn "Corepack failed to prepare pnpm (Signature error?). Attempting update and direct fallback..."
    npm install -g corepack@latest --force >/dev/null 2>&1 || true
    corepack prepare "pnpm@${_V_PNPM:-latest}" --activate || {
      log_warn "Corepack still failed. Using direct npm installation for pnpm."
      npm install -g "pnpm@${_V_PNPM:-latest}" --force
    }
  fi

  # Resilient yarn installation
  if ! corepack prepare "yarn@${_V_YARN:-latest}" --activate; then
    log_warn "Corepack failed for yarn. Using direct npm installation."
    npm install -g "yarn@${_V_YARN:-latest}" --force
  fi

  # 2. Dependency resolution
  if [ -f "$PACKAGE_JSON" ]; then
    # We use 'install' explicitly to bypass manager detection overhead for bootstrap
    # but still use run_npm_script to leverage its guards.
    run_npm_script install
  fi
}

# Purpose: Sets up Node.js runtime for project.
# Delegate: Managed by mise (.mise.toml)
setup_node() {
  if ! has_lang_files "package.json .nvmrc .node-version" "*.js *.ts *.jsx *.tsx"; then
    return 0
  fi

  local _T0_NODE_RT
  _T0_NODE_RT=$(date +%s)
  local _TITLE="Node.js"
  local _PROVIDER="node"

  # Fast-path: Check version-aware existence
  local _CUR_VER
  _CUR_VER=$(get_version node)
  local _REQ_VER
  _REQ_VER=$(get_mise_tool_version "$_PROVIDER")

  if [ "$_CUR_VER" != "-" ] && [ "$_CUR_VER" = "$_REQ_VER" ]; then
    log_summary "Runtime" "Node.js" "✅ Detected" "$_CUR_VER" "0"
    return 0
  fi

  _log_setup "$_TITLE" "$_PROVIDER"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Node.js" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_NODE_RT="✅ Installed"
  install_runtime_node || _STAT_NODE_RT="❌ Failed"

  local _DUR_NODE_RT
  _DUR_NODE_RT=$(($(date +%s) - _T0_NODE_RT))
  log_summary "Runtime" "Node.js" "$_STAT_NODE_RT" "$(get_version node)" "$_DUR_NODE_RT"

  if [ "$_STAT_NODE_RT" = "✅ Installed" ] && [ -f "$PACKAGE_JSON" ]; then
    # Detect Frameworks from package.json for summary
    if grep -q '"vitepress"' "$PACKAGE_JSON"; then log_summary "Framework" "VitePress" "✅ Detected" "$(get_version node "exec vitepress --version")" "0"; fi
    if grep -q '"vue"' "$PACKAGE_JSON"; then log_summary "Framework" "Vue" "✅ Detected" "-" "0"; fi
    if grep -q '"react"' "$PACKAGE_JSON"; then log_summary "Framework" "React" "✅ Detected" "-" "0"; fi
    if grep -q '"astro"' "$PACKAGE_JSON"; then log_summary "Framework" "Astro" "✅ Detected" "-" "0"; fi
    if grep -q '"svelte"' "$PACKAGE_JSON"; then log_summary "Framework" "Svelte" "✅ Detected" "-" "0"; fi
    if grep -q '"tailwindcss"' "$PACKAGE_JSON"; then log_summary "Framework" "Tailwind" "✅ Detected" "-" "0"; fi
  fi

  # Detect Bun if bun.lockb exists
  if [ -f "bun.lockb" ]; then
    log_summary "Runtime" "Bun" "✅ Detected" "$(bun --version 2>/dev/null || echo "exists")" "0"
  fi

  # Detect Deno if deno.json exists
  if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
    log_summary "Runtime" "Deno" "✅ Detected" "$(deno --version 2>/dev/null | head -n 1 | awk '{print $2}')" "0"
  fi
}
# Purpose: Checks if Node.js runtime is available.
# Examples:
#   check_runtime_node "Linter"
check_runtime_node() {
  local _TOOL_DESC_NODE="${1:-Node.js}"
  if ! command -v node >/dev/null 2>&1; then
    log_warn "Required runtime 'node' for $_TOOL_DESC_NODE is missing. Skipping."
    return 1
  fi
  return 0
}
