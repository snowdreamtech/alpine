#!/bin/sh
# scripts/archive-changelog.sh - Automate major-version changelog archiving
# This script moves entries of previous major versions from CHANGELOG.md to archival files.
# Features: POSIX compliant, Atomic Operations, Deduplication, Safety Traps,
#           History Sorting, Universal Versioning, Subdirectory Support, Concurrency Lock,
#           Smart Directory Discovery, ANSI Colored Output, Verbosity Control.

set -e

CHANGELOG="CHANGELOG.md"
PACKAGE_JSON="package.json"
DRY_RUN=0
VERBOSE=1 # 0: quiet, 1: normal, 2: verbose
LOCK_DIR="$CHANGELOG.lock"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { [ "$VERBOSE" -ge 1 ] && printf "%b%s%b\n" "$BLUE" "$1" "$NC"; }
log_success() { [ "$VERBOSE" -ge 1 ] && printf "%b%s%b\n" "$GREEN" "$1" "$NC"; }
log_warn() { [ "$VERBOSE" -ge 1 ] && printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; }
log_error() { printf "%b%s%b\n" "$RED" "$1" "$NC" >&2; }
log_debug() { [ "$VERBOSE" -ge 2 ] && printf "[DEBUG] %s\n" "$1"; }

# Smart Directory Discovery
if [ -z "$ARCHIVE_DIR" ]; then
  if [ -d "docs/changelogs" ]; then
    ARCHIVE_DIR="docs/changelogs"
  elif [ -d "changelogs" ]; then
    ARCHIVE_DIR="changelogs"
  else
    ARCHIVE_DIR="."
  fi
fi

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Automates the movement of older major version entries from $CHANGELOG
to archival files and maintains a history section.

Options:
  --dry-run        Preview changes without modifying files.
  -q, --quiet      Suppress all output except errors.
  -v, --verbose    Show detailed debug information.
  --help           Show this help message.

Environment Variables:
  ARCHIVE_DIR      Directory to store archive files (default: auto-detected or .).
                    Auto-detection order: docs/changelogs/ -> changelogs/ -> ./
                    Example: ARCHIVE_DIR=custom/path $0
EOF
}

# Argument parsing
for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=1
    log_warn "Running in DRY-RUN mode. No changes will be applied."
    ;;
  -q | --quiet)
    VERBOSE=0
    ;;
  -v | --verbose)
    VERBOSE=2
    ;;
  --help)
    show_help
    exit 0
    ;;
  esac
done

if [ ! -f "$CHANGELOG" ]; then
  log_debug "$CHANGELOG not found, skipping."
  exit 0
fi

# Concurrency Lock (Atomic mkdir is standard POSIX lock)
if [ "$DRY_RUN" -eq 0 ]; then
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    log_error "Error: Another archival process seems to be running (lock exists: $LOCK_DIR)."
    exit 1
  fi
  log_debug "Lock acquired: $LOCK_DIR"
fi

# Cleanup on exit
TMP_HEADER=$(mktemp)
TMP_ARCHIVE_PREFIX=$(mktemp -d)
NEW_CHANGELOG=$(mktemp)

cleanup() {
  log_debug "Cleaning up temporary files..."
  rm -f "$TMP_HEADER" "$NEW_CHANGELOG"
  rm -rf "$TMP_ARCHIVE_PREFIX"
  [ "$DRY_RUN" -eq 0 ] && rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Get current major version (Universal Source)
CURRENT_MAJOR=""
if [ -f "$PACKAGE_JSON" ]; then
  log_debug "Checking $PACKAGE_JSON for version..."
  if command -v jq >/dev/null 2>&1; then
    CURRENT_MAJOR=$(jq -r '.version | split(".")[0]' "$PACKAGE_JSON" 2>/dev/null || true)
  else
    CURRENT_MAJOR=$(grep '"version":' "$PACKAGE_JSON" | head -n 1 | sed 's/.*"//;s/\..*//' || true)
  fi
fi

# Fallback to Git tags if package.json version is missing or invalid
if [ -z "$CURRENT_MAJOR" ] || [ "$CURRENT_MAJOR" = "null" ]; then
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log_debug "Falling back to Git tags for version..."
    GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
    if [ -n "$GIT_TAG" ]; then
      CURRENT_MAJOR=$(echo "$GIT_TAG" | sed 's/^v//;s/\..*//')
    fi
  fi
fi

# Input Validation
case "$CURRENT_MAJOR" in
'' | *[!0-9]*)
  log_error "Error: Could not determine a valid numeric major version (Found: '$CURRENT_MAJOR')"
  exit 1
  ;;
esac

log_info "Targeting major version: $CURRENT_MAJOR"

# 1. Extract the header (everything up to the first version header)
FIRST_H2_LINE=$(grep -n "^## \[" "$CHANGELOG" | head -n1 | cut -d: -f1)
if [ -z "$FIRST_H2_LINE" ]; then
  log_warn "No version headers found in $CHANGELOG. Nothing to archive."
  exit 0
fi

log_debug "Header ends at line $FIRST_H2_LINE"
head -n "$((FIRST_H2_LINE - 1))" "$CHANGELOG" >"$TMP_HEADER"

# 2. Process all versions using a portable awk approach
log_info "Scanning $CHANGELOG for older major versions..."
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
  log_debug "Preserving current major version content."
  cat "$TMP_ARCHIVE_PREFIX/current.md" >>"$NEW_CHANGELOG"
fi

# 4. Handle archives with deduplication
for arch_file in "$TMP_ARCHIVE_PREFIX"/v*.md; do
  [ -e "$arch_file" ] || continue

  v_tag=$(basename "$arch_file" .md)
  v_num=$(echo "$v_tag" | sed 's/^v//')
  FINAL_ARCH_FILE="$ARCHIVE_DIR/CHANGELOG-v$v_num.md"
  log_debug "Processing archival block for major version $v_num..."

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
        log_warn "DRY-RUN: Would prepend new entries to $FINAL_ARCH_FILE"
      else
        log_info "Updating archive: $FINAL_ARCH_FILE"
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
      log_warn "DRY-RUN: Would create $FINAL_ARCH_FILE"
    else
      log_success "Creating new archive: $FINAL_ARCH_FILE"
      mkdir -p "$ARCHIVE_DIR"
      printf "# Changelog Archive v%s\n\n" "$v_num" >"$FINAL_ARCH_FILE"
      cat "$arch_file" >>"$FINAL_ARCH_FILE"
    fi
  fi
done

# 5. Rebuild History section in NEW_CHANGELOG (Sorted)
log_info "Rebuilding History section (Archive Directory: $ARCHIVE_DIR)..."
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
  if [ "$VERBOSE" -ge 1 ]; then
    log_warn "DRY-RUN: History section preview:"
    grep -A 100 "^## History" "$NEW_CHANGELOG" || true
  fi
else
  mv "$NEW_CHANGELOG" "$CHANGELOG"
  log_success "Successfully updated $CHANGELOG"
fi
