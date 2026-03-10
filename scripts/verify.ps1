# scripts/verify.ps1 - PowerShell wrapper for scripts/verify.sh
#
# Purpose:
#   Orchestrates the project's verification suite (checks, lint, test).
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "verify.sh" $args
