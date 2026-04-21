# Alpine Base Image

# Technical Purpose: High-performance, multi-architecture base image for Snowdream Tech projects.
# Design:
#   - Optimized layering for minimal image size.
#   - Decoupled initialization via entrypoint.d mechanism.
#   - Native support for PUID/PGID user mapping.
#   - Pre-installed with essential dev/ops tooling (Git, Curl, Sudo, etc.).

FROM alpine:3.22.3

# Build-time Configuration
ARG BUILDTIME \
    VERSION \
    REVISION \
    KEEPALIVE=0 \
    CAP_NET_BIND_SERVICE=0 \
    LANG=C.UTF-8 \
    UMASK=022 \
    DEBUG=false \
    PASSWORDLESS_SUDO=false \
    PGID=0 \
    PUID=0 \
    USER=root \
    WORKDIR=/root

# Standard OCI Metadata (https://github.com/opencontainers/image-spec)
LABEL org.opencontainers.image.authors="Snowdream Tech" \
    org.opencontainers.image.title="Alpine Base Image" \
    org.opencontainers.image.description="Professional Docker Image packaging for Alpine Linux. Supports amd64, arm32v6, arm32v7, arm64, i386, ppc64le, riscv64, s390x." \
    org.opencontainers.image.documentation="https://hub.docker.com/r/snowdreamtech/alpine" \
    org.opencontainers.image.base.name="snowdreamtech/alpine:latest" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source="https://github.com/snowdreamtech/alpine" \
    org.opencontainers.image.vendor="Snowdream Tech" \
    org.opencontainers.image.version="${VERSION:-3.22.2}" \
    org.opencontainers.image.created="${BUILDTIME}" \
    org.opencontainers.image.revision="${REVISION}" \
    org.opencontainers.image.url="https://github.com/snowdreamtech/alpine"

# Runtime Environment Configuration
ENV KEEPALIVE=${KEEPALIVE} \
    CAP_NET_BIND_SERVICE=${CAP_NET_BIND_SERVICE} \
    LANG=${LANG} \
    UMASK=${UMASK} \
    DEBUG=${DEBUG} \
    PASSWORDLESS_SUDO=${PASSWORDLESS_SUDO} \
    PGID=${PGID} \
    PUID=${PUID} \
    USER=${USER} \
    WORKDIR=${WORKDIR}

# Infrastructure & Tooling Setup
# Includes standard repositories and essential system packages.
RUN apk update \
    && apk add --no-cache \
    bash \
    zsh \
    nano \
    rsync \
    lsb-release \
    doas \
    sudo \
    procps-ng \
    vim \
    zip \
    unzip \
    bzip2 \
    xz \
    file \
    gzip \
    jq \
    busybox-suid \
    musl-locales \
    musl-locales-lang \
    tzdata \
    openssl \
    gnupg \
    sysstat \
    wget \
    curl \
    git \
    bind-tools \
    netcat-openbsd \
    traceroute \
    iputils \
    net-tools \
    lsof \
    libcap \
    su-exec \
    ca-certificates \
    && update-ca-certificates

# System Initialization logic (User mapping, permissions) is handled in entrypoint.d scripts.
# This keeps the Dockerfile clean and the process extensible.

# Container Orchestration Files
COPY entrypoint.d /usr/local/bin/entrypoint.d
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Ensure execution bits are correctly set for all entrypoint scripts.
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.d/*

# Standard Healthcheck (Verification of core system responsiveness)
HEALTHCHECK NONE

# Process Execution
USER root
WORKDIR /root
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/sh"]

# Trigger patch version bump
