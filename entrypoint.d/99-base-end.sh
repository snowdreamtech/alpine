#!/bin/sh
# Command Execution & Persistence Extension
# Purpose: Handles the transition to the target command or keeps the container alive.
# Design: Final script in entrypoint.d. Supports su-exec and KEEPALIVE behavior.
# Usage: Standardizes how the container exits or persists after initialization.

set -e

# Configure working directory
if [ -z "${WORKDIR}" ]; then
  WORKDIR="/root"
fi

if [ "$DEBUG" = "true" ]; then
  echo "→ [EXTENSION] Finalizing environment in ${WORKDIR}"
fi
cd "${WORKDIR}"

# Hand over control to the main command if provided
if [ $# -gt 0 ]; then
  if [ "$DEBUG" = "true" ]; then
    echo "🚀 [EXTENSION] Executing command: $*"
  fi
  # su-exec is used to drop privileges to the configured PUID/PGID correctly.
  su-exec "${PUID}:${PGID}" "$@"
fi

# Persistence logic for background-only or idle containers
# Reference: https://github.com/docker/compose/issues/1926#issuecomment-422351028
if [ "${KEEPALIVE}" -eq 1 ]; then
  if [ "$DEBUG" = "true" ]; then
    echo "♾️ [EXTENSION] Keep-alive enabled. Entering persistence loop..."
  fi
  trap : TERM INT
  tail -f /dev/null &
  wait
fi
