#!/bin/sh
# Environment & User Setup Extension
# Purpose: Configures the runtime environment, including PUID/PGID mapping and UMASK.
# Design: Ensures the container environment aligns with host-provided UID/GID for volumes.
# Usage: Automatically executed by the core docker-entrypoint.sh.

set -e

# Create a user with PUID and PGID if specified and doesn't exist
if [ "$(id -u)" = "0" ]; then
  if [ "${USER}" != "root" ] && [ ! -d "/home/${USER}" ] && [ "${PUID:-0}" -ne 0 ] && [ "${PGID:-0}" -ne 0 ]; then
    if [ "$DEBUG" = "true" ]; then
      echo "→ [EXTENSION] Mapping user: ${USER} (UID: ${PUID}, GID: ${PGID})"
    fi
    addgroup -g "${PGID}" "${USER}"
    adduser -h /home/"${USER}" -u "${PUID}" -g "${USER}" -G "${USER}" -s /bin/sh -D "${USER}"
    # Note: sudoers configuration can be added here if NOPASSWD:ALL is required.
  fi
else
  if [ "$DEBUG" = "true" ]; then
    echo "→ [EXTENSION] Running as non-root (UID: $(id -u)). Skipping dynamic user mapping."
  fi
fi

# Apply system umask for file creation consistency
if [ -z "${UMASK}" ]; then
  UMASK=022
fi

if [ "$DEBUG" = "true" ]; then
  echo "→ [EXTENSION] Applying system umask: ${UMASK}"
fi
umask "${UMASK}"
