# scripts/update-tools.ps1 - PowerShell wrapper for scripts/update-tools.sh
#
# Purpose:
#   Intelligent tool version upgrader for Mise.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "update-tools.sh" $args
