# scripts/update.ps1 - PowerShell wrapper for scripts/update.sh
#
# Purpose:
#   Standardizes the maintenance of global and project tools.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "update.sh" $args
