# scripts/format.ps1 - PowerShell wrapper for scripts/format.sh
#
# Purpose:
#   Optimizes code style across all project components using uniform rules.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "format.sh" $args
