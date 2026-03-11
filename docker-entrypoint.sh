#!/bin/sh
# Docker Entrypoint Wrapper
# Purpose: Orchestrates container initialization by executing scripts in entrypoint.d.
# Usage: This script is the default ENTRYPOINT. It iterates over entrypoint.d/ and then
# hands over control to the specific commands (handled in 99-base-end.sh).
# Dependencies: Requires /usr/local/bin/entrypoint.d directory.
# Design:
#   - POSIX compliant for maximum portability across Alpine/Debian/etc.
#   - Supports DEBUG=true for verbose initialization logging.

set -e

if [ "$DEBUG" = "true" ]; then
  echo "→ [ENTRYPOINT] Executing initialization suite in /usr/local/bin/entrypoint.d"
fi

# Iterate over all scripts in the extension directory.
# This allows decoupled specialized setup (user mapping, env config, etc.)
for script in /usr/local/bin/entrypoint.d/*; do
  if [ -x "$script" ]; then
    if [ "$DEBUG" = "true" ]; then
      echo "→ Running extension: $(basename "$script")"
    fi
    # Execute the extension script with all passed arguments.
    # Note: 99-base-end.sh is expected to handle the final exec/keepalive.
    "$script" "$@"
  else
    if [ "$DEBUG" = "true" ] && [ -f "$script" ]; then
      echo "⚠️ Skipping $(basename "$script") (not executable)"
    fi
  fi
done

if [ "$DEBUG" = "true" ]; then
  echo "→ [ENTRYPOINT] Initialization sequence complete."
fi
