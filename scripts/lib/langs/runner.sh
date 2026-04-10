#!/usr/bin/env sh
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Runner Logic Module

# Purpose: Installs Just (modern runner).
# Delegate: Managed by mise (.mise.toml)
install_just() {
  setup_registry_just
  install_tool_safe "just" "${VER_JUST_PROVIDER:-}" "Just" "--version" 0 "JUST" ""
}

# Purpose: Installs Task (modern runner).
# Delegate: Managed by mise (.mise.toml)
install_task() {
  setup_registry_task
  install_tool_safe "task" "${VER_TASK_PROVIDER:-}" "Task" "--version" 0 "TASK" ""
}

# Purpose: Sets up Runners environment.
setup_runners() {
  install_just
  install_task
}
