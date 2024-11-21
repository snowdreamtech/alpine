FROM alpine:3.20.3

# OCI annotations to image
LABEL org.opencontainers.image.authors="Snowdream Tech" \
    org.opencontainers.image.title="Alpine Base Image" \
    org.opencontainers.image.description="Docker Images for Alpine. (i386, amd64, arm32v6, arm32v7, arm64, ppc64le,riscv64, s390x)" \
    org.opencontainers.image.documentation="https://hub.docker.com/r/snowdreamtech/alpine" \
    org.opencontainers.image.base.name="snowdreamtech/alpine:latest" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source="https://github.com/snowdreamtech/alpine" \
    org.opencontainers.image.vendor="Snowdream Tech" \
    org.opencontainers.image.version="3.20.3" \
    org.opencontainers.image.url="https://github.com/snowdreamtech/alpine"

# keep the docker container running
ENV KEEPALIVE=1 \
    # Ensure the container exec commands handle range of utf8 characters based of
    # default locales in base image (https://github.com/docker-library/docs/tree/master/debian#locales)
    LANG=C.UTF-8 \
    SSH_ROOT_PASSWORD=

RUN echo "@main https://dl-cdn.alpinelinux.org/alpine/edge/main" | tee -a /etc/apk/repositories \
    && echo "@community https://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories \
    && echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories \
    && apk add --no-cache musl-locales \
    musl-locales-lang \
    tzdata \
    openssl \
    wget \
    curl \
    ca-certificates \                                                                                                                                                                                                      
    && update-ca-certificates


RUN apk add --no-cache \
    fastfetch \
    xauth \
    openssh \
    && sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config \ 
    && sed -i "s/^#PasswordAuthentication/PasswordAuthentication/g" /etc/ssh/sshd_config \ 
    && sed -i "s/^#PermitEmptyPasswords/PermitEmptyPasswords/g" /etc/ssh/sshd_config \ 
    && sed -i "s/^#HostKey/HostKey/g" /etc/ssh/sshd_config \ 
    && sed -i "s/^#PubkeyAuthentication/PubkeyAuthentication/g" /etc/ssh/sshd_config \ 
    && sed -i "s/^#IgnoreRhosts/IgnoreRhosts/g" /etc/ssh/sshd_config \ 
    && sed -i "s/^#StrictModes/StrictModes/g" /etc/ssh/sshd_config \ 
    && sed -i "s/#MaxAuthTries.*/MaxAuthTries 7/g" /etc/ssh/sshd_config \ 
    && sed -i "s/#MaxSessions.*/MaxSessions 10/g" /etc/ssh/sshd_config \ 
    && sed -i "s/#ClientAliveInterval.*/ClientAliveInterval 900/g" /etc/ssh/sshd_config \ 
    && sed -i "s/#ClientAliveCountMax.*/ClientAliveCountMax 0/g" /etc/ssh/sshd_config \ 
    && sed -i "s/Subsystem.*/Subsystem\tsftp\tinternal-sftp/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?AllowAgentForwarding.*/AllowAgentForwarding yes/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?AllowTcpForwarding.*/AllowTcpForwarding yes/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?AllowTcpForwarding.*/AllowTcpForwarding yes/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?GatewayPorts.*/GatewayPorts yes/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?X11Forwarding.*/X11Forwarding yes/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?X11DisplayOffset.*/X11DisplayOffset 10/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?X11UseLocalhost.*/X11UseLocalhost yes/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?PermitTTY.*/PermitTTY yes/g" /etc/ssh/sshd_config \
    && sed -i -E "s/#?PrintMotd.*/PrintMotd yes/g" /etc/ssh/sshd_config 

COPY motd.sh /etc/periodic/15min/

EXPOSE 22

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]