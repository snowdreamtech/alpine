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
  corepack prepare "pnpm@${_V_PNPM:-latest}" --activate
  corepack prepare "yarn@${_V_YARN:-latest}" --activate

  # 2. Dependency resolution
  if [ -f "$PACKAGE_JSON" ]; then
    # We use 'install' explicitly to bypass manager detection overhead for bootstrap
    # but still use run_npm_script to leverage its guards.
    run_npm_script install
  fi
}

# Purpose: Configures Node.js runtime and installs dependencies.
setup_node() {
  local _T0_NODE
  _T0_NODE=$(date +%s)
  _log_setup "Node.js" "node"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "Node.js" "⚖️ Previewed" "-" "0"
    return 0
  fi

  local _STAT_NODE="✅ Installed"
  install_runtime_node || _STAT_NODE="❌ Failed"

  local _DUR_NODE
  _DUR_NODE=$(($(date +%s) - _T0_NODE))
  log_summary "Runtime" "Node.js" "$_STAT_NODE" "$(get_version node)" "$_DUR_NODE"

  if [ "$_STAT_NODE" = "✅ Installed" ] && [ -f "$PACKAGE_JSON" ]; then
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
