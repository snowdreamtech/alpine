#!/bin/sh
# scripts/archive-changelog.sh - Automate major-version changelog archiving
# This script moves entries of previous major versions from CHANGELOG.md to archival files.

set -e

CHANGELOG="CHANGELOG.md"
PACKAGE_JSON="package.json"

if [ ! -f "$CHANGELOG" ] || [ ! -f "$PACKAGE_JSON" ]; then
  exit 0
fi

# Get current major version from package.json
if command -v jq >/dev/null 2>&1; then
  CURRENT_MAJOR=$(jq -r '.version | split(".")[0]' "$PACKAGE_JSON")
else
  # Portable extraction using grep/sed
  CURRENT_MAJOR=$(grep '"version":' "$PACKAGE_JSON" | head -n 1 | sed -E 's/.*"([0-9]+)\..*/\1/')
fi

# Temp files
TMP_HEADER=$(mktemp)
TMP_ARCHIVE_PREFIX=$(mktemp -d)

# 1. Extract the header (everything up to the first version header)
FIRST_H2_LINE=$(grep -n "^## \[" "$CHANGELOG" | head -n1 | cut -d: -f1)
if [ -z "$FIRST_H2_LINE" ]; then
  # No version headers found yet
  rm -rf "$TMP_HEADER" "$TMP_ARCHIVE_PREFIX"
  exit 0
fi

head -n "$((FIRST_H2_LINE - 1))" "$CHANGELOG" >"$TMP_HEADER"

# 2. Process all versions using a more portable awk approach
tail -n +"$FIRST_H2_LINE" "$CHANGELOG" | awk -v major="$CURRENT_MAJOR" -v prefix="$TMP_ARCHIVE_PREFIX" '
  /^## \[/ {
    # Extract major version manually for portability (BSD awk compatibility)
    header = $0;
    sub(/^## \[/, "", header);
    split(header, parts, ".");
    v_major = parts[1];

    if ($0 ~ /Unreleased/) {
      output = "current";
    } else if (v_major == major) {
      output = "current";
    } else if (v_major != "") {
      output = "v" v_major;
    } else {
      output = "current";
    }
  }
  {
    if (output == "") output = "current";
    print >> (prefix "/" output ".md");
  }
'

# 3. Rebuild CHANGELOG.md
cat "$TMP_HEADER" >"$CHANGELOG"
if [ -f "$TMP_ARCHIVE_PREFIX/current.md" ]; then
  cat "$TMP_ARCHIVE_PREFIX/current.md" >>"$CHANGELOG"
fi

# 4. Handle archives
# Use for loop to avoid ls | grep (ls -f lists all files including hidden, but prefix is clean)
for arch_file in "$TMP_ARCHIVE_PREFIX"/v*.md; do
  [ -e "$arch_file" ] || continue

  V_NUM=$(basename "$arch_file" .md | sed 's/^v//')
  FINAL_ARCH_FILE="CHANGELOG-v$V_NUM.md"

  # Prepend newest entries to archive if it already exists
  if [ -f "$FINAL_ARCH_FILE" ]; then
    cat "$arch_file" >"${FINAL_ARCH_FILE}.tmp"
    printf "\n" >>"${FINAL_ARCH_FILE}.tmp"
    # Skip header in existing file if it exists
    sed '1,2d' "$FINAL_ARCH_FILE" >>"${FINAL_ARCH_FILE}.tmp"
    mv "${FINAL_ARCH_FILE}.tmp" "$FINAL_ARCH_FILE"
  else
    printf "# Changelog Archive v%s\n\n" "$V_NUM" >"$FINAL_ARCH_FILE"
    cat "$arch_file" >>"$FINAL_ARCH_FILE"
  fi

  # Add/Update History section link
  if ! grep -q "^## History" "$CHANGELOG"; then
    printf "\n## History\n\n" >>"$CHANGELOG"
  fi

  LINK="- [v$V_NUM.x.x Archive](./$FINAL_ARCH_FILE)"
  if ! grep -Fq -- "$LINK" "$CHANGELOG"; then
    # Portable sed insertion
    sed -i.bak "/^## History/a \\
$LINK
" "$CHANGELOG" && rm "${CHANGELOG}.bak"
  fi
done

# Cleanup
rm -rf "$TMP_HEADER" "$TMP_ARCHIVE_PREFIX"
