#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/sync-lock.sh — Mise Lockfile Synchronizer
#
# Purpose:
#   Synchronizes mise.lock with the comprehensive manifest (Tier 1 + Tier 2).
#   Ensures all tools are cryptographically locked for all supported platforms.

set -eu

# 1. Housekeeping
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$PROJECT_ROOT"

# Ensure mise is available
if ! command -v mise >/dev/null 2>&1; then
  echo "Error: mise not found in PATH."
  exit 1
fi

echo "Synchronizing mise.lock for all platforms..."

# 2. Manifest Aggregation
# We use a temporary file to avoid corrupting .mise.toml if the process is interrupted.
TMP_MANIFEST=".mise.toml.lock.temp"
./scripts/gen-full-manifest.sh >"$TMP_MANIFEST"

# 3. List Extraction
# We must explicitly list tools to force mise to update/add them for all platforms.
_TOOLS=$(grep "=" "$TMP_MANIFEST" | cut -d= -f1 | tr -d '" ' | xargs)

# 4. Multi-Platform Locking
# We point mise to the temporary manifest.
# Platforms: Ubuntu (x64/arm64), macOS (x64/arm64), Windows (x64).
# We omit windows-arm64 as most tools don't provide it yet, but can be added if needed.
# shellcheck disable=SC2086
MISE_CONFIG="$TMP_MANIFEST" mise lock --platform linux-x64,linux-arm64,macos-x64,macos-arm64,windows-x64 $_TOOLS

# 5. Cleanup
rm -f "$TMP_MANIFEST"

echo "mise.lock synchronized successfully for all platforms."
