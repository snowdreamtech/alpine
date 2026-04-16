#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/remove-windows-wrappers.sh - Remove redundant Windows wrapper scripts
#
# Purpose:
#   Remove all .bat and .ps1 wrapper scripts as we now rely on Git Bash/WSL
#   for Windows compatibility. This simplifies maintenance and reduces duplication.
#
# Usage:
#   sh scripts/remove-windows-wrappers.sh [--dry-run]
#
# Options:
#   --dry-run    Show what would be deleted without actually deleting

set -eu

# Parse arguments
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  echo "🔍 DRY RUN MODE - No files will be deleted"
  echo ""
fi

# Find all .bat and .ps1 files in scripts directory (excluding .venv)
echo "📋 Finding Windows wrapper scripts..."
echo ""

BAT_FILES=$(find scripts -type f -name "*.bat" ! -path "*/.*" 2>/dev/null || true)
PS1_FILES=$(find scripts -type f -name "*.ps1" ! -path "*/.*" 2>/dev/null || true)

BAT_COUNT=$(echo "$BAT_FILES" | grep -c . || echo 0)
PS1_COUNT=$(echo "$PS1_FILES" | grep -c . || echo 0)
TOTAL=$((BAT_COUNT + PS1_COUNT))

echo "Found:"
echo "  - $BAT_COUNT .bat files"
echo "  - $PS1_COUNT .ps1 files"
echo "  - $TOTAL total files"
echo ""

if [ "$TOTAL" -eq 0 ]; then
  echo "✅ No Windows wrapper scripts found. Nothing to do."
  exit 0
fi

# Show files to be deleted
echo "Files to be deleted:"
echo ""
if [ -n "$BAT_FILES" ]; then
  echo "$BAT_FILES" | while IFS= read -r file; do
    [ -n "$file" ] && echo "  - $file"
  done
fi
if [ -n "$PS1_FILES" ]; then
  echo "$PS1_FILES" | while IFS= read -r file; do
    [ -n "$file" ] && echo "  - $file"
  done
fi
echo ""

# Delete files
if [ "$DRY_RUN" -eq 1 ]; then
  echo "🔍 DRY RUN: Would delete $TOTAL files"
  exit 0
fi

echo "🗑️  Deleting files..."

# Delete .bat files
if [ -n "$BAT_FILES" ]; then
  echo "$BAT_FILES" | while IFS= read -r file; do
    if [ -n "$file" ] && [ -f "$file" ]; then
      rm "$file"
      echo "  ✓ Deleted: $file"
    fi
  done
fi

# Delete .ps1 files
if [ -n "$PS1_FILES" ]; then
  echo "$PS1_FILES" | while IFS= read -r file; do
    if [ -n "$file" ] && [ -f "$file" ]; then
      rm "$file"
      echo "  ✓ Deleted: $file"
    fi
  done
fi

echo ""
echo "✅ Successfully deleted $TOTAL Windows wrapper scripts"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git status"
echo "  2. Update documentation to reflect Git Bash requirement"
echo "  3. Commit the changes: git add -A && git commit -m 'refactor: remove Windows wrapper scripts'"
