#!/bin/sh
# Base Initialization & Extension Bootstrap Hook
# Purpose: Provides a standardized early-stage hook for fundamental initialization.
# Design:
#   - Executed as the very first script in the entrypoint.d sequence (00-*).
#   - Acts as an extension point for third-party or downstream image boots.
# Usage:
#   - downstream images should mount or copy their early setup here.
#   - placeholder for core system-level boots (e.g., entropy seeding).

set -e

if [ "$DEBUG" = "true" ]; then
  echo "→ [EXTENSION] Bootstrapping global initialization suite (00-base-init.sh)"
fi
