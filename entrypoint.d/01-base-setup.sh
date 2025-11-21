#!/bin/sh
set -e

# Create a user with PUID and PGID
if [ "${USER}" != "root" ] && [ ! -d "/home/${USER}" ] && [ "${PUID}" -ne 0 ] && [ "${PGID}" -ne 0 ]; then
    addgroup -g "${PGID}" "${USER}"; 
    adduser -h /home/"${USER}" -u "${PUID}" -g "${USER}" -G "${USER}" -s /bin/sh -D "${USER}"; 
    # sed -i "/%sudo/c ${USER} ALL=(ALL:ALL) NOPASSWD:ALL" /etc/sudoers; 
fi

# Enable CAP_NET_BIND_SERVICE
# if [ "${USER}" != "root" ] && [ "${CAP_NET_BIND_SERVICE}" -eq 1 ]; then 
    # setcap 'cap_net_bind_service=+ep' `which nginx`; 
# fi

# set umask
if [ -z "${UMASK}" ]; then
  UMASK=022
fi
umask "${UMASK}"