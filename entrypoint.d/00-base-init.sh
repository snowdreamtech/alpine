#!/bin/sh
# Base Initialization Extension
# Purpose: Provides an early-stage hook for fundamental system initialization.
# Design: Executed as the first script in the entrypoint.d sequence.
# Usage: Placeholder for core system-level boots (e.g., entropy seeding, early logging).

set -e

if [ "$DEBUG" = "true" ]; then
  echo "→ [EXTENSION] Initializing base system components (00-base-init.sh)"
fi
