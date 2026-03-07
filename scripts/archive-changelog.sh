#!/bin/sh
# scripts/archive-changelog.sh - Automate major-version changelog archiving
# This script moves entries of previous major versions from CHANGELOG.md to archival files.
# Features: POSIX compliant, Atomic Operations, Deduplication, Safety Traps,
#           History Sorting, Universal Versioning, Subdirectory Support, Concurrency Lock,
#           Smart Directory Discovery, ANSI Colored Output, Verbosity Control,
#           GitHub Actions Job Summary, Execution Context Guard, Multi-Language Versioning.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard: Ensure we are in the project root
guard_project_root
if [ ! -f "$CHANGELOG" ]; then
  log_error "Error: $CHANGELOG not found in project root."
  exit 1
fi

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
  -h, --help       Show this help message.

Environment Variables:
  ARCHIVE_DIR      Directory to store archive files (default: auto-detected or .).
                    Auto-detection order: docs/changelogs/ -> changelogs/ -> ./
                    Example: ARCHIVE_DIR=custom/path $0
EOF
}

# Argument parsing
parse_common_args "$@"

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
# For Job Summary
TMP_SUMMARY=$(mktemp)

cleanup() {
  log_debug "Cleaning up temporary files..."
  rm -f "$TMP_HEADER" "$NEW_CHANGELOG" "$TMP_SUMMARY"
  rm -rf "$TMP_ARCHIVE_PREFIX"
  [ "$DRY_RUN" -eq 0 ] && rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Get current major version (Universal Source)
CURRENT_MAJOR=""

# Helper function to extract major version from a semantic version string
get_major() { echo "$1" | sed 's/^v//;s/\..*//'; }

# 1. Check package.json (Node.js)
if [ -f "$PACKAGE_JSON" ]; then
  log_debug "Checking $PACKAGE_JSON for version..."
  if command -v jq >/dev/null 2>&1; then
    raw_v=$(jq -r '.version' "$PACKAGE_JSON" 2>/dev/null || true)
  else
    # Improved POSIX sed for package.json
    raw_v=$(grep '"version":' "$PACKAGE_JSON" | head -n 1 | sed 's/.*"version":[[:space:]]*"//;s/".*//' || true)
  fi
  if [ -n "$raw_v" ] && [ "$raw_v" != "null" ]; then
    CURRENT_MAJOR=$(get_major "$raw_v")
  fi
fi

# 2. Check Cargo.toml (Rust)
if [ -z "$CURRENT_MAJOR" ] && [ -f "$CARGO_TOML" ]; then
  log_debug "Checking $CARGO_TOML for version..."
  # Improved POSIX sed for Cargo.toml
  raw_v=$(grep '^version =' "$CARGO_TOML" | head -n 1 | sed -e 's/.*"\(.*\)"/\1/' -e "s/.*'\(.*\)'/\1/" || true)
  if [ -n "$raw_v" ]; then
    CURRENT_MAJOR=$(get_major "$raw_v")
  fi
fi

# 3. Check pyproject.toml (Python)
if [ -z "$CURRENT_MAJOR" ] && [ -f "$PYPROJECT_TOML" ]; then
  log_debug "Checking $PYPROJECT_TOML for version..."
  # Improved POSIX sed for pyproject.toml
  raw_v=$(grep '^version =' "$PYPROJECT_TOML" | head -n 1 | sed -e 's/.*"\(.*\)"/\1/' -e "s/.*'\(.*\)'/\1/" || true)
  if [ -n "$raw_v" ]; then
    CURRENT_MAJOR=$(get_major "$raw_v")
  fi
fi

# 4. Check VERSION file (Generic)
if [ -z "$CURRENT_MAJOR" ] && [ -f "$VERSION_FILE" ]; then
  log_debug "Checking $VERSION_FILE for version..."
  raw_v=$(cat "$VERSION_FILE" | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
  if [ -n "$raw_v" ]; then
    CURRENT_MAJOR=$(get_major "$raw_v")
  fi
fi

# 5. Fallback to Git tags if all files fail
if [ -z "$CURRENT_MAJOR" ] || [ "$CURRENT_MAJOR" = "null" ]; then
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log_debug "Falling back to Git tags for version..."
    GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
    if [ -n "$GIT_TAG" ]; then
      CURRENT_MAJOR=$(get_major "$GIT_TAG")
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
printf "### Archival Execution Summary\n\n" >"$TMP_SUMMARY"
printf "| Major Version | Action | Destination |\n" >>"$TMP_SUMMARY"
printf "| :--- | :--- | :--- |\n" >>"$TMP_SUMMARY"
ARCHIVE_COUNT=0

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
        printf "| v%s | Prepend (Dry Run) | %s |\n" "$v_num" "$FINAL_ARCH_FILE" >>"$TMP_SUMMARY"
      else
        log_info "Updating archive: $FINAL_ARCH_FILE"
        tmp_arch=$(mktemp)
        cat "$FILTERED_CONTENT" >"$tmp_arch"
        printf "\n" >>"$tmp_arch"
        sed '1,2d' "$FINAL_ARCH_FILE" >>"$tmp_arch"
        mv "$tmp_arch" "$FINAL_ARCH_FILE"
        printf "| v%s | Updated | %s |\n" "$v_num" "$FINAL_ARCH_FILE" >>"$TMP_SUMMARY"
      fi
      ARCHIVE_COUNT=$((ARCHIVE_COUNT + 1))
    else
      log_debug "No new entries for v$v_num, skipping."
    fi
    rm -f "$FILTERED_CONTENT"
  else
    if [ "$DRY_RUN" -eq 1 ]; then
      log_warn "DRY-RUN: Would create $FINAL_ARCH_FILE"
      printf "| v%s | Create (Dry Run) | %s |\n" "$v_num" "$FINAL_ARCH_FILE" >>"$TMP_SUMMARY"
    else
      log_success "Creating new archive: $FINAL_ARCH_FILE"
      mkdir -p "$ARCHIVE_DIR"
      printf "# Changelog Archive v%s\n\n" "$v_num" >"$FINAL_ARCH_FILE"
      cat "$arch_file" >>"$FINAL_ARCH_FILE"
      printf "| v%s | Created | %s |\n" "$v_num" "$FINAL_ARCH_FILE" >>"$TMP_SUMMARY"
    fi
    ARCHIVE_COUNT=$((ARCHIVE_COUNT + 1))
  fi
done

if [ "$ARCHIVE_COUNT" -eq 0 ]; then
  printf "| N/A | No changes required | %s is up to date |\n" "$CHANGELOG" >>"$TMP_SUMMARY"
fi

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
  log_warn "DRY-RUN: History section preview:"
  grep -A 100 "^## History" "$NEW_CHANGELOG" || true
else
  mv "$NEW_CHANGELOG" "$CHANGELOG"
  log_success "Successfully updated $CHANGELOG"
fi

# 7. Write to GITHUB_STEP_SUMMARY if available
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
  log_debug "Writing to GITHUB_STEP_SUMMARY..."
  cat "$TMP_SUMMARY" >>"$GITHUB_STEP_SUMMARY"
fi
