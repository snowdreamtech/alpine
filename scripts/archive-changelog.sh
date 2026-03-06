#!/bin/sh
# scripts/archive-changelog.sh - Automate major-version changelog archiving
# This script moves entries of previous major versions from CHANGELOG.md to archival files.
# Strictly POSIX-compliant.

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
  # Portable extraction using grep/sed (BRE only)
  CURRENT_MAJOR=$(grep '"version":' "$PACKAGE_JSON" | head -n 1 | sed 's/.*"//;s/\..*//')
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

# head -n $((FIRST_H2_LINE - 1)) is POSIX-compliant
head -n "$((FIRST_H2_LINE - 1))" "$CHANGELOG" >"$TMP_HEADER"

# 2. Process all versions using a more portable awk approach (Avoid match() and other non-POSIX)
tail -n +"$FIRST_H2_LINE" "$CHANGELOG" | awk -v major="$CURRENT_MAJOR" -v prefix="$TMP_ARCHIVE_PREFIX" '
  /^## \[/ {
    # Extract major version manually using split
    line = $0;
    sub(/^## \[/, "", line);
    split(line, parts, ".");
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
    target = prefix "/" output ".md";
    print >> target;
  }
'

# 3. Rebuild CHANGELOG.md
cat "$TMP_HEADER" >"$CHANGELOG"
if [ -f "$TMP_ARCHIVE_PREFIX/current.md" ]; then
  cat "$TMP_ARCHIVE_PREFIX/current.md" >>"$CHANGELOG"
fi

# 4. Handle archives
# Use for loop with patterns to avoid ls | grep
for arch_file in "$TMP_ARCHIVE_PREFIX"/v*.md; do
  [ -e "$arch_file" ] || continue

  v_tag=$(basename "$arch_file" .md)
  v_num=$(echo "$v_tag" | sed 's/^v//')
  FINAL_ARCH_FILE="CHANGELOG-v$v_num.md"

  # Prepend newest entries to archive if it already exists
  if [ -f "$FINAL_ARCH_FILE" ]; then
    tmp_file=$(mktemp)
    cat "$arch_file" >"$tmp_file"
    printf "\n" >>"$tmp_file"
    # Portable sed: Skip first two lines (header) of existing archive
    sed '1,2d' "$FINAL_ARCH_FILE" >>"$tmp_file"
    mv "$tmp_file" "$FINAL_ARCH_FILE"
  else
    printf "# Changelog Archive v%s\n\n" "$v_num" >"$FINAL_ARCH_FILE"
    cat "$arch_file" >>"$FINAL_ARCH_FILE"
  fi

  # Add/Update History section link
  if ! grep -q "^## History" "$CHANGELOG"; then
    printf "\n## History\n\n" >>"$CHANGELOG"
  fi

  LINK="- [v$v_num.x.x Archive](./$FINAL_ARCH_FILE)"
  if ! grep -Fq -- "$LINK" "$CHANGELOG"; then
    # POSIX-compliant sed insertion using a temp file
    tmp_cl=$(mktemp)
    sed "/^## History/a\\
$LINK
" "$CHANGELOG" >"$tmp_cl"
    mv "$tmp_cl" "$CHANGELOG"
  fi
done

# Cleanup
rm -rf "$TMP_HEADER" "$TMP_ARCHIVE_PREFIX"
