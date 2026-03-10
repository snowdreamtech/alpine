# scripts/release.ps1 - PowerShell wrapper for scripts/release.sh
#
# Purpose:
#   Automates semantic versioning, git tagging, and pre-release verification.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "release.sh" $args
