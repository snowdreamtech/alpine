#!/bin/sh
set -e

# set umask
if [ -z "${UMASK}" ]; then
  UMASK=022
fi
umask "${UMASK}"

# set workdir
if [ -z "${WORKDIR}" ]; then
  WORKDIR="/root"
fi
cd "${WORKDIR}"

# exec commands
if [ -n "$*" ]; then
  su-exec "${PUID}:${PGID}" ""$*""
fi

# keep the docker container running
# https://github.com/docker/compose/issues/1926#issuecomment-422351028
if [ "${KEEPALIVE}" -eq 1 ]; then
  trap : TERM INT
  tail -f /dev/null &
  wait
  # sleep infinity & wait
fi
