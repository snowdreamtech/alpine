#!/bin/sh
# Environment & User Setup Extension
# Purpose: Configures the runtime environment, including PUID/PGID mapping and UMASK.
# Design: Ensures the container environment aligns with host-provided UID/GID for volumes.
# Usage: Automatically executed by the core docker-entrypoint.sh.

set -e

# Create a user with PUID and PGID if specified and doesn't exist
if [ "$(id -u)" = "0" ]; then
  if [ "${USER}" != "root" ] && [ "${PUID:-0}" -ne 0 ] && [ "${PGID:-0}" -ne 0 ]; then
    if [ "$DEBUG" = "true" ]; then
      echo "→ [EXTENSION] Ensuring user mapping: ${USER} (UID: ${PUID}, GID: ${PGID})"
    fi

    # 1. Handle group creation/mapping
    if ! getent group "${PGID}" >/dev/null 2>&1; then
      addgroup -g "${PGID}" "${USER}"
    else
      EXISTING_GROUP=$(getent group "${PGID}" | cut -d: -f1)
      if [ "$DEBUG" = "true" ]; then
        echo "→ [EXTENSION] GID ${PGID} already exists as group: ${EXISTING_GROUP}"
      fi
    fi

    # 2. Handle user creation/mapping
    if ! getent passwd "${PUID}" >/dev/null 2>&1; then
      adduser -h /home/"${USER}" -u "${PUID}" -g "${USER}" -G "${USER}" -s /bin/sh -D "${USER}"
    else
      EXISTING_USER=$(getent passwd "${PUID}" | cut -d: -f1)
      if [ "$DEBUG" = "true" ]; then
        echo "→ [EXTENSION] UID ${PUID} already exists as user: ${EXISTING_USER}"
      fi
    fi

    # 3. Ensure home directory permissions
    if [ -d "/home/${USER}" ]; then
      chown -R "${PUID}:${PGID}" "/home/${USER}"
    fi
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
