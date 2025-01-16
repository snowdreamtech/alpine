#!/bin/sh
set -e

# setup-keymap
setup-keymap.exp >/dev/null 2>&1


# ssh-keygen -A
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
  ssh-keygen -A >/dev/null 2>&1
fi

# start cornd
crond >/dev/null 2>&1

# generate motd
/etc/periodic/15min/motd.sh >/dev/null 2>&1

# openssl rand -base64 33
if [ -z "${SSH_ROOT_PASSWORD}" ]; then {
    SSH_ROOT_PASSWORD=$(openssl rand -base64 33)
    echo "Generate random ssh root password:${SSH_ROOT_PASSWORD}"
}
fi

# change the password for root
echo "root:$SSH_ROOT_PASSWORD" | chpasswd >/dev/null 2>&1

# generate ssh keys
if [ ! -d "/root/.ssh" ]; then
  ssh-keygen -t ed25519 -C "user@example.com" -f $HOME/.ssh/id_ed25519 -q -N ""
  ssh-keygen -t rsa -b 4096 -C "user@example.com" -f $HOME/.ssh/id_rsa -q -N ""
  ssh-keygen -t ecdsa -b 521 -C "user@example.com" -f $HOME/.ssh/id_ecdsa -q -N ""
  ssh-keygen -t dsa -C "user@example.com" -f $HOME/.ssh/id_dsa -q -N ""
fi

# start sshd
/usr/sbin/sshd -D

# exec commands
if [ -n "$*" ]; then
  sh -c "$*"
fi

# keep the docker container running
# https://github.com/docker/compose/issues/1926#issuecomment-422351028
if [ "${KEEPALIVE}" -eq 1 ]; then
  trap : TERM INT
  tail -f /dev/null &
  wait
  # sleep infinity & wait
fi
