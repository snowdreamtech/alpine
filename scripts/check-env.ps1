# scripts/check-env.ps1 - PowerShell wrapper for scripts/check-env.sh
#
# Purpose:
#   Validates the developer workstation against project-required runtimes.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "check-env.sh" $args
