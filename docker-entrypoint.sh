#!/bin/sh
set -e

# exec commands
if [ -n "$*" ]; then
    sh -c "$*"
fi

# keep the docker container running
if [ "${KEEPALIVE}" -eq 1 ]; then
    tail -f /dev/null
    # sleep infinity
fi