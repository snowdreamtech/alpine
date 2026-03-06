#!/bin/sh
# scripts/archive-changelog.sh - Automate major-version changelog archiving
# This script moves entries of previous major versions from CHANGELOG.md to archival files.
# Features: POSIX compliant, Atomic Operations, Deduplication.

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
NEW_CHANGELOG=$(mktemp)

# 1. Extract the header (everything up to the first version header)
FIRST_H2_LINE=$(grep -n "^## \[" "$CHANGELOG" | head -n1 | cut -d: -f1)
if [ -z "$FIRST_H2_LINE" ]; then
  # No version headers found yet
  rm -f "$TMP_HEADER" "$NEW_CHANGELOG"
  rm -rf "$TMP_ARCHIVE_PREFIX"
  exit 0
fi

head -n "$((FIRST_H2_LINE - 1))" "$CHANGELOG" >"$TMP_HEADER"

# 2. Process all versions using a portable awk approach
tail -n +"$FIRST_H2_LINE" "$CHANGELOG" | awk -v major="$CURRENT_MAJOR" -v prefix="$TMP_ARCHIVE_PREFIX" '
  /^## \[/ {
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

# 3. Preparation for rebuild (Atomic)
cat "$TMP_HEADER" >"$NEW_CHANGELOG"
if [ -f "$TMP_ARCHIVE_PREFIX/current.md" ]; then
  cat "$TMP_ARCHIVE_PREFIX/current.md" >>"$NEW_CHANGELOG"
fi

# 4. Handle archives with deduplication
for arch_file in "$TMP_ARCHIVE_PREFIX"/v*.md; do
  [ -e "$arch_file" ] || continue

  v_tag=$(basename "$arch_file" .md)
  v_num=$(echo "$v_tag" | sed 's/^v//')
  FINAL_ARCH_FILE="CHANGELOG-v$v_num.md"

  if [ -f "$FINAL_ARCH_FILE" ]; then
    # Deduplication: only prepend blocks not already in the archive
    # Use awk to filter out existing version headers
    FILTERED_CONTENT=$(mktemp)
    awk -v arch="$FINAL_ARCH_FILE" '
      BEGIN {
        while ((getline line < arch) > 0) {
          if (line ~ /^## \[/) { headers[line] = 1; }
        }
        close(arch);
      }
      /^## \[/ {
        if (headers[$0]) { skip = 1; }
        else { skip = 0; }
      }
      { if (!skip) print; }
    ' "$arch_file" >"$FILTERED_CONTENT"

    if [ -s "$FILTERED_CONTENT" ]; then
      tmp_arch=$(mktemp)
      cat "$FILTERED_CONTENT" >"$tmp_arch"
      printf "\n" >>"$tmp_arch"
      # Skip first two lines (header) of existing archive
      sed '1,2d' "$FINAL_ARCH_FILE" >>"$tmp_arch"
      mv "$tmp_arch" "$FINAL_ARCH_FILE"
    fi
    rm -f "$FILTERED_CONTENT"
  else
    # New archive file
    printf "# Changelog Archive v%s\n\n" "$v_num" >"$FINAL_ARCH_FILE"
    cat "$arch_file" >>"$FINAL_ARCH_FILE"
  fi

  # Add/Update History section link in the NEW_CHANGELOG
  if ! grep -q "^## History" "$NEW_CHANGELOG"; then
    printf "\n## History\n\n" >>"$NEW_CHANGELOG"
  fi

  LINK="- [v$v_num.x.x Archive](./$FINAL_ARCH_FILE)"
  if ! grep -Fq -- "$LINK" "$NEW_CHANGELOG"; then
    tmp_cl=$(mktemp)
    sed "/^## History/a\\
$LINK
" "$NEW_CHANGELOG" >"$tmp_cl"
    mv "$tmp_cl" "$NEW_CHANGELOG"
  fi
done

# 5. Final Swap (Atomic)
mv "$NEW_CHANGELOG" "$CHANGELOG"

# Cleanup
rm -f "$TMP_HEADER"
rm -rf "$TMP_ARCHIVE_PREFIX"
