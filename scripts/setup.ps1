# scripts/setup.ps1 - PowerShell wrapper for scripts/setup.sh
#
# Purpose:
#   Automates development environment provisioning and tool installation.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "setup.sh" $args
