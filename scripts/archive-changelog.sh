#!/bin/sh
# scripts/archive-changelog.sh - Automate major-version changelog archiving
# This script moves entries of previous major versions from CHANGELOG.md to archival files.
# Features: POSIX compliant, Atomic Operations, Deduplication, Safety Traps,
#           History Sorting, Universal Versioning, Subdirectory Support, Concurrency Lock.

set -e

CHANGELOG="CHANGELOG.md"
PACKAGE_JSON="package.json"
DRY_RUN=0
ARCHIVE_DIR="${ARCHIVE_DIR:-.}"
LOCK_DIR="$CHANGELOG.lock"

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Automates the movement of older major version entries from $CHANGELOG
to archival files and maintains a history section.

Options:
  --dry-run    Preview changes without modifying files.
  --help       Show this help message.

Environment Variables:
  ARCHIVE_DIR  Directory to store archive files (default: .).
                Example: ARCHIVE_DIR=docs/changelogs $0
EOF
}

# Argument parsing
for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=1
    echo "Running in DRY-RUN mode. No changes will be applied."
    ;;
  --help)
    show_help
    exit 0
    ;;
  esac
done

if [ ! -f "$CHANGELOG" ]; then
  exit 0
fi

# Concurrency Lock (Atomic mkdir is standard POSIX lock)
if [ "$DRY_RUN" -eq 0 ]; then
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "Error: Another archival process seems to be running (lock exists: $LOCK_DIR)." >&2
    exit 1
  fi
fi

# Cleanup on exit
TMP_HEADER=$(mktemp)
TMP_ARCHIVE_PREFIX=$(mktemp -d)
NEW_CHANGELOG=$(mktemp)

cleanup() {
  rm -f "$TMP_HEADER" "$NEW_CHANGELOG"
  rm -rf "$TMP_ARCHIVE_PREFIX"
  [ "$DRY_RUN" -eq 0 ] && rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Get current major version (Universal Source)
CURRENT_MAJOR=""
if [ -f "$PACKAGE_JSON" ]; then
  if command -v jq >/dev/null 2>&1; then
    CURRENT_MAJOR=$(jq -r '.version | split(".")[0]' "$PACKAGE_JSON" 2>/dev/null || true)
  else
    CURRENT_MAJOR=$(grep '"version":' "$PACKAGE_JSON" | head -n 1 | sed 's/.*"//;s/\..*//' || true)
  fi
fi

# Fallback to Git tags if package.json version is missing or invalid
if [ -z "$CURRENT_MAJOR" ] || [ "$CURRENT_MAJOR" = "null" ]; then
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
    if [ -n "$GIT_TAG" ]; then
      CURRENT_MAJOR=$(echo "$GIT_TAG" | sed 's/^v//;s/\..*//')
    fi
  fi
fi

# Input Validation
case "$CURRENT_MAJOR" in
'' | *[!0-9]*)
  echo "Error: Could not determine a valid numeric major version (Found: '$CURRENT_MAJOR')" >&2
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
  /^## History/ { skip_history = 1; next; }
  /^## \[/ {
    skip_history = 0;
    line = $0;
    sub(/^## \[/, "", line);
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
    if (skip_history) next;
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
  FINAL_ARCH_FILE="$ARCHIVE_DIR/CHANGELOG-v$v_num.md"

  if [ -f "$FINAL_ARCH_FILE" ]; then
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
      mkdir -p "$ARCHIVE_DIR"
      printf "# Changelog Archive v%s\n\n" "$v_num" >"$FINAL_ARCH_FILE"
      cat "$arch_file" >>"$FINAL_ARCH_FILE"
    fi
  fi
done

# 5. Rebuild History section in NEW_CHANGELOG (Sorted)
echo "Rebuilding History section (Archive Directory: $ARCHIVE_DIR)..."
HISTORY_LINKS_TMP=$(mktemp)
# Check filesystem for existing archives in ARCHIVE_DIR
for f in "$ARCHIVE_DIR"/CHANGELOG-v*.md; do
  [ -e "$f" ] || continue
  file_name=$(basename "$f")
  v_num=$(echo "$file_name" | sed 's/^CHANGELOG-v//;s/\.md$//')
  printf "%s|%s\n" "$v_num" "- [v$v_num.x.x Archive](./$f)" >>"$HISTORY_LINKS_TMP"
done

# Merge with newly planned archives from TMP_ARCHIVE_PREFIX
for f in "$TMP_ARCHIVE_PREFIX"/v*.md; do
  [ -e "$f" ] || continue
  v_num=$(echo "$f" | sed 's|^.*/v||;s/.md$//')
  link="- [v$v_num.x.x Archive](./$ARCHIVE_DIR/CHANGELOG-v$v_num.md)"
  # Normalize link paths (remove repeated ./)
  link=$(echo "$link" | sed 's|\./\./|\./|g')
  if ! grep -qF -- "$link" "$HISTORY_LINKS_TMP" 2>/dev/null; then
    printf "%s|%s\n" "$v_num" "$link" >>"$HISTORY_LINKS_TMP"
  fi
done

if [ -s "$HISTORY_LINKS_TMP" ]; then
  printf "\n## History\n" >>"$NEW_CHANGELOG"
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
