# --- Base Image Configuration ---
# [Recommended] Microsoft's official devcontainer base image, optimized for VS Code.
# If you need to use a custom or internal enterprise image, replace the FROM line below.
# hadolint ignore=DL3026
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04@sha256:81380e4c9c14e8a629ff39029639e4b7893e67400246fa7782a0fe7dc193a02a

# Use pipefail for safer shell operations
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies, Node tools, Python tools, and binary tools in consolidated layers
# hadolint ignore=DL3008,DL3016,DL3013,DL4006
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    curl git make python3 python3-pip python3-venv nodejs npm golang-go \
    openjdk-17-jre-headless unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && corepack enable \
    && FORCE_SETUP=1 make setup all

# Set up user environment
USER vscode
WORKDIR /workspace
