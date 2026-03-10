# scripts/env.ps1 - PowerShell wrapper for scripts/env.sh
#
# Purpose:
#   Standardizes management of .env files and template synchronization.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "env.sh" $args
