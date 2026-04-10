#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Protobuf Logic Module

# Purpose: Installs buf for Protobuf linting/management.
# Delegate: Managed by mise (.mise.toml)
install_buf() {
  setup_registry_buf
  install_tool_safe "buf" "${VER_BUF_PROVIDER:-}" "Buf" "--version" 0 "PROTOC" ""
}

# Purpose: Sets up Protobuf environment.
setup_protobuf() {
  install_buf
}
