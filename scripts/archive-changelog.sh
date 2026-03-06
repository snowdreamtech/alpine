#!/bin/sh
# scripts/archive-changelog.sh - Automate major-version changelog archiving
# This script moves entries of previous major versions from CHANGELOG.md to archival files.
# Features: POSIX compliant, Atomic Operations, Deduplication, Safety Traps, History Sorting.

set -e

CHANGELOG="CHANGELOG.md"
PACKAGE_JSON="package.json"
DRY_RUN=0

# Argument parsing
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    DRY_RUN=1
    echo "Running in DRY-RUN mode. No changes will be applied."
  fi
done

if [ ! -f "$CHANGELOG" ] || [ ! -f "$PACKAGE_JSON" ]; then
  exit 0
fi

# Cleanup on exit
TMP_HEADER=$(mktemp)
TMP_ARCHIVE_PREFIX=$(mktemp -d)
NEW_CHANGELOG=$(mktemp)

cleanup() {
  rm -f "$TMP_HEADER" "$NEW_CHANGELOG"
  rm -rf "$TMP_ARCHIVE_PREFIX"
}
trap cleanup EXIT INT TERM

# Get current major version from package.json
if command -v jq >/dev/null 2>&1; then
  CURRENT_MAJOR=$(jq -r '.version | split(".")[0]' "$PACKAGE_JSON")
else
  # Portable extraction using grep/sed (BRE only)
  CURRENT_MAJOR=$(grep '"version":' "$PACKAGE_JSON" | head -n 1 | sed 's/.*"//;s/\..*//')
fi

# Input Validation
case "$CURRENT_MAJOR" in
'' | *[!0-9]*)
  echo "Error: Could not determine a valid numeric major version from $PACKAGE_JSON (Found: '$CURRENT_MAJOR')" >&2
  exit 1
  ;;
esac

echo "Targeting major version: $CURRENT_MAJOR"

# 1. Extract the header (everything up to the first version header)
FIRST_H2_LINE=$(grep -n "^## \[" "$CHANGELOG" | head -n1 | cut -d: -f1)
if [ -z "$FIRST_H2_LINE" ]; then
  echo "No version headers found in $CHANGELOG. Nothing to archive."
  exit 0
fi

head -n "$((FIRST_H2_LINE - 1))" "$CHANGELOG" >"$TMP_HEADER"

# 2. Process all versions using a portable awk approach
echo "Scanning $CHANGELOG for older major versions..."
tail -n +"$FIRST_H2_LINE" "$CHANGELOG" | awk -v major="$CURRENT_MAJOR" -v prefix="$TMP_ARCHIVE_PREFIX" '
  /^## \[/ {
    line = $0;
    sub(/^## \[/, "", line);
    # Normalize version (remove leading v, extract major)
    sub(/^v/, "", line);
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
    # Deduplication
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
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "DRY-RUN: Would prepend new entries to $FINAL_ARCH_FILE"
      else
        echo "Updating archive: $FINAL_ARCH_FILE"
        tmp_arch=$(mktemp)
        cat "$FILTERED_CONTENT" >"$tmp_arch"
        printf "\n" >>"$tmp_arch"
        sed '1,2d' "$FINAL_ARCH_FILE" >>"$tmp_arch"
        mv "$tmp_arch" "$FINAL_ARCH_FILE"
      fi
    fi
    rm -f "$FILTERED_CONTENT"
  else
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "DRY-RUN: Would create $FINAL_ARCH_FILE"
    else
      echo "Creating new archive: $FINAL_ARCH_FILE"
      printf "# Changelog Archive v%s\n\n" "$v_num" >"$FINAL_ARCH_FILE"
      cat "$arch_file" >>"$FINAL_ARCH_FILE"
    fi
  fi
done

# 5. Rebuild History section in NEW_CHANGELOG (Sorted)
echo "Rebuilding History section..."
HISTORY_LINKS_TMP=$(mktemp)
# Check filesystem for existing archives
for f in CHANGELOG-v*.md; do
  [ -e "$f" ] || continue
  v_num=$(echo "$f" | sed 's/^CHANGELOG-v//;s/\.md$//')
  printf "%s|%s\n" "$v_num" "- [v$v_num.x.x Archive](./$f)" >>"$HISTORY_LINKS_TMP"
done

# Merge with newly planned archives from TMP_ARCHIVE_PREFIX
for f in "$TMP_ARCHIVE_PREFIX"/v*.md; do
  [ -e "$f" ] || continue
  v_num=$(echo "$f" | sed 's|^.*/v||;s/.md$//')
  link="- [v$v_num.x.x Archive](./CHANGELOG-v$v_num.md)"
  # Avoid duplicates in the link list
  if ! grep -qF -- "$link" "$HISTORY_LINKS_TMP"; then
    printf "%s|%s\n" "$v_num" "$link" >>"$HISTORY_LINKS_TMP"
  fi
done

if [ -s "$HISTORY_LINKS_TMP" ]; then
  printf "\n## History\n\n" >>"$NEW_CHANGELOG"
  sort -t'|' -k1,1nr "$HISTORY_LINKS_TMP" | cut -d'|' -f2 >>"$NEW_CHANGELOG"
fi
rm -f "$HISTORY_LINKS_TMP"

# 6. Final Swap (Atomic)
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY-RUN: History section preview:"
  grep -A 100 "^## History" "$NEW_CHANGELOG" || true
else
  mv "$NEW_CHANGELOG" "$CHANGELOG"
  echo "Successfully updated $CHANGELOG"
fi
