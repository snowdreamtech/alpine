# Use a base image with common development tools
# hadolint ignore=DL3026
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Use pipefail for safer shell operations
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies, Node tools, Python tools, and binary tools in consolidated layers
# hadolint ignore=DL3008,DL3016,DL3013
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    curl \
    git \
    make \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    golang-go \
    shellcheck \
    hadolint \
    shfmt \
    gitleaks \
    ruff \
    clang-format \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && npm install -g \
    markdownlint-cli2 \
    prettier \
    editorconfig-checker \
    eslint \
    @stoplight/spectral-cli \
    @commitlint/cli \
    @commitlint/config-conventional \
    stylelint \
    stylelint-config-standard \
    @taplo/cli \
    sort-package-json \
    && pip3 install --no-cache-dir \
    pre-commit \
    yamllint \
    sqlfluff \
    actionlint-py \
    && curl -fLsS https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh | sh -s -- -b /usr/local/bin \
    && curl -fLsS https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b /usr/local/bin \
    && curl -fLsS https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash \
    && curl -fLsS https://github.com/stackrox/kube-linter/releases/latest/download/kube-linter-linux.tar.gz | tar -xz -C /usr/local/bin kube-linter \
    && GO_CHECKMAKE_URL=$(curl -sSf https://api.github.com/repos/checkmake/checkmake/releases/latest | grep 'browser_download_url.*linux.*amd64' | head -1 | cut -d'"' -f4) \
    && curl -fLsS "$GO_CHECKMAKE_URL" -o /usr/local/bin/checkmake && chmod +x /usr/local/bin/checkmake

# Set up user environment
USER vscode
WORKDIR /workspace
