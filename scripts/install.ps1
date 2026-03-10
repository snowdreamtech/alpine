# scripts/install.ps1 - PowerShell wrapper for scripts/install.sh
#
# Purpose:
#   Orchestrates project dependency installation across package managers.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "install.sh" $args
