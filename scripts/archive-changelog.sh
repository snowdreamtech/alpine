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

main() {
  # 1. Execution Context Guard: Ensure we are in the project root
  guard_project_root
  if [ ! -f "$CHANGELOG" ]; then
    log_error "Error: $CHANGELOG not found in project root."
    exit 1
  fi

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "💧 Starting Changelog Archival Process...\n"

  # Smart Directory Discovery
  # shellcheck disable=SC2153
  local _ARCHIVE_DIR="$ARCHIVE_DIR"
  if [ -z "$_ARCHIVE_DIR" ]; then
    if [ -d "docs/changelogs" ]; then
      _ARCHIVE_DIR="docs/changelogs"
    elif [ -d "changelogs" ]; then
      _ARCHIVE_DIR="changelogs"
    else
      _ARCHIVE_DIR="."
    fi
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
  local _TMP_HEADER
  local _TMP_ARCHIVE_PREFIX
  local _NEW_CHANGELOG
  local _TMP_SUMMARY
  _TMP_HEADER=$(mktemp)
  _TMP_ARCHIVE_PREFIX=$(mktemp -d)
  _NEW_CHANGELOG=$(mktemp)
  # For Job Summary
  _TMP_SUMMARY=$(mktemp)

  cleanup() {
    local _exit_code=$?
    log_debug "Cleaning up temporary files..."
    rm -f "$_TMP_HEADER" "$_NEW_CHANGELOG" "$_TMP_SUMMARY"
    rm -rf "$_TMP_ARCHIVE_PREFIX"
    [ "$DRY_RUN" -eq 0 ] && rmdir "$LOCK_DIR" 2>/dev/null || true
    return "$_exit_code"
  }
  trap cleanup EXIT INT TERM

  # Get current major version (Universal Source)
  local _RAW_V
  _RAW_V=$(get_project_version)
  case "$_RAW_V" in
  '' | '-' | 'null')
    log_warn "Could not determine version from project files. Falling back to Git tags..."
    local _GIT_TAG
    _GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
    _RAW_V="$_GIT_TAG"
    ;;
  esac

  # Extract major version
  local _CURRENT_MAJOR
  _CURRENT_MAJOR=$(echo "$_RAW_V" | sed 's/^v//' | cut -d. -f1)

  # Input Validation
  case "$_CURRENT_MAJOR" in
  '' | *[!0-9]*)
    log_error "Error: Could not determine a valid numeric major version (Found: '$_CURRENT_MAJOR' from '$_RAW_V')"
    exit 1
    ;;
  esac

  log_info "Targeting major version: $_CURRENT_MAJOR"

  # 1. Extract the header (everything up to the first version header)
  local _FIRST_H2_LINE
  _FIRST_H2_LINE=$(grep -n "^## \[" "$CHANGELOG" | head -n1 | cut -d: -f1)
  if [ -z "$_FIRST_H2_LINE" ]; then
    log_warn "No version headers found in $CHANGELOG. Nothing to archive."
    return 0
  fi

  log_debug "Header ends at line $_FIRST_H2_LINE"
  head -n "$((_FIRST_H2_LINE - 1))" "$CHANGELOG" >"$_TMP_HEADER"

  # 2. Process all versions using a portable awk approach
  log_info "Scanning $CHANGELOG for older major versions..."
  tail -n +"$_FIRST_H2_LINE" "$CHANGELOG" | awk -v major="$_CURRENT_MAJOR" -v prefix="$_TMP_ARCHIVE_PREFIX" '
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
  cat "$_TMP_HEADER" >"$_NEW_CHANGELOG"
  if [ -f "$_TMP_ARCHIVE_PREFIX/current.md" ]; then
    log_debug "Preserving current major version content."
    cat "$_TMP_ARCHIVE_PREFIX/current.md" >>"$_NEW_CHANGELOG"
  fi

  # 4. Handle archives with deduplication
  printf "### Archival Execution Summary\n\n" >"$_TMP_SUMMARY"
  printf "| Major Version | Action | Destination |\n" >>"$_TMP_SUMMARY"
  printf "| :--- | :--- | :--- |\n" >>"$_TMP_SUMMARY"
  local _ARCHIVE_COUNT=0

  local _arch_file
  for _arch_file in "$_TMP_ARCHIVE_PREFIX"/v*.md; do
    [ -e "$_arch_file" ] || continue

    _V_TAG=$(basename "$_arch_file" .md)
    local _V_NUM
    _V_NUM=$(echo "$_V_TAG" | sed 's/^v//')
    local _FINAL_ARCH_FILE="$_ARCHIVE_DIR/CHANGELOG-v$_V_NUM.md"
    log_debug "Processing archival block for major version $_V_NUM..."

    if [ -f "$_FINAL_ARCH_FILE" ]; then
      local _FILTERED_CONTENT
      _FILTERED_CONTENT=$(mktemp)
      awk -v arch="$_FINAL_ARCH_FILE" '
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
      ' "$_arch_file" >"$_FILTERED_CONTENT"

      if [ -s "$_FILTERED_CONTENT" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
          log_warn "DRY-RUN: Would prepend new entries to $_FINAL_ARCH_FILE"
          printf "| v%s | Prepend (Dry Run) | %s |\n" "$_V_NUM" "$_FINAL_ARCH_FILE" >>"$_TMP_SUMMARY"
        else
          log_info "Updating archive: $_FINAL_ARCH_FILE"
          local _tmp_arch
          _tmp_arch=$(mktemp)
          cat "$_FILTERED_CONTENT" >"$_tmp_arch"
          printf "\n" >>"$_tmp_arch"
          sed '1,2d' "$_FINAL_ARCH_FILE" >>"$_tmp_arch"
          atomic_swap "$_tmp_arch" "$_FINAL_ARCH_FILE"
          printf "| v%s | Updated | %s |\n" "$_V_NUM" "$_FINAL_ARCH_FILE" >>"$_TMP_SUMMARY"
        fi
        _ARCHIVE_COUNT=$((_ARCHIVE_COUNT + 1))
      else
        log_debug "No new entries for v$_V_NUM, skipping."
      fi
      rm -f "$_FILTERED_CONTENT"
    else
      if [ "$DRY_RUN" -eq 1 ]; then
        log_warn "DRY-RUN: Would create $_FINAL_ARCH_FILE"
        printf "| v%s | Create (Dry Run) | %s |\n" "$_V_NUM" "$_FINAL_ARCH_FILE" >>"$_TMP_SUMMARY"
      else
        log_success "Creating new archive: $_FINAL_ARCH_FILE"
        mkdir -p "$_ARCHIVE_DIR"
        printf "# Changelog Archive v%s\n\n" "$_V_NUM" >"$_FINAL_ARCH_FILE"
        cat "$_arch_file" >>"$_FINAL_ARCH_FILE"
        printf "| v%s | Created | %s |\n" "$_V_NUM" "$_FINAL_ARCH_FILE" >>"$_TMP_SUMMARY"
      fi
      _ARCHIVE_COUNT=$((_ARCHIVE_COUNT + 1))
    fi
  done

  if [ "$_ARCHIVE_COUNT" -eq 0 ]; then
    printf "| N/A | No changes required | %s is up to date |\n" "$CHANGELOG" >>"$_TMP_SUMMARY"
  fi

  # 5. Rebuild History section in NEW_CHANGELOG (Sorted)
  log_info "Rebuilding History section (Archive Directory: $_ARCHIVE_DIR)..."
  local _HISTORY_LINKS_TMP
  _HISTORY_LINKS_TMP=$(mktemp)
  # Check filesystem for existing archives in ARCHIVE_DIR
  local _f
  for _f in "$_ARCHIVE_DIR"/CHANGELOG-v*.md; do
    [ -e "$_f" ] || continue
    local _FILE_NAME
    _FILE_NAME=$(basename "$_f")
    local _V_NUM_PROC
    _V_NUM_PROC=$(echo "$_FILE_NAME" | sed 's/^CHANGELOG-v//;s/\.md$//')
    printf "%s|%s\n" "$_V_NUM_PROC" "- [v$_V_NUM_PROC.x.x Archive](./$_f)" >>"$_HISTORY_LINKS_TMP"
  done

  # Merge with newly planned archives from TMP_ARCHIVE_PREFIX
  for _f in "$_TMP_ARCHIVE_PREFIX"/v*.md; do
    [ -e "$_f" ] || continue
    local _V_NUM_PROC
    _V_NUM_PROC=$(echo "$_f" | sed 's|^.*/v||;s/.md$//')
    local _LINK
    _LINK="- [v$_V_NUM_PROC.x.x Archive](./$_ARCHIVE_DIR/CHANGELOG-v$_V_NUM_PROC.md)"
    # Normalize link paths (remove repeated ./)
    _LINK=$(echo "$_LINK" | sed 's|\./\./|\./|g')
    if ! grep -qF -- "$_LINK" "$_HISTORY_LINKS_TMP" 2>/dev/null; then
      printf "%s|%s\n" "$_V_NUM_PROC" "$_LINK" >>"$_HISTORY_LINKS_TMP"
    fi
  done

  if [ -s "$_HISTORY_LINKS_TMP" ]; then
    printf "\n## History\n" >>"$_NEW_CHANGELOG"
    sort -t'|' -k1,1nr "$_HISTORY_LINKS_TMP" | cut -d'|' -f2 >>"$_NEW_CHANGELOG"
  fi
  rm -f "$_HISTORY_LINKS_TMP"

  # 6. Final Swap (Atomic)
  if [ "$DRY_RUN" -eq 1 ]; then
    log_warn "DRY-RUN: History section preview:"
    grep -A 100 "^## History" "$_NEW_CHANGELOG" || true
  else
    atomic_swap "$_NEW_CHANGELOG" "$CHANGELOG"
    log_success "Successfully updated $CHANGELOG"
  fi

  # 7. Write to GITHUB_STEP_SUMMARY if available
  if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    log_debug "Writing to GITHUB_STEP_SUMMARY..."
    cat "$_TMP_SUMMARY" >>"$GITHUB_STEP_SUMMARY"
  fi
}

main "$@"
