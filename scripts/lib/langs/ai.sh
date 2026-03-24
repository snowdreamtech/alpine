#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# AI/Data Science Logic Module

# Purpose: Checks for Jupyter configurations.
install_jupyter() {
  if ! has_lang_files "" "JUPYTER"; then
    return 0
  fi
  log_summary "AI/Data" "Jupyter" "✅ Detected" "-" "0"
}

# Purpose: Checks for DVC (Data Version Control) configurations.
install_dvc() {
  if ! has_lang_files "" "DVC"; then
    return 0
  fi
  log_summary "AI/Data" "DVC" "✅ Detected" "-" "0"
}

# Purpose: Sets up AI/Data Science environment.
setup_ai() {
  install_jupyter
  install_dvc
}
