# scripts/audit.ps1 - PowerShell wrapper for scripts/audit.sh
#
# Purpose:
#   Standardizes execution of dependency scans and secret detection modules.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "audit.sh" $args
