#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# OpenAPI Logic Module

# Purpose: Installs spectral for OpenAPI/AsyncAPI linting.
# Delegate: Managed by mise (.mise.toml)
install_spectral() {
  setup_registry_spectral
  install_tool_safe "spectral" "${VER_SPECTRAL_PROVIDER:-}" "Spectral" "--version" 0 "openapi.yaml openapi.json asyncapi.yaml asyncapi.json" ""
}

# Purpose: Sets up OpenAPI environment.
setup_openapi() {
  install_spectral
}
