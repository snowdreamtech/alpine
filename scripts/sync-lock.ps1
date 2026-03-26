# scripts/sync-lock.ps1 - PowerShell wrapper for scripts/sync-lock.sh
#
# Purpose:
#   Synchronizes and verifies the mise.lock file across all platforms.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "sync-lock.sh" $args
