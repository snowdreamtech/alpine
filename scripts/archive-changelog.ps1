# scripts/archive-changelog.ps1 - PowerShell wrapper for scripts/archive-changelog.sh
#
# Purpose:
#   Moves entries of previous major versions from CHANGELOG.md to archival files.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "archive-changelog.sh" $args
