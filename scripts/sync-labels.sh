#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

#
# sync-labels.sh
# Purpose: Synchronizes and brands repository labels using GitHub CLI (gh).
# Design: Ensures consistent colors and descriptions for engineering labels.
# Usage: GH_TOKEN=xxx sh scripts/sync-labels.sh

set -eu

# Define SnowdreamTech Brand Colors & Labels
# Format: "name:color:description"
LABELS=$(
  cat <<EOF
dependencies:0366d6:Dependencies and package updates
devops:7d31b2:CI/CD, infrastructure and dev environment
infrastructure:6b5aed:Core infrastructure, Docker, and system configs
linting:ffcc00:Code style, linting, and formatting
javascript:f7df1e:JavaScript/TypeScript ecosystem
github-actions:2088ff:GitHub Actions workflow changes
EOF
)

sync_label() {
  _name=$1
  _color=$2
  _desc=$3

  echo "🔄 Syncing label: [$_name] (#$_color)"
  # Create or Edit the label
  # Use gh's native template output instead of jq for cross-platform compatibility
  # Template format extracts just the name field, one per line
  if gh label list --template '{{range .}}{{.name}}{{"\n"}}{{end}}' | grep -qx "${_name:-}"; then
    gh label edit "${_name:-}" --color "${_color:-}" --description "${_desc:-}"
  else
    gh label create "${_name:-}" --color "${_color:-}" --description "${_desc:-}"
  fi
}

# Main loop
echo "${LABELS:-}" | while IFS=: read -r name color desc; do
  [ -n "${name:-}" ] && sync_label "${name:-}" "${color:-}" "${desc:-}"
done

echo "✅ Label synchronization complete."
